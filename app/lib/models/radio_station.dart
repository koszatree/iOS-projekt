import 'package:xml/xml.dart';

class RadioStation {
  final String stationUuid;
  final String name;
  final String country;
  final String countryCode;
  final String codec;
  final int bitrate;
  final String homepage;
  final String favicon;
  final double geoLat;
  final double geoLon;
  final bool hls;
  final bool lastCheckOk;

  const RadioStation({
    required this.stationUuid,
    required this.name,
    required this.country,
    required this.countryCode,
    required this.codec,
    required this.bitrate,
    required this.homepage,
    required this.favicon,
    required this.geoLat,
    required this.geoLon,
    required this.hls,
    required this.lastCheckOk,
  });

  factory RadioStation.fromXml(XmlElement el) {
    String t(String tag) =>
        el.findElements(tag).firstOrNull?.innerText.trim() ?? '';

    return RadioStation(
      stationUuid: t('stationUuid'),
      name: t('name'),
      country: t('country'),
      countryCode: t('countryCode'),
      codec: t('codec'),
      bitrate: int.tryParse(t('bitrate')) ?? 0,
      homepage: t('homepage'),
      favicon: t('favicon'),
      geoLat: double.tryParse(t('geoLat')) ?? 0.0,
      geoLon: double.tryParse(t('geoLon')) ?? 0.0,
      hls: t('hls') == 'true',
      lastCheckOk: t('lastCheckOk') == 'true',
    );
  }
}
