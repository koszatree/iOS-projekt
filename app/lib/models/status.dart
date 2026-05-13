import 'package:xml/xml.dart';

class Status {
  final String serviceName;
  final String externalServiceName;
  final String checkedUrl;
  final String checkedAt;
  final String httpStatusCode;
  final String message;
  final int responseTimeMs;
  final bool ok;

  const Status({
    required this.serviceName,
    required this.externalServiceName,
    required this.checkedUrl,
    required this.checkedAt,
    required this.httpStatusCode,
    required this.message,
    required this.responseTimeMs,
    required this.ok,
  });

  /// Parsuje pojedynczy element usługi, np. <coordinateService> lub <musicService>.
  factory Status.fromXml(XmlElement el) {
    String t(String tag) =>
        el.findElements(tag).firstOrNull?.innerText.trim() ?? '';

    return Status(
      serviceName: t('serviceName'),
      externalServiceName: t('externalServiceName'),
      checkedUrl: t('checkedUrl'),
      checkedAt: t('checkedAt'),
      httpStatusCode: t('httpStatusCode'),
      message: t('message'),
      responseTimeMs: int.tryParse(t('responseTimeMs')) ?? 0,
      ok: t('ok') == 'true',
    );
  }
}
