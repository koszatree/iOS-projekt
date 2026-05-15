import 'package:flutter/material.dart';

import 'package:app/models/city.dart';
import 'package:app/models/daily_temperature.dart';
import 'package:app/models/hourly_temperature.dart';
import 'package:app/providers/service_soap.dart';
import 'package:app/providers/service_weather.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Ekran pogody – punkt wejścia
// ─────────────────────────────────────────────────────────────────────────────

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  List<City> _cities = [];
  // Aktualna temperatura dla każdego miasta (null = ładowanie/błąd)
  final Map<String, double?> _currentTemps = {};
  bool _loadingCities = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  Future<void> _loadCities() async {
    setState(() {
      _loadingCities = true;
      _errorMessage = null;
    });
    try {
      final cities = await MapSoapService.getCities();
      setState(() {
        _cities = cities;
        _loadingCities = false;
      });
      // Pobierz temperatury równolegle dla wszystkich miast
      _loadTemperatures(cities);
    } catch (e) {
      setState(() {
        _loadingCities = false;
        _errorMessage = 'Błąd pobierania miast: $e';
      });
    }
  }

  Future<void> _loadTemperatures(List<City> cities) async {
    await Future.wait(
      cities.map((city) async {
        final temp = await ServiceWeather.getCurrentTemperatureForCity(city);
        if (mounted) {
          setState(() => _currentTemps[city.name] = temp);
        }
      }),
    );
  }

  void _openCity(City city) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => _CityWeatherScreen(city: city)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('Pogoda w miastach'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Odśwież',
            onPressed: _loadCities,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loadingCities) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF4CAF50)),
            SizedBox(height: 16),
            Text(
              'Pobieranie miast…',
              style: TextStyle(color: Colors.black54, fontSize: 14),
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
              const Icon(Icons.cloud_off, size: 64, color: Color(0xFFD32F2F)),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 14, color: Color(0xFFD32F2F)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadCities,
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

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      itemCount: _cities.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final city = _cities[i];
        final temp = _currentTemps[city.name];
        final hasTemp = _currentTemps.containsKey(city.name);

        return _CityRow(
          city: city,
          temperature: temp,
          isLoadingTemp: !hasTemp,
          onTap: () => _openCity(city),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: wiersz miasta z aktualną temperaturą
// ─────────────────────────────────────────────────────────────────────────────

class _CityRow extends StatelessWidget {
  const _CityRow({
    required this.city,
    required this.temperature,
    required this.isLoadingTemp,
    required this.onTap,
  });

  final City city;
  final double? temperature;
  final bool isLoadingTemp;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Ikona
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.location_city,
                  color: Color(0xFF4CAF50),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),

              // Nazwa miasta
              Expanded(
                child: Text(
                  city.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF212121),
                  ),
                ),
              ),

              // Temperatura
              if (isLoadingTemp)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF4CAF50),
                  ),
                )
              else if (temperature != null)
                _TempBadge(temperature: temperature!)
              else
                const Icon(Icons.cloud_off, size: 20, color: Colors.black26),

              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.black26, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ekran szczegółowy miasta – prognoza 16 dni + godzinowa
// ─────────────────────────────────────────────────────────────────────────────

class _CityWeatherScreen extends StatefulWidget {
  const _CityWeatherScreen({required this.city});

  final City city;

  @override
  State<_CityWeatherScreen> createState() => _CityWeatherScreenState();
}

class _CityWeatherScreenState extends State<_CityWeatherScreen> {
  // Przełącznik widoku
  bool _showHourly = false;

  // Prognoza 16-dniowa
  DailyTemperatureResponse? _dailyForecast;
  bool _loadingDaily = true;
  String? _dailyError;

  // Prognoza godzinowa
  HourlyTemperatureResponse? _hourlyForecast;
  bool _loadingHourly = false;
  String? _hourlyError;

  // Wybrany dzień dla prognozy godzinowej
  DailyTemperature? _selectedDay;

