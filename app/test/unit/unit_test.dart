import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/city.dart';

String buildGetMapTileBody(City city) {
  return '<soapenv:Envelope '
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
}

void main() {
  test('buduje poprawne SOAP body dla getMapTile na podstawie City', () {
    const city = City(
      name: 'Gdańsk-local',
      latitude: 54.352,
      longitude: 18.646,
      radiusKm: 10.0,
      minLon: 18.50,
      minLat: 54.30,
      maxLon: 18.75,
      maxLat: 54.40,
      width: 1024,
      height: 768,
    );

    final body = buildGetMapTileBody(city);

    expect(body, contains('<minLon>18.5</minLon>'));
    expect(body, contains('<minLat>54.3</minLat>'));
    expect(body, contains('<maxLon>18.75</maxLon>'));
    expect(body, contains('<maxLat>54.4</maxLat>'));
    expect(body, contains('<width>1024</width>'));
    expect(body, contains('<height>768</height>'));
  });
}
