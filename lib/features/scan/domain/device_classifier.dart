import 'package:spy_dev_det/features/scan/domain/device_evidence.dart';
import 'package:spy_dev_det/features/scan/domain/device_observation.dart';
import 'package:spy_dev_det/features/scan/domain/service_catalog.dart';

class DeviceClassifier {
  const DeviceClassifier({this.serviceCatalog = const ServiceCatalog()});

  final ServiceCatalog serviceCatalog;

  DeviceObservation classify(
    DeviceObservation device, {
    required String? gatewayIpv4,
  }) {
    final isLocalDevice = device.evidence.any(
      (item) =>
          item.source == DeviceEvidenceSource.network &&
          item.description == 'Taramanın çalıştığı cihaz',
    );
    if (isLocalDevice) {
      return device.copyWith(
        category: DeviceCategory.computerOrPhone,
        confidence: ConfidenceLevel.high,
      );
    }

    final searchable = [
      ...device.services,
      ...device.evidence.map(
        (item) => '${item.description} ${item.serviceType ?? ''}',
      ),
    ].join(' ').toLowerCase();
    final serviceInsights = serviceCatalog.inspect(device);

    if (gatewayIpv4 != null && device.ipAddress == gatewayIpv4) {
      final hasGatewayEvidence = device.evidence.any(
        (item) => item.source == DeviceEvidenceSource.network,
      );
      return device.copyWith(
        category: DeviceCategory.router,
        confidence: ConfidenceLevel.high,
        evidence: hasGatewayEvidence
            ? device.evidence
            : [
                ...device.evidence,
                const DeviceEvidence(
                  source: DeviceEvidenceSource.network,
                  description:
                      'İşletim sistemi bu adresi ağ geçidi olarak bildirdi',
                ),
              ],
      );
    }

    final isPrinter =
        serviceInsights.any((insight) => insight.kind == ServiceKind.printer) ||
        _containsAny(searchable, const [
          '_ipp._tcp',
          '_printer._tcp',
          'yazıcı servisi',
          'printer',
        ]);
    if (isPrinter) {
      return device.copyWith(
        category: DeviceCategory.printer,
        confidence:
            searchable.contains('_ipp._tcp') ||
                searchable.contains('_printer._tcp')
            ? ConfidenceLevel.high
            : ConfidenceLevel.medium,
      );
    }

    final hasRtsp =
        serviceInsights.any(
          (insight) => insight.kind == ServiceKind.mediaStream,
        ) ||
        _containsAny(searchable, const ['rtsp', '_rtsp._tcp']);
    final hasOnvifVideo = serviceInsights.any(
      (insight) => insight.kind == ServiceKind.onvifVideo,
    );
    final hasCameraIdentity = _containsAny(searchable, const [
      'ipcamera',
      'networkcamera',
      'camera',
    ]);
    if (hasRtsp || hasCameraIdentity || hasOnvifVideo) {
      return device.copyWith(
        category: DeviceCategory.cameraCandidate,
        confidence: hasOnvifVideo || (hasRtsp && hasCameraIdentity)
            ? ConfidenceLevel.high
            : ConfidenceLevel.low,
      );
    }

    if (serviceInsights.any(
          (insight) => insight.kind == ServiceKind.mediaDevice,
        ) ||
        _containsAny(searchable, const ['mediarenderer', 'dial receiver'])) {
      return device.copyWith(
        category: DeviceCategory.mediaDevice,
        confidence: ConfidenceLevel.high,
      );
    }

    final hasComputerService = serviceInsights.any(
      (insight) =>
          insight.kind == ServiceKind.remoteAdministration ||
          insight.kind == ServiceKind.fileSharing,
    );
    if (hasComputerService ||
        _containsAny(searchable, const [
          '_workstation._tcp',
          '_device-info._tcp',
          'ssh (22)',
          'smb/windows paylaşımı (445)',
          'uzak masaüstü (3389)',
          'netbios ad servisi (137)',
        ])) {
      return device.copyWith(
        category: DeviceCategory.computerOrPhone,
        confidence:
            searchable.contains('_workstation._tcp') ||
                serviceInsights.any(
                  (insight) => insight.kind == ServiceKind.fileSharing,
                )
            ? ConfidenceLevel.medium
            : ConfidenceLevel.low,
      );
    }

    return device.copyWith(
      category: DeviceCategory.unknown,
      confidence: ConfidenceLevel.none,
    );
  }

  bool _containsAny(String value, List<String> terms) =>
      terms.any(value.contains);
}