  @override
  void initState() {
    super.initState();
    _loadDailyForecast();
  }

  // ── Ładowanie prognozy dziennej ───────────────────────────────────────────

  Future<void> _loadDailyForecast() async {
    setState(() {
      _loadingDaily = true;
      _dailyError = null;
    });
    try {
      final forecast = await ServiceWeather.getDailyAverageTemperatureForCity(
        widget.city,
      );
      setState(() {
        _dailyForecast = forecast;
        _loadingDaily = false;
        // Domyślnie zaznacz dzisiaj
        _selectedDay = forecast.today;
      });
    } catch (e) {
      setState(() {
        _loadingDaily = false;
        _dailyError = 'Błąd pobierania prognozy: $e';
      });
    }
  }

  // ── Ładowanie prognozy godzinowej ─────────────────────────────────────────

  Future<void> _loadHourlyForecast(String date) async {
    setState(() {
      _loadingHourly = true;
      _hourlyError = null;
      _hourlyForecast = null;
    });
    try {
      final forecast = await ServiceWeather.getHourlyTemperatureForCity(
        city: widget.city,
        date: date,
      );
      setState(() {
        _hourlyForecast = forecast;
        _loadingHourly = false;
      });
    } catch (e) {
      setState(() {
        _loadingHourly = false;
        _hourlyError = 'Błąd pobierania prognozy godzinowej: $e';
      });
    }
  }

  // ── Przełączenie widoku ────────────────────────────────────────────────────

  void _switchView(bool showHourly) {
    if (_showHourly == showHourly) return;
    setState(() => _showHourly = showHourly);
    if (showHourly && _selectedDay != null && _hourlyForecast == null) {
      _loadHourlyForecast(_selectedDay!.date);
    }
  }

