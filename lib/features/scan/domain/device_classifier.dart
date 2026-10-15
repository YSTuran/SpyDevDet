import 'package:spy_dev_det/features/scan/domain/device_evidence.dart';
import 'package:spy_dev_det/features/scan/domain/device_observation.dart';

class DeviceClassifier {
  const DeviceClassifier();

  DeviceObservation classify(
    DeviceObservation device, {
    required String? gatewayIpv4,
  }) {
    final searchable = [
      ...device.services,
      ...device.evidence.map(
        (item) => '${item.description} ${item.serviceType ?? ''}',
      ),
    ].join(' ').toLowerCase();

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

    final isPrinter = _containsAny(searchable, const [
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

    final hasRtsp = _containsAny(searchable, const ['rtsp', '_rtsp._tcp']);
    final hasCameraIdentity = _containsAny(searchable, const [
      'onvif',
      'ipcamera',
      'networkcamera',
      'camera',
    ]);
    if (hasRtsp || hasCameraIdentity) {
      return device.copyWith(
        category: DeviceCategory.cameraCandidate,
        confidence: hasRtsp && hasCameraIdentity
            ? ConfidenceLevel.high
            : ConfidenceLevel.low,
      );
    }

    if (_containsAny(searchable, const [
      '_googlecast._tcp',
      '_airplay._tcp',
      '_hap._tcp',
      'mediarenderer',
      'dial receiver',
    ])) {
      return device.copyWith(
        category: DeviceCategory.mediaDevice,
        confidence: ConfidenceLevel.high,
      );
    }

    if (_containsAny(searchable, const [
      '_workstation._tcp',
      '_device-info._tcp',
      'ssh (22)',
    ])) {
      return device.copyWith(
        category: DeviceCategory.computerOrPhone,
        confidence: searchable.contains('_workstation._tcp')
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
