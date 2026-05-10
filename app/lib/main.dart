import 'dart:typed_data';
import 'package:flutter/material.dart';

import 'models/city.dart';
import 'providers/service_soap.dart';

import 'screens/server_status.dart';
import 'screens/radios_stations.dart';
import 'screens/authors.dart';
import 'screens/weather.dart';

void main() {
  runApp(const MyApp());
}

// ─────────────────────────────────────────────────────────────────────────────
// Aplikacja
// ─────────────────────────────────────────────────────────────────────────────

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mapa App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4CAF50)),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const MapScreen(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Główny ekran
// ─────────────────────────────────────────────────────────────────────────────

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {
  // Animacja menu
  bool _menuOpen = false;
  late AnimationController _animationController;
  late Animation<double> _menuAnimation;

  // Wyszukiwarka
  final TextEditingController _searchController = TextEditingController();
  List<City> _cities = [];
  List<City> _suggestions = [];

  // Mapa
  City? _selectedCity;
  Uint8List? _mapImageBytes;
  bool _loadingCities = false;
  bool _loadingMap = false;
  String? _errorMessage;

  static const double _rightColumnWidth = 60.0;

  final TransformationController _mapController = TransformationController();
  double _currentScale = 1.0;
  static const double _minScale = 1.0;
  static const double _maxScale = 4.0;
  static const double _zoomStep = 1.25;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _menuAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );
    _searchController.addListener(_onSearchChanged);
    _fetchCities();
    _selectCityByName('Gdańsk-local');
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // ── Sterowanie menu ───────────────────────────────────────────────────────

  void _toggleMenu() {
    setState(() => _menuOpen = !_menuOpen);
    _menuOpen ? _animationController.forward() : _animationController.reverse();
  }

  // ── Pobieranie listy miast ────────────────────────────────────────────────

  Future<void> _fetchCities() async {
    setState(() => _loadingCities = true);
    try {
      final cities = await MapSoapService.getCities();
      setState(() {
        _cities = cities;
        _loadingCities = false;
      });
    } catch (e) {
      setState(() {
        _loadingCities = false;
        _errorMessage = 'Błąd pobierania listy miast: $e';
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

  // ── Sterowanie zoomem mapy ────────────────────────────────────────────────

  void _resetMapTransform() {
    _currentScale = 1.0;
    _mapController.value = Matrix4.identity();
  }

  void _zoomIn() {
    _setZoom(_currentScale * _zoomStep);
  }

  void _zoomOut() {
    _setZoom(_currentScale / _zoomStep);
  }

  void _setZoom(double targetScale) {
    final scale = targetScale.clamp(_minScale, _maxScale);
    setState(() => _currentScale = scale);

    final matrix = Matrix4.identity()..scale(scale);
    _mapController.value = matrix;
  }

  // ── Wybór miasta i pobranie mapy ──────────────────────────────────────────

  Future<void> _selectCity(City city) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _selectedCity = city;
      _suggestions = [];
      _searchController.text = city.name;
      _loadingMap = true;
      _mapImageBytes = null;
      _errorMessage = null;
    });
    _resetMapTransform();

    try {
      final bytes = await MapSoapService.getMapTile(city);
      setState(() {
        _mapImageBytes = bytes;
        _loadingMap = false;
      });
    } catch (e) {
      setState(() {
        _loadingMap = false;
        _errorMessage = 'Błąd pobierania mapy: $e';
      });
    }
  }

  // Wybór miasta po nazwie (np. z podpowiedzi) ─────────────────────────────────

  Future<void> _selectCityByName(String name) async {
    try {
      final city = await MapSoapService.getCityByName(name);
      _selectCity(city);
    } catch (e) {
      setState(() => _errorMessage = 'Błąd: $e');
    }
  }

  // ── Wyszukiwanie po naciśnięciu lupy lub Enter ────────────────────────────

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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Tło: mapa lub placeholder ───────────────────────────────────
          Positioned.fill(
            child: _MapBackground(
              imageBytes: _mapImageBytes,
              isLoading: _loadingMap,
              controller: _mapController,
              minScale: _minScale,
              maxScale: _maxScale,
              child: _mapImageBytes != null
                  ? Image.memory(
                      _mapImageBytes!,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    )
                  : const ColoredBox(color: Colors.white),
            ),
          ),

          // ── Panel menu ──────────────────────────────────────────────────
          Positioned(
            top: topPadding,
            left: 0,
            right: _rightColumnWidth,
            child: AnimatedBuilder(
              animation: _menuAnimation,
              builder: (context, child) => ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: _menuAnimation.value,
                  child: child,
                ),
              ),
              child: _DropMenu(onClose: _toggleMenu),
            ),
          ),

          // ── Podpowiedzi wyszukiwania ─────────────────────────────────────
          if (_suggestions.isNotEmpty)
            Positioned(
              top: topPadding + 64,
              left: 62,
              right: _rightColumnWidth + 4,
              child: _SuggestionList(
                suggestions: _suggestions,
                onSelected: _selectCity,
              ),
            ),

          // ── Lupa – zawsze widoczna, prawy górny róg ───────────────────────
          Positioned(
            top: topPadding + 12,
            right: 8,
            child: _IconCircleButton(
              icon: Icons.search,
              onPressed: _onSearchSubmit,
              tooltip: 'Wyszukaj',
            ),
          ),

          // ── Zoom – zawsze widoczny, prawa strona ──────────────────────────
          Positioned(
            top: topPadding + 80,
            right: 8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ZoomButton(icon: Icons.add, onPressed: _zoomIn),
                const SizedBox(height: 8),
                _ZoomButton(icon: Icons.remove, onPressed: _zoomOut),
              ],
            ),
          ),

          // ── Hamburger – zawsze widoczny, lewy górny róg ───────────────────
          Positioned(
            top: topPadding + 10,
            left: 8,
            child: _HamburgerButton(isOpen: _menuOpen, onPressed: _toggleMenu),
          ),

          // ── Pasek wyszukiwania – znika gdy menu otwarte ───────────────────
          Positioned(
            top: topPadding + 10,
            left: 62,
            right: _rightColumnWidth + 4,
            child: AnimatedBuilder(
              animation: _menuAnimation,
              builder: (context, child) => Opacity(
                opacity: 1.0 - _menuAnimation.value,
                child: IgnorePointer(ignoring: _menuOpen, child: child),
              ),
              child: _SearchBar(
                controller: _searchController,
                onSubmitted: (_) => _onSearchSubmit(),
                isLoading: _loadingCities,
              ),
            ),
          ),

          // ── Komunikat błędu ───────────────────────────────────────────────
          if (_errorMessage != null)
            Positioned(
              bottom: 40,
              left: 16,
              right: 16,
              child: _ErrorBanner(
                message: _errorMessage!,
                onDismiss: () => setState(() => _errorMessage = null),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: tło mapy
// ─────────────────────────────────────────────────────────────────────────────

class _MapBackground extends StatelessWidget {
  const _MapBackground({
    required this.imageBytes,
    required this.isLoading,
    required this.controller,
    required this.minScale,
    required this.maxScale,
    required this.child,
  });

  final Uint8List? imageBytes;
  final bool isLoading;
  final TransformationController controller;
  final double minScale;
  final double maxScale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const ColoredBox(
        color: Color(0xFFF5F5F5),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF4CAF50)),
              SizedBox(height: 16),
              Text(
                'Pobieranie mapy…',
                style: TextStyle(color: Colors.black54, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }
    if (imageBytes != null) {
      return InteractiveViewer(
        transformationController: controller,
        panEnabled: true,
        scaleEnabled: true,
        minScale: minScale,
        maxScale: maxScale,
        boundaryMargin: const EdgeInsets.all(80),
        constrained: false,
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: child,
        ),
      );
    }
    return const ColoredBox(color: Colors.white);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: pasek wyszukiwania
// ─────────────────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    this.onSubmitted,
    this.isLoading = false,
  });

  final TextEditingController controller;
  final ValueChanged<String>? onSubmitted;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
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
              textAlignVertical: TextAlignVertical.center,
              style: const TextStyle(fontSize: 15),
              textInputAction: TextInputAction.search,
              onSubmitted: onSubmitted,
              decoration: InputDecoration(
                hintText: isLoading ? 'Ładowanie miast…' : 'Wyszukaj miasto…',
                hintStyle: const TextStyle(color: Colors.black45, fontSize: 15),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 0,
                ),
              ),
            ),
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF4CAF50),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: lista podpowiedzi
// ─────────────────────────────────────────────────────────────────────────────

