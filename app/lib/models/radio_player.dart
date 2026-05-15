import 'package:xml/xml.dart';

class RadioPlayer {
  final String stationUuid;
  final String stationName;
  final String streamUrl;
  final String originalUrl;
  final String contentType;
  final String streamType;
  final bool ok;
  final bool playable;
  final bool liveStream;
  final String message;

  const RadioPlayer({
    required this.stationUuid,
    required this.stationName,
    required this.streamUrl,
    required this.originalUrl,
    required this.contentType,
    required this.streamType,
    required this.ok,
    required this.playable,
    required this.liveStream,
    required this.message,
  });

  factory RadioPlayer.fromXml(XmlElement el) {
    String t(String tag) =>
        el.findElements(tag).firstOrNull?.innerText.trim() ?? '';

    return RadioPlayer(
      stationUuid: t('stationUuid'),
      stationName: t('stationName'),
      streamUrl: t('streamUrl'),
      originalUrl: t('originalUrl'),
      contentType: t('contentType'),
      streamType: t('streamType'),
      ok: t('ok') == 'true',
      playable: t('playable') == 'true',
      liveStream: t('liveStream') == 'true',
      message: t('message'),
    );
  }
}