  void _selectDay(DailyTemperature day) {
    setState(() => _selectedDay = day);
    if (_showHourly) {
      _loadHourlyForecast(day.date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: Text(widget.city.name),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _loadingDaily
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF4CAF50)),
                  SizedBox(height: 16),
                  Text(
                    'Pobieranie prognozy…',
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                ],
              ),
            )
          : _dailyError != null
          ? _ErrorView(message: _dailyError!, onRetry: _loadDailyForecast)
          : Column(
              children: [
                // ── Przełącznik widoku ─────────────────────────────
                _ViewToggle(showHourly: _showHourly, onChanged: _switchView),

                // ── Zawartość ──────────────────────────────────────
                Expanded(
                  child: _showHourly
                      ? _HourlyView(
                          selectedDay: _selectedDay,
                          allDays: _dailyForecast?.days ?? [],
                          hourlyForecast: _hourlyForecast,
                          isLoading: _loadingHourly,
                          error: _hourlyError,
                          onDaySelected: _selectDay,
                          onRetry: () => _selectedDay != null
                              ? _loadHourlyForecast(_selectedDay!.date)
                              : null,
                        )
                      : _DailyView(
                          days: _dailyForecast?.days ?? [],
                          selectedDay: _selectedDay,
                          onDaySelected: _selectDay,
                        ),
                ),
              ],
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: przełącznik Dzienna / Godzinowa
// ─────────────────────────────────────────────────────────────────────────────

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.showHourly, required this.onChanged});

  final bool showHourly;
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF4CAF50),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF388E3C),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            _ToggleBtn(
              label: 'Prognoza 16-dniowa',
              icon: Icons.calendar_month,
              active: !showHourly,
              onTap: () => onChanged(false),
            ),
            _ToggleBtn(
              label: 'Godzinowa',
              icon: Icons.schedule,
              active: showHourly,
              onTap: () => onChanged(true),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  const _ToggleBtn({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: active ? const Color(0xFF2E7D32) : Colors.white70,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active ? const Color(0xFF2E7D32) : Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: widok prognozy 16-dniowej
// ─────────────────────────────────────────────────────────────────────────────

class _DailyView extends StatelessWidget {
  const _DailyView({
    required this.days,
    required this.selectedDay,
    required this.onDaySelected,
  });

  final List<DailyTemperature> days;
  final DailyTemperature? selectedDay;
  final void Function(DailyTemperature) onDaySelected;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      return const Center(
        child: Text(
          'Brak danych prognozy',
          style: TextStyle(color: Colors.black45),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      itemCount: days.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final day = days[i];
        final isSelected = selectedDay?.date == day.date;
        final isToday = i == 0;

        return _DayCard(
          day: day,
          isSelected: isSelected,
          isToday: isToday,
          onTap: () => onDaySelected(day),
        );
      },
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.day,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  final DailyTemperature day;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  String get _weekdayName {
    const names = [
      'Poniedziałek',
      'Wtorek',
      'Środa',
      'Czwartek',
      'Piątek',
      'Sobota',
      'Niedziela',
    ];
    final dt = day.dateTime;
    if (dt == null) return '';
    return names[dt.weekday - 1];
  }

  String get _formattedDate {
    final dt = day.dateTime;
    if (dt == null) return day.date;
    return '${dt.day}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final temp = day.averageTemperature;
    final tempColor = _tempColor(temp);

    return Card(
      elevation: isSelected ? 4 : 2,
      shadowColor: isSelected
          ? const Color(0xFF4CAF50).withOpacity(0.3)
          : Colors.black12,
      color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? const BorderSide(color: Color(0xFF4CAF50), width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Ikona pogody (uproszczona na podstawie temp)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tempColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_weatherIcon(temp), color: tempColor, size: 22),
              ),
              const SizedBox(width: 14),

              // Dzień tygodnia + data
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          isToday ? 'Dziś' : _weekdayName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFF212121),
                          ),
                        ),
                        if (isToday) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'dziś',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formattedDate,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),

              // Temperatura
              _TempBadge(temperature: temp),
            ],
          ),
        ),
      ),
    );
  }

  IconData _weatherIcon(double t) {
    if (t < 0) return Icons.ac_unit;
    if (t < 10) return Icons.cloud;
    if (t < 20) return Icons.wb_cloudy;
    return Icons.wb_sunny;
  }

  Color _tempColor(double t) {
    if (t < 0) return const Color(0xFF1565C0);
    if (t < 10) return const Color(0xFF1976D2);
    if (t < 20) return const Color(0xFF388E3C);
    if (t < 28) return const Color(0xFFF57C00);
    return const Color(0xFFD32F2F);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: widok prognozy godzinowej
// ─────────────────────────────────────────────────────────────────────────────

class _HourlyView extends StatelessWidget {
  const _HourlyView({
    required this.selectedDay,
    required this.allDays,
    required this.hourlyForecast,
    required this.isLoading,
    required this.error,
    required this.onDaySelected,
    required this.onRetry,
  });

  final DailyTemperature? selectedDay;
  final List<DailyTemperature> allDays;
  final HourlyTemperatureResponse? hourlyForecast;
  final bool isLoading;
  final String? error;
  final void Function(DailyTemperature) onDaySelected;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Selektor dnia ──────────────────────────────────────────────
        _DaySelector(
          days: allDays,
          selectedDay: selectedDay,
          onSelected: onDaySelected,
        ),

        // ── Lista godzin ───────────────────────────────────────────────
        Expanded(child: _buildHourlyContent()),
      ],
    );
  }

  Widget _buildHourlyContent() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
      );
    }
    if (error != null) {
      return _ErrorView(message: error!, onRetry: onRetry);
    }
    if (hourlyForecast == null) {
      return const Center(
        child: Text(
          'Wybierz dzień, aby zobaczyć prognozę godzinową',
          style: TextStyle(color: Colors.black45, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      );
    }
    if (hourlyForecast!.hours.isEmpty) {
      return const Center(
        child: Text(
          'Brak danych godzinowych',
          style: TextStyle(color: Colors.black45),
        ),
      );
    }

    final now = DateTime.now().hour;

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      itemCount: hourlyForecast!.hours.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, i) {
        final entry = hourlyForecast!.hours[i];
        final isCurrent = entry.hour == now;
        return _HourCard(entry: entry, isCurrent: isCurrent);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: poziomy selektor dni (dla widoku godzinowego)
// ─────────────────────────────────────────────────────────────────────────────

class _DaySelector extends StatelessWidget {
  const _DaySelector({
    required this.days,
    required this.selectedDay,
    required this.onSelected,
  });

  final List<DailyTemperature> days;
  final DailyTemperature? selectedDay;
  final void Function(DailyTemperature) onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: days.length,
        itemBuilder: (context, i) {
          final day = days[i];
          final isSelected = selectedDay?.date == day.date;
          final dt = day.dateTime;
          final label = i == 0
              ? 'Dziś'
              : dt != null
              ? '${dt.day}.${dt.month.toString().padLeft(2, '0')}'
              : day.date;

          return GestureDetector(
            onTap: () => onSelected(day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.black54,
                    ),
                  ),
                  Text(
                    '${day.averageTemperature.toStringAsFixed(1)}°',
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? Colors.white70 : Colors.black38,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: karta godziny
// ─────────────────────────────────────────────────────────────────────────────

class _HourCard extends StatelessWidget {
  const _HourCard({required this.entry, required this.isCurrent});

  final HourlyEntry entry;
  final bool isCurrent;

  String get _formattedTime {
    final dt = entry.dateTime;
    if (dt == null) return entry.time;
    return '${dt.hour.toString().padLeft(2, '0')}:00';
  }

  @override
  Widget build(BuildContext context) {
    final temp = entry.temperature;
    final tempColor = _tempColor(temp);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isCurrent ? const Color(0xFFE8F5E9) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: isCurrent
            ? const Border.fromBorderSide(
                BorderSide(color: Color(0xFF4CAF50), width: 1.5),
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Godzina
          SizedBox(
            width: 50,
            child: Text(
              _formattedTime,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                color: isCurrent
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFF212121),
              ),
            ),
          ),

          // Ikona
          Icon(_weatherIcon(temp), color: tempColor, size: 20),
          const SizedBox(width: 12),

          // Pasek temperatury
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ((temp + 20) / 60).clamp(0.0, 1.0),
                backgroundColor: const Color(0xFFF0F0F0),
                color: tempColor,
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Wartość
          _TempBadge(temperature: temp),

          // Marker "teraz"
          if (isCurrent) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'teraz',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _weatherIcon(double t) {
    if (t < 0) return Icons.ac_unit;
    if (t < 10) return Icons.cloud;
    if (t < 20) return Icons.wb_cloudy;
    return Icons.wb_sunny;
  }

  Color _tempColor(double t) {
    if (t < 0) return const Color(0xFF1565C0);
    if (t < 10) return const Color(0xFF1976D2);
    if (t < 20) return const Color(0xFF388E3C);
    if (t < 28) return const Color(0xFFF57C00);
    return const Color(0xFFD32F2F);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: odznaka temperatury
// ─────────────────────────────────────────────────────────────────────────────

class _TempBadge extends StatelessWidget {
  const _TempBadge({required this.temperature});

  final double temperature;

  Color get _color {
    if (temperature < 0) return const Color(0xFF1565C0);
    if (temperature < 10) return const Color(0xFF1976D2);
    if (temperature < 20) return const Color(0xFF388E3C);
    if (temperature < 28) return const Color(0xFFF57C00);
    return const Color(0xFFD32F2F);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${temperature.toStringAsFixed(1)}°C',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: _color,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: widok błędu z przyciskiem retry
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 56, color: Color(0xFFD32F2F)),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(fontSize: 14, color: Color(0xFFD32F2F)),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Spróbuj ponownie'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
