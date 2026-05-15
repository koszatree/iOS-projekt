import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

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

  // Odtwarzacz
  final AudioPlayer _player = AudioPlayer();
  String? _playingUuid; // UUID aktualnie odtwarzanej stacji
  String? _loadingUuid; // UUID stacji ładującej strumień
  String? _playerError; // Komunikat błędu odtwarzacza

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _fetchCities();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _player.dispose();
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

  void _hideSuggestions() => setState(() => _suggestions = []);

  // ── Wyszukiwanie po tekście (Enter lub przycisk) ──────────────────────────

  void _onSearchSubmit() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      _hideSuggestions();
      return;
    }

    City? match;
    try {
      match = _cities.firstWhere((c) => c.name.toLowerCase() == query);
    } catch (_) {}
    match ??= _suggestions.isNotEmpty ? _suggestions.first : null;

    _hideSuggestions();

    if (match == null) {
      setState(
        () =>
            _errorMessage = 'Nie znaleziono miasta „${_searchController.text}"',
      );
      return;
    }
    _selectCity(match);
  }

  // ── Wybór miasta i pobranie stacji ────────────────────────────────────────

  Future<void> _selectCity(City city) async {
    _searchController.value = TextEditingValue(
      text: city.name,
      selection: TextSelection.collapsed(offset: city.name.length),
    );
    _hideSuggestions();
    _searchFocusNode.unfocus();

    // Zatrzymaj odtwarzanie przy zmianie miasta
    await _stopPlayback();

    setState(() {
      _selectedCity = city;
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

  // ── Odtwarzanie ───────────────────────────────────────────────────────────

  Future<void> _togglePlayback(RadioStation station) async {
    if (_playingUuid == station.stationUuid) {
      await _stopPlayback();
      return;
    }
    await _stopPlayback();
    setState(() {
      _loadingUuid = station.stationUuid;
      _playerError = null;
    });

    try {
      final streamInfo = await ServiceRadio.getStationStreamUrl(
        station.stationUuid,
      );
      await _player.setUrl(streamInfo.streamUrl);
      await _player.play();
      if (!mounted) return;
      setState(() {
        _playingUuid = station.stationUuid;
        _loadingUuid = null;
      });
    } catch (e) {
      debugPrint('RADIO ERROR: $e'); // ← dodaj to
      if (!mounted) return;
      setState(() {
        _loadingUuid = null;
        _playerError = 'Błąd odtwarzania: $e';
      });
    }
  }

  Future<void> _stopPlayback() async {
    await _player.stop();
    if (mounted) {
      setState(() {
        _playingUuid = null;
        _loadingUuid = null;
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
          // ── Pasek wyszukiwania + podpowiedzi ──────────────────────────
          _SearchSection(
            controller: _searchController,
            focusNode: _searchFocusNode,
            suggestions: _suggestions,
            isLoading: _loadingCities,
            onCitySelected: _selectCity,
            onSubmit: _onSearchSubmit,
          ),

          // ── Baner aktualnie odtwarzanej stacji ─────────────────────────
          if (_playingUuid != null) _buildNowPlayingBanner(),

          // ── Komunikat błędu odtwarzacza ────────────────────────────────
          if (_playerError != null)
            _ErrorBanner(
              message: _playerError!,
              onDismiss: () => setState(() => _playerError = null),
            ),

          // ── Zawartość ──────────────────────────────────────────────────
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildNowPlayingBanner() {
    final station = _stations
        .where((s) => s.stationUuid == _playingUuid)
        .firstOrNull;
    final name = station?.name ?? '';

    return Container(
      color: const Color(0xFF388E3C),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.graphic_eq, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Odtwarzanie: $name',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: _stopPlayback,
            child: const Icon(
              Icons.stop_circle_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
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

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _stations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final station = _stations[i];
        final isPlaying = _playingUuid == station.stationUuid;
        final isLoading = _loadingUuid == station.stationUuid;

        return _StationCard(
          station: station,
          isPlaying: isPlaying,
          isLoading: isLoading,
          onPlayTap: () => _togglePlayback(station),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: sekcja wyszukiwania
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
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
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
                      decoration: InputDecoration(
                        hintText: isLoading
                            ? 'Ładowanie miast…'
                            : 'Wyszukaj miasto…',
                        hintStyle: const TextStyle(
                          color: Colors.black45,
                          fontSize: 15,
                        ),
                        prefixIcon: const Icon(
                          Icons.location_city,
                          color: Color(0xFF4CAF50),
                          size: 20,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
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
                  // Przycisk wyszukiwania
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

          // Podpowiedzi
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
                              Icons.location_on,
                              size: 16,
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
  const _StationCard({
    required this.station,
    required this.isPlaying,
    required this.isLoading,
    required this.onPlayTap,
  });

  final RadioStation station;
  final bool isPlaying;
  final bool isLoading;
  final VoidCallback onPlayTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = station.lastCheckOk
        ? const Color(0xFF4CAF50)
        : const Color(0xFFD32F2F);

    return Card(
      elevation: isPlaying ? 4 : 2,
      shadowColor: isPlaying
          ? const Color(0xFF4CAF50).withOpacity(0.4)
          : Colors.black12,
      color: isPlaying ? const Color(0xFFE8F5E9) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: isPlaying
            ? const BorderSide(color: Color(0xFF4CAF50), width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Awatar ──────────────────────────────────────────────────
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
                  Text(
                    station.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isPlaying
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFF212121),
                    ),
                  ),
                  if (station.country.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      station.country,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
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

            const SizedBox(width: 8),

            // ── Status dostępności + przycisk play/stop ─────────────────
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  station.lastCheckOk
                      ? Icons.check_circle
                      : Icons.cancel_outlined,
                  color: statusColor,
                  size: 16,
                ),
                const SizedBox(height: 6),
                _PlayButton(
                  isPlaying: isPlaying,
                  isLoading: isLoading,
                  enabled: station.lastCheckOk,
                  onTap: onPlayTap,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: przycisk play/stop/ładowanie
// ─────────────────────────────────────────────────────────────────────────────

class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.isPlaying,
    required this.isLoading,
    required this.enabled,
    required this.onTap,
  });

  final bool isPlaying;
  final bool isLoading;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        width: 36,
        height: 36,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Color(0xFF4CAF50),
            ),
          ),
        ),
      );
    }

    final color = !enabled
        ? Colors.grey
        : isPlaying
        ? const Color(0xFFD32F2F)
        : const Color(0xFF4CAF50);

    return Material(
      color: color.withOpacity(0.1),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
            color: color,
            size: 24,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: awatar stacji
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
  Widget build(BuildContext context) => const Center(
    child: Icon(Icons.radio, size: 24, color: Color(0xFF4CAF50)),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: chip etykiety
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

// ─────────────────────────────────────────────────────────────────────────────
// Widget: baner błędu odtwarzacza
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFD32F2F),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: const Icon(Icons.close, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }
}
