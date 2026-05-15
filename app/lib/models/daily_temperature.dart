import 'package:xml/xml.dart';

class DailyTemperature {
  final String date;
  final double averageTemperature;

  const DailyTemperature({
    required this.date,
    required this.averageTemperature,
  });

  factory DailyTemperature.fromXml(XmlElement el) {
    String t(String tag) =>
        el.findElements(tag).firstOrNull?.innerText.trim() ?? '';

    return DailyTemperature(
      date: t('date'),
      averageTemperature: double.tryParse(t('averageTemperature')) ?? 0.0,
    );
  }

  DateTime? get dateTime => DateTime.tryParse(date);

  @override
  String toString() => 'DailyTemperature($date, ${averageTemperature}°C)';
}

class DailyTemperatureResponse {
  final List<DailyTemperature> days;

  const DailyTemperatureResponse({required this.days});

  DailyTemperature? get today => days.isNotEmpty ? days.first : null;

  DailyTemperature? forDate(String date) {
    try {
      return days.firstWhere((d) => d.date == date);
    } catch (_) {
      return null;
    }
  }
}
