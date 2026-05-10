import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import 'package:app/models/city.dart';

class MapSoapService {
  static const String _endpoint =
      'http://localhost:8080/platform-service-2.3-SNAPSHOT/CoordinateService';

  static const Map<String, String> _headers = {
    'Content-Type': 'text/xml; charset=utf-8',
    'SOAPAction': '',
  };

  /// Pobiera listę dostępnych miast z serwera.
  static Future<List<City>> getCities() async {
    const body =
        '<soapenv:Envelope '
        'xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" '
        'xmlns:coo="http://coordinate.platformservice.pnpios.pl/">'
        '<soapenv:Header/>'
        '<soapenv:Body><coo:getCities/></soapenv:Body>'
        '</soapenv:Envelope>';

    final response = await http
        .post(Uri.parse(_endpoint), headers: _headers, body: body)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('getCities HTTP ${response.statusCode}');
    }

    final doc = XmlDocument.parse(utf8.decode(response.bodyBytes));
    return doc.findAllElements('city').map(City.fromXml).toList();
  }

  static Future<City> getCityByName(String name) async {
    final cities = await getCities();
    return cities.firstWhere(
      (c) => c.name.toLowerCase() == name.toLowerCase(),
      orElse: () => throw Exception('Miasto "$name" nie znalezione'),
    );
  }

  /// Pobiera kafelek mapy dla wybranego miasta, zwraca bajty obrazu.
  ///
  /// Obsługuje zarówno odpowiedź binarną (Content-Type: image/*)
  /// jak i base64 osadzone w tagu SOAP (<return>, <mapTile> lub <map>).
  static Future<Uint8List> getMapTile(City city) async {
    final body =
        '<soapenv:Envelope '
        'xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" '
        'xmlns:coo="http://coordinate.platformservice.pnpios.pl/">'
        '<soapenv:Header/>'
        '<soapenv:Body>'
        '<coo:getMapTile>'
        '<minLon>${city.minLon}</minLon>'
        '<minLat>${city.minLat}</minLat>'
        '<maxLon>${city.maxLon}</maxLon>'
        '<maxLat>${city.maxLat}</maxLat>'
        '<width>${city.width}</width>'
        '<height>${city.height}</height>'
        '</coo:getMapTile>'
        '</soapenv:Body>'
        '</soapenv:Envelope>';

    final response = await http
        .post(Uri.parse(_endpoint), headers: _headers, body: body)
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('getMapTile HTTP ${response.statusCode}');
    }

    // Odpowiedź binarna
    final contentType = response.headers['content-type'] ?? '';
    if (contentType.contains('image')) {
      return response.bodyBytes;
    }

    // Odpowiedź SOAP – base64 w tagu <imageBase64>
    final doc = XmlDocument.parse(utf8.decode(response.bodyBytes));
    final imageEl = doc.findAllElements('imageBase64').firstOrNull;

    if (imageEl != null && imageEl.innerText.trim().isNotEmpty) {
      return base64Decode(imageEl.innerText.trim());
    }

    throw Exception('Nie znaleziono tagu <imageBase64> w odpowiedzi serwera');
  }
}
