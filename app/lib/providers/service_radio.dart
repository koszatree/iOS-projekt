import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import 'package:app/models/city.dart';
import 'package:app/models/radio_station.dart';
import 'package:app/providers/service_soap.dart';

class ServiceRadio {
  static const String _endpoint =
      'http://localhost:8080/platform-service-2.3-SNAPSHOT/MusicService';

  static const Map<String, String> _headers = {
    'Content-Type': 'text/xml; charset=utf-8',
    'SOAPAction': '',
  };

  /// Zwraca listę dostępnych miast (deleguje do MapSoapService).
  static Future<List<City>> getCities() => MapSoapService.getCities();

  /// Pobiera stacje radiowe w granicach wybranego miasta.
  static Future<List<RadioStation>> getStationsForCity(
    City city, {
    int limit = 100,
  }) async {
    final body =
        '<soapenv:Envelope '
        'xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" '
        'xmlns:mus="http://music.platformservice.pnpios.pl/">'
        '<soapenv:Header/>'
        '<soapenv:Body>'
        '<mus:getStationsInMapBounds>'
        '<minLat>${city.minLat}</minLat>'
        '<minLon>${city.minLon}</minLon>'
        '<maxLat>${city.maxLat}</maxLat>'
        '<maxLon>${city.maxLon}</maxLon>'
        '<limit>$limit</limit>'
        '</mus:getStationsInMapBounds>'
        '</soapenv:Body>'
        '</soapenv:Envelope>';

    final response = await http
        .post(Uri.parse(_endpoint), headers: _headers, body: body)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('getStationsInMapBounds HTTP ${response.statusCode}');
    }

    final doc = XmlDocument.parse(utf8.decode(response.bodyBytes));
    return doc.findAllElements('return').map(RadioStation.fromXml).toList();
  }
}
