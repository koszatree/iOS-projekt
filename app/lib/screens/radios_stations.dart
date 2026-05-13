import 'package:flutter/material.dart';

import 'package:app/models/city.dart';
import 'package:app/models/radio_station.dart';
import 'package:app/providers/service_radio.dart';

class RadioStationsScreen extends StatefulWidget {
  const RadioStationsScreen({super.key});

  @override
  State<RadioStationsScreen> createState() => _RadioStationsScreenState();
}

class _RadioStationsScreenState extends State<RadioStationsScreen> {
  // Wyszukiwarka miast
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<City> _cities = [];
  List<City> _suggestions = [];
  City? _selectedCity;

  // Stacje
  List<RadioStation> _stations = [];
  bool _loadingCities = false;
  bool _loadingStations = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus) {
        setState(() => _suggestions = []);
      }
    });
    _fetchCities();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // ── Pobieranie listy miast ────────────────────────────────────────────────

  Future<void> _fetchCities() async {
    setState(() => _loadingCities = true);
    try {
      final cities = await ServiceRadio.getCities();
      setState(() {
        _cities = cities;
        _loadingCities = false;
      });
    } catch (e) {
      setState(() {
        _loadingCities = false;
        _errorMessage = 'Błąd pobierania miast: $e';
      });
    }
  }

  // ── Filtrowanie podpowiedzi ───────────────────────────────────────────────

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }

    setState(() {
      _suggestions = _cities
          .where((c) => c.name.toLowerCase().contains(query))
          .toList();
    });
  }

  // ── Wybór miasta i pobranie stacji ────────────────────────────────────────

  // ── Wyszukiwanie po tekście (Enter lub przycisk) ─────────────────────────

  void _onSearchSubmit() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return;

    City? match;
    try {
      match = _cities.firstWhere((c) => c.name.toLowerCase() == query);
    } catch (_) {}
    match ??= _suggestions.isNotEmpty ? _suggestions.first : null;

    if (match == null) {
      setState(
        () =>
            _errorMessage = 'Nie znaleziono miasta „${_searchController.text}"',
      );
      return;
    }
    _selectCity(match);
  }

  Future<void> _selectCity(City city) async {
    _searchController.value = TextEditingValue(
      text: city.name,
      selection: TextSelection.collapsed(offset: city.name.length),
    );

    setState(() {
      _selectedCity = city;
      _suggestions = [];
      _loadingStations = true;
      _stations = [];
      _errorMessage = null;
    });

    try {
      final stations = await ServiceRadio.getStationsForCity(city);
      if (!mounted) return;
      setState(() {
        _stations = stations;
        _loadingStations = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingStations = false;
        _errorMessage = 'Błąd pobierania stacji: $e';
      });
    }
  }

  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Lista stacji radiowych'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Pasek wyszukiwania + podpowiedzi ────────────────────────────
          _SearchSection(
            controller: _searchController,
            focusNode: _searchFocusNode,
            suggestions: _suggestions,
            isLoading: _loadingCities,
            onCitySelected: _selectCity,
            onSubmit: _onSearchSubmit,
          ),

          // ── Zawartość ────────────────────────────────────────────────────
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    // Ładowanie stacji
    if (_loadingStations) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFF4CAF50)),
            const SizedBox(height: 16),
            Text(
              'Pobieranie stacji dla „${_selectedCity?.name}"…',
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
          ],
        ),
      );
    }

    // Błąd
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 56,
                color: Color(0xFFD32F2F),
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 14, color: Color(0xFFD32F2F)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (_selectedCity != null)
                ElevatedButton.icon(
                  onPressed: () => _selectCity(_selectedCity!),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Spróbuj ponownie'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // Placeholder – brak wybranego miasta
    if (_selectedCity == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.radio, size: 72, color: Color(0xFFBDBDBD)),
              SizedBox(height: 16),
              Text(
                'Wyszukaj miasto, aby zobaczyć dostępne stacje radiowe',
                style: TextStyle(fontSize: 15, color: Colors.black45),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Brak stacji w wybranym mieście
    if (_stations.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.radio_outlined,
              size: 64,
              color: Color(0xFFBDBDBD),
            ),
            const SizedBox(height: 12),
            Text(
              'Brak stacji radiowych w mieście\n„${_selectedCity!.name}"',
              style: const TextStyle(fontSize: 15, color: Colors.black45),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Lista stacji
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            '${_stations.length} stacji w „${_selectedCity!.name}"',
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _stations.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _StationCard(station: _stations[i]),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: sekcja wyszukiwania z podpowiedziami
// ─────────────────────────────────────────────────────────────────────────────

class _SearchSection extends StatelessWidget {
  const _SearchSection({
    required this.controller,
    required this.focusNode,
    required this.suggestions,
    required this.isLoading,
    required this.onCitySelected,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final List<City> suggestions;
  final bool isLoading;
  final void Function(City) onCitySelected;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF4CAF50),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      textAlignVertical: TextAlignVertical.center,
                      style: const TextStyle(fontSize: 15),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => onSubmit(),
                      decoration: const InputDecoration(
                        hintText: 'Wyszukaj miasto…',
                        hintStyle: TextStyle(
                          color: Colors.black45,
                          fontSize: 15,
                        ),
                        prefixIcon: Icon(
                          Icons.location_city,
                          color: Color(0xFF4CAF50),
                          size: 20,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 0),
                      ),
                    ),
                  ),
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                    ),
                  Material(
                    color: const Color(0xFF388E3C),
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(8),
                    ),
                    child: InkWell(
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(8),
                      ),
                      onTap: onSubmit,
                      child: const SizedBox(
                        width: 46,
                        height: 46,
                        child: Icon(
                          Icons.search,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (suggestions.isNotEmpty)
            Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: suggestions.map((city) {
                    return InkWell(
                      onTap: () => onCitySelected(city),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Color(0xFFEEEEEE)),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_city,
                              size: 18,
                              color: Color(0xFF4CAF50),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              city.name,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF212121),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: karta stacji radiowej
// ─────────────────────────────────────────────────────────────────────────────

class _StationCard extends StatelessWidget {
  const _StationCard({required this.station});

  final RadioStation station;

  @override
  Widget build(BuildContext context) {
    final statusColor = station.lastCheckOk
        ? const Color(0xFF4CAF50)
        : const Color(0xFFD32F2F);

    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Ikona / favicon ─────────────────────────────────────────
            _StationAvatar(
              faviconUrl: station.favicon,
              isOk: station.lastCheckOk,
            ),
            const SizedBox(width: 12),

            // ── Dane stacji ─────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nazwa
                  Text(
                    station.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF212121),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Kraj
                  if (station.country.isNotEmpty)
                    Text(
                      station.country,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black45,
                      ),
                    ),

                  const SizedBox(height: 6),

                  // Tagi: kodek, bitrate, HLS
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (station.codec.isNotEmpty) _Chip(label: station.codec),
                      if (station.bitrate > 0)
                        _Chip(label: '${station.bitrate} kbps'),
                      if (station.hls)
                        _Chip(label: 'HLS', color: const Color(0xFF1976D2)),
                    ],
                  ),
                ],
              ),
            ),

            // ── Status ──────────────────────────────────────────────────
            Icon(
              station.lastCheckOk ? Icons.check_circle : Icons.cancel_outlined,
              color: statusColor,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: awatar stacji (favicon lub ikona zastępcza)
// ─────────────────────────────────────────────────────────────────────────────

class _StationAvatar extends StatelessWidget {
  const _StationAvatar({required this.faviconUrl, required this.isOk});

  final String faviconUrl;
  final bool isOk;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.hardEdge,
      child: faviconUrl.isNotEmpty
          ? Image.network(
              faviconUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const _RadioIcon(),
            )
          : const _RadioIcon(),
    );
  }
}

class _RadioIcon extends StatelessWidget {
  const _RadioIcon();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.radio, size: 24, color: Color(0xFF4CAF50)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: chip etykiety (kodek, bitrate)
// ─────────────────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.color = const Color(0xFF4CAF50)});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
