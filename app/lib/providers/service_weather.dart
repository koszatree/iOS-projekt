import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import 'package:app/models/city.dart';
import 'package:app/models/daily_temperature.dart';
import 'package:app/models/hourly_temperature.dart';

class ServiceWeather {
  static const String _endpoint =
      'http://localhost:8080/platform-service-2.3-SNAPSHOT/WeatherService';

  static const Map<String, String> _headers = {
    'Content-Type': 'text/xml; charset=utf-8',
    'SOAPAction': '',
  };

  /// Pobiera średnie temperatury dzienne dla podanych współrzędnych
  static Future<DailyTemperatureResponse> getDailyAverageTemperature({
    required double latitude,
    required double longitude,
  }) async {
    final body =
        '<soapenv:Envelope '
        'xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" '
        'xmlns:wea="http://weather.platformservice.pnpios.pl/">'
        '<soapenv:Header/>'
        '<soapenv:Body>'
        '<wea:getDailyAverageTemperatureMonth>'
        '<latitude>$latitude</latitude>'
        '<longitude>$longitude</longitude>'
        '</wea:getDailyAverageTemperatureMonth>'
        '</soapenv:Body>'
        '</soapenv:Envelope>';

    final response = await http
        .post(Uri.parse(_endpoint), headers: _headers, body: body)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(
        'getDailyAverageTemperatureMonth HTTP ${response.statusCode}',
      );
    }

    final doc = XmlDocument.parse(utf8.decode(response.bodyBytes));
    final returnEl = doc.findAllElements('return').firstOrNull;
    if (returnEl == null) {
      throw Exception(
        'Brak elementu <return> w odpowiedzi getDailyAverageTemperatureMonth',
      );
    }

    final days = returnEl
        .findElements('days')
        .map(DailyTemperature.fromXml)
        .toList();

    return DailyTemperatureResponse(days: days);
  }

  /// Wygodna wersja przyjmująca obiekt City.
  static Future<DailyTemperatureResponse> getDailyAverageTemperatureForCity(
    City city,
  ) => getDailyAverageTemperature(
    latitude: city.latitude,
    longitude: city.longitude,
  );

  /// Pobiera temperatury godzinowe dla podanych współrzędnych i daty.

  static Future<HourlyTemperatureResponse> getHourlyTemperatureForDay({
    required double latitude,
    required double longitude,
    required String date,
  }) async {
    final body =
        '<soapenv:Envelope '
        'xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" '
        'xmlns:wea="http://weather.platformservice.pnpios.pl/">'
        '<soapenv:Header/>'
        '<soapenv:Body>'
        '<wea:getHourlyTemperatureForDay>'
        '<latitude>$latitude</latitude>'
        '<longitude>$longitude</longitude>'
        '<date>$date</date>'
        '</wea:getHourlyTemperatureForDay>'
        '</soapenv:Body>'
        '</soapenv:Envelope>';

    final response = await http
        .post(Uri.parse(_endpoint), headers: _headers, body: body)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('getHourlyTemperatureForDay HTTP ${response.statusCode}');
    }

    final doc = XmlDocument.parse(utf8.decode(response.bodyBytes));
    final returnEl = doc.findAllElements('return').firstOrNull;
    if (returnEl == null) {
      throw Exception(
        'Brak elementu <return> w odpowiedzi getHourlyTemperatureForDay',
      );
    }

    final responseDate =
        returnEl.findElements('date').firstOrNull?.innerText.trim() ?? date;

    final hours = returnEl
        .findElements('hours')
        .map(HourlyEntry.fromXml)
        .toList();

    return HourlyTemperatureResponse(date: responseDate, hours: hours);
  }

  static Future<HourlyTemperatureResponse> getHourlyTemperatureForCity({
    required City city,
    required String date,
  }) => getHourlyTemperatureForDay(
    latitude: city.latitude,
    longitude: city.longitude,
    date: date,
  );

  /// Pobiera aktualną temperaturę dla miasta (dzisiejsza data, bieżąca godzina).
  /// Zwraca wartość w °C lub null w razie błędu.
  static Future<double?> getCurrentTemperatureForCity(City city) async {
    try {
      final today = _todayDateString();
      final hourly = await getHourlyTemperatureForCity(city: city, date: today);
      return hourly.current?.temperature;
    } catch (_) {
      return null;
    }
  }

  /// Dzisiejsza data w formacie "YYYY-MM-DD".
  static String _todayDateString() {
    final now = DateTime.now();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '${now.year}-$m-$d';
  }
}
