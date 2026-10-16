import 'package:spy_dev_det/features/scan/domain/device_evidence.dart';
import 'package:spy_dev_det/features/scan/domain/device_observation.dart';

enum ServiceKind {
  remoteAdministration,
  nameService,
  webInterface,
  secureWebInterface,
  mediaStream,
  deviceService,
  printer,
  mediaDevice,
  discovery,
  onvifVideo,
}

class ServiceInsight {
  const ServiceInsight({
    required this.id,
    required this.title,
    required this.explanation,
    required this.kind,
    this.caution,
  });

  final String id;
  final String title;
  final String explanation;
  final ServiceKind kind;
  final String? caution;
}

class ServiceCatalog {
  const ServiceCatalog();

  List<ServiceInsight> inspect(DeviceObservation device) {
    final insights = <String, ServiceInsight>{};
    for (final evidence in device.evidence) {
      if (evidence.source == DeviceEvidenceSource.tcp &&
          evidence.description.contains('bağlantı kabul etti') &&
          evidence.port != null) {
        final port = evidence.port!;
        final insight = _tcpPort(port);
        if (insight != null) {
          insights[insight.id] = insight;
        }
      }

      final serviceType = evidence.serviceType?.toLowerCase() ?? '';
      if (evidence.source == DeviceEvidenceSource.mdns) {
        final insight = _mdns(serviceType);
        if (insight != null) {
          insights[insight.id] = insight;
        }
      }
      if (evidence.source == DeviceEvidenceSource.ssdp) {
        insights['ssdp'] = const ServiceInsight(
          id: 'ssdp',
          title: 'SSDP/UPnP duyurusu',
          explanation: 'Cihaz kendisini yerel ağda UPnP üzerinden duyurdu.',
          kind: ServiceKind.discovery,
          caution: 'Duyuru cihazın güvenilir veya güvensiz olduğunu göstermez.',
        );
      }
      if (evidence.source == DeviceEvidenceSource.onvif) {
        final video = serviceType.contains('networkvideotransmitter');
        insights[video ? 'onvif-video' : 'onvif'] = ServiceInsight(
          id: video ? 'onvif-video' : 'onvif',
          title: video ? 'ONVIF video cihazı duyurusu' : 'ONVIF duyurusu',
          explanation: video
              ? 'Cihaz, WS-Discovery yanıtında kendisini ağ video vericisi olarak tanıttı.'
              : 'Cihaz ONVIF/WS-Discovery keşfine yanıt verdi.',
          kind: video ? ServiceKind.onvifVideo : ServiceKind.discovery,
          caution:
              'Bu bulgu cihazın gizli veya kötü amaçlı olduğunu kanıtlamaz.',
        );
      }
    }
    return List.unmodifiable(insights.values);
  }

  ServiceInsight? _tcpPort(int port) => switch (port) {
    22 => const ServiceInsight(
      id: 'tcp-22',
      title: 'SSH (TCP 22)',
      explanation: 'Uzaktan komut satırı veya cihaz yönetimi servisi olabilir.',
      kind: ServiceKind.remoteAdministration,
    ),
    53 => const ServiceInsight(
      id: 'tcp-53',
      title: 'DNS (TCP 53)',
      explanation: 'Alan adı çözümleme servisi olabilir.',
      kind: ServiceKind.nameService,
    ),
    80 || 8080 => ServiceInsight(
      id: 'tcp-$port',
      title: 'Web arayüzü (TCP $port)',
      explanation: 'Yerel web yönetim arayüzü veya cihaz servisi olabilir.',
      kind: ServiceKind.webInterface,
      caution: 'Açık bir web portu tek başına kamera kanıtı değildir.',
    ),
    443 => const ServiceInsight(
      id: 'tcp-443',
      title: 'HTTPS (TCP 443)',
      explanation: 'Şifreli yerel web yönetim arayüzü olabilir.',
      kind: ServiceKind.secureWebInterface,
    ),
    554 => const ServiceInsight(
      id: 'tcp-554',
      title: 'RTSP (TCP 554)',
      explanation: 'Ses veya video akışı sunan bir medya servisi olabilir.',
      kind: ServiceKind.mediaStream,
      caution: 'RTSP tek başına cihazın kamera olduğunu kesinleştirmez.',
    ),
    8000 => const ServiceInsight(
      id: 'tcp-8000',
      title: 'Cihaz servisi (TCP 8000)',
      explanation: 'Üreticiye özgü web, yönetim veya medya servisi olabilir.',
      kind: ServiceKind.deviceService,
    ),
    9100 => const ServiceInsight(
      id: 'tcp-9100',
      title: 'Yazıcı servisi (TCP 9100)',
      explanation: 'Ağ üzerinden doğrudan yazdırma servisi olabilir.',
      kind: ServiceKind.printer,
    ),
    _ => null,
  };

  ServiceInsight? _mdns(String type) {
    if (type.contains('_ipp._tcp') || type.contains('_printer._tcp')) {
      return const ServiceInsight(
        id: 'mdns-printer',
        title: 'mDNS yazıcı duyurusu',
        explanation: 'Cihaz yerel ağda yazdırma hizmeti duyurdu.',
        kind: ServiceKind.printer,
      );
    }
    if (type.contains('_rtsp._tcp')) {
      return const ServiceInsight(
        id: 'mdns-rtsp',
        title: 'mDNS RTSP duyurusu',
        explanation: 'Cihaz yerel ağda bir medya akışı servisi duyurdu.',
        kind: ServiceKind.mediaStream,
      );
    }
    if (type.contains('_googlecast._tcp') ||
        type.contains('_airplay._tcp') ||
        type.contains('_hap._tcp')) {
      return const ServiceInsight(
        id: 'mdns-media',
        title: 'Akıllı ev/medya duyurusu',
        explanation: 'Cihaz bir medya oynatma veya akıllı ev servisi duyurdu.',
        kind: ServiceKind.mediaDevice,
      );
    }
    if (type.isNotEmpty) {
      return ServiceInsight(
        id: 'mdns-$type',
        title: 'mDNS servis duyurusu',
        explanation: 'Cihaz yerel ağda $type servisini duyurdu.',
        kind: ServiceKind.discovery,
      );
    }
    return null;
  }
}
