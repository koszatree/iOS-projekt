import 'package:xml/xml.dart';

class HourlyEntry {
  final String time;
  final double temperature;

  const HourlyEntry({required this.time, required this.temperature});

  factory HourlyEntry.fromXml(XmlElement el) {
    String t(String tag) =>
        el.findElements(tag).firstOrNull?.innerText.trim() ?? '';

    return HourlyEntry(
      time: t('time'),
      temperature: double.tryParse(t('temperature')) ?? 0.0,
    );
  }

  DateTime? get dateTime => DateTime.tryParse(time);

  int get hour => dateTime?.hour ?? 0;

  @override
  String toString() => 'HourlyEntry($time, ${temperature}°C)';
}

class HourlyTemperatureResponse {
  final String date;
  final List<HourlyEntry> hours;

  const HourlyTemperatureResponse({required this.date, required this.hours});

  HourlyEntry? atHour(int hour) {
    try {
      return hours.firstWhere((h) => h.hour == hour);
    } catch (_) {
      return null;
    }
  }

  HourlyEntry? get current {
    final now = DateTime.now().hour;
    return atHour(now) ?? (hours.isNotEmpty ? hours.first : null);
  }
}
