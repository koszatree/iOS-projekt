import 'package:xml/xml.dart';

class City {
  final String name;
  final double latitude;
  final double longitude;
  final double radiusKm;
  final double minLon;
  final double minLat;
  final double maxLon;
  final double maxLat;
  final int width;
  final int height;

  const City({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusKm,
    required this.minLon,
    required this.minLat,
    required this.maxLon,
    required this.maxLat,
    required this.width,
    required this.height,
  });

  factory City.fromXml(XmlElement el) {
    String t(String tag) => el.findElements(tag).first.innerText.trim();
    return City(
      name: t('name'),
      latitude: double.parse(t('latitude')),
      longitude: double.parse(t('longitude')),
      radiusKm: double.parse(t('radiusKm')),
      minLon: double.parse(t('minLon')),
      minLat: double.parse(t('minLat')),
      maxLon: double.parse(t('maxLon')),
      maxLat: double.parse(t('maxLat')),
      width: int.parse(t('width')),
      height: int.parse(t('height')),
    );
  }

  @override
  String toString() => 'City($name, lat=$latitude, lon=$longitude)';
}