class _SuggestionList extends StatelessWidget {
  const _SuggestionList({required this.suggestions, required this.onSelected});

  final List<City> suggestions;
  final void Function(City) onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: suggestions.map((city) {
            return InkWell(
              onTap: () => onSelected(city),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: baner błędu
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFD32F2F),
      borderRadius: BorderRadius.circular(8),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
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
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: panel menu
// ─────────────────────────────────────────────────────────────────────────────

class _DropMenu extends StatelessWidget {
  const _DropMenu({required this.onClose});

  final VoidCallback onClose;

  static const List<_MenuItemData> _items = [
    _MenuItemData(icon: Icons.podcasts, label: 'Lista Stacji radiowych'),
    _MenuItemData(icon: Icons.wb_cloudy_outlined, label: 'Pogoda w miastach'),
    _MenuItemData(icon: Icons.wifi, label: 'Status połączenia z serwerem'),
    _MenuItemData(icon: Icons.group, label: 'Wykonawcy'),
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 6,
      shadowColor: Colors.black26,
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(4),
        bottomRight: Radius.circular(4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(
            height: 56,
            child: Center(
              child: Text(
                'Menu',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1),
          for (int i = 0; i < _items.length; i++) ...[
            _MenuRow(
              icon: _items[i].icon,
              label: _items[i].label,
              onTap: () {
                onClose(); // Zamknij menu po kliknięciu
                switch (_items[i].label) {
                  case 'Lista Stacji radiowych':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RadioStationsScreen(),
                      ),
                    );
                    break;
                  case 'Pogoda w miastach':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WeatherScreen(),
                      ),
                    );
                    break;
                  case 'Status połączenia z serwerem':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ServerStatusScreen(),
                      ),
                    );
                    break;
                  case 'Wykonawcy':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AuthorsScreen(),
                      ),
                    );
                    break;
                }
              },
            ),
            if (i < _items.length - 1)
              const Divider(height: 1, thickness: 1, indent: 20, endIndent: 20),
          ],
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _MenuItemData {
  const _MenuItemData({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Row(
          children: [
            Icon(icon, size: 24, color: const Color(0xFF4CAF50)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF212121),
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: przycisk hamburgera
// ─────────────────────────────────────────────────────────────────────────────

class _HamburgerButton extends StatelessWidget {
  const _HamburgerButton({required this.isOpen, required this.onPressed});

  final bool isOpen;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onPressed,
        child: SizedBox(
          width: 46,
          height: 46,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Icon(
              isOpen ? Icons.close : Icons.menu,
              key: ValueKey(isOpen),
              size: 26,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: okrągły przycisk ikony (np. lupa)
// ─────────────────────────────────────────────────────────────────────────────

class _IconCircleButton extends StatelessWidget {
  const _IconCircleButton({
    required this.icon,
    required this.onPressed,
    this.tooltip = '',
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 3,
        shadowColor: Colors.black26,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, size: 22, color: Colors.black87),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: przycisk zoom
// ─────────────────────────────────────────────────────────────────────────────

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF4CAF50),
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: Colors.black38,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: Colors.white, size: 26),
        ),
      ),
    );
  }
}
