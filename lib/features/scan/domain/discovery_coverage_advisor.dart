import 'package:spy_dev_det/features/scan/domain/scan_report.dart';

class DiscoveryCoverageAdvisor {
  const DiscoveryCoverageAdvisor();

  List<String> explain({
    required Map<DiscoveryMethod, DiscoveryMethodResult> methods,
    bool rangeTruncated = false,
    bool noDevicesObserved = false,
    bool hasMissingDevices = false,
  }) {
    final explanations = <String>[];
    final reachability = methods[DiscoveryMethod.reachability];
    final neighbor = methods[DiscoveryMethod.neighbor];
    final multicastMethods = const [
      DiscoveryMethod.mdns,
      DiscoveryMethod.ssdp,
      DiscoveryMethod.onvif,
    ];

    if (rangeTruncated) {
      explanations.add(
        'Büyük ağın yalnız güvenli 254 adreslik bölümü tarandı; diğer '
        'adreslerdeki cihazlar görünmemiş olabilir.',
      );
    }
    if (_isUnavailable(reachability)) {
      explanations.add(
        'İşletim sistemi erişilebilirlik kontrolü kullanılamadı; açık TCP '
        'portu bulunmayan cihazlar gözlemlenmemiş olabilir.',
      );
    }
    if (_isUnavailable(neighbor) ||
        neighbor?.phase == DiscoveryMethodPhase.platformRestricted) {
      explanations.add(
        neighbor?.userMessage ??
            'Komşu tablosuna erişilemediği için bazı cihazların MAC ve '
                'üretici bilgileri alınamamış olabilir.',
      );
    }
    if (multicastMethods.any((method) => _isUnavailable(methods[method]))) {
      explanations.add(
        'Bir veya daha fazla yerel servis keşfi kullanılamadı; mDNS, SSDP '
        'veya ONVIF duyurusu yapan cihazlar eksik olabilir.',
      );
    }
    if (multicastMethods.every(
      (method) => methods[method]?.phase == DiscoveryMethodPhase.skipped,
    )) {
      explanations.add(
        'Hızlı taramada yerel servis duyuruları çalıştırılmadı. Daha geniş '
        'kapsam için ayrıntılı tarama kullanılabilir.',
      );
    }
    if (noDevicesObserved || hasMissingDevices) {
      explanations.add(
        'Cihaz uyku modunda, güvenlik duvarı arkasında, misafir ağında veya '
        'istemci izolasyonu nedeniyle erişilemez durumda olabilir.',
      );
    }
    return List.unmodifiable(explanations.toSet());
  }

  bool _isUnavailable(DiscoveryMethodResult? result) =>
      result == null ||
      result.phase == DiscoveryMethodPhase.failed ||
      result.phase == DiscoveryMethodPhase.unavailable ||
      result.phase == DiscoveryMethodPhase.cancelled;
}
