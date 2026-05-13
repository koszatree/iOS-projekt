import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import 'package:app/models/status.dart';

class ServiceStatus {
  static const String _endpoint =
      'http://localhost:8080/platform-service-2.3-SNAPSHOT/AggregationService';
  /*
  static const String _endpointMusicService =
      'http://localhost:8080/platform-service-2.3-SNAPSHOT/MusicService';
  static const String _endpointCoordinateService =
      'http://localhost:8080/platform-service-2.3-SNAPSHOT/CoordinateService';
  static const String _endpointWeatherService =
      'http://localhost:8080/platform-service-2.3-SNAPSHOT/WeatherService';
  */

  static const Map<String, String> _headers = {
    'Content-Type': 'text/xml; charset=utf-8',
    'SOAPAction': '',
  };

  static const List<String> _serviceTagNames = [
    'coordinateService',
    'musicService',
    'weatherService',
  ];

  static Future<
    ({
      List<Status> statuses,
      String checkedAt,
      String message,
      bool ok,
      int responseTimeMs,
    })
  >
  pingAll() async {
    const body =
        '<soapenv:Envelope '
        'xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" '
        'xmlns:agg="http://aggregation.platformservice.pnpios.pl/">'
        '<soapenv:Header/>'
        '<soapenv:Body>'
        '<agg:pingAll/>'
        '</soapenv:Body>'
        '</soapenv:Envelope>';

    final response = await http
        .post(Uri.parse(_endpoint), headers: _headers, body: body)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('pingAll HTTP ${response.statusCode}');
    }

    final doc = XmlDocument.parse(utf8.decode(response.bodyBytes));

    final returnEl = doc.findAllElements('return').firstOrNull;
    if (returnEl == null) {
      throw Exception('Brak elementu <return> w odpowiedzi serwera');
    }

    String t(String tag) =>
        returnEl.findElements(tag).firstOrNull?.innerText.trim() ?? '';

    final statuses = <Status>[];
    for (final tag in _serviceTagNames) {
      final el = returnEl.findElements(tag).firstOrNull;
      if (el != null) statuses.add(Status.fromXml(el));
    }

    return (
      statuses: statuses,
      checkedAt: t('checkedAt'),
      message: t('message'),
      ok: t('ok') == 'true',
      responseTimeMs: int.tryParse(t('responseTimeMs')) ?? 0,
    );
  }
}
