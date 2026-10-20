import 'package:spy_dev_det/features/scan/domain/device_evidence.dart';

enum MacStatus { available, notObserved, restrictedOrUnavailable, invalid }

enum DeviceFamiliarity { unclassified, newDevice, seenBefore, known }

extension DeviceFamiliarityText on DeviceFamiliarity {
  String get label => switch (this) {
    DeviceFamiliarity.unclassified => 'Henüz karşılaştırılmadı',
    DeviceFamiliarity.newDevice => 'Yeni cihaz',
    DeviceFamiliarity.seenBefore => 'Daha önce görüldü',
    DeviceFamiliarity.known => 'Bilinen cihaz',
  };
}

extension MacStatusText on MacStatus {
  String get label => switch (this) {
    MacStatus.available => 'MAC adresi bulundu',
    MacStatus.notObserved => 'MAC adresi bu taramada gözlemlenmedi',
    MacStatus.restrictedOrUnavailable =>
      'MAC adresi ağ veya Android kısıtı nedeniyle edinilemedi',
    MacStatus.invalid => 'Geçersiz MAC adresi kullanılmadı',
  };
}

class DeviceObservation {
  const DeviceObservation({
    required this.id,
    required this.ipAddress,
    required this.displayName,
    required this.macStatus,
    required this.services,
    this.discoveryMethod = 'Bilinmiyor',
    this.macAddress,
    this.vendor,
    this.evidence = const [],
    this.category = DeviceCategory.unknown,
    this.categoryOverride,
    this.isOwned = false,
    this.confidence = ConfidenceLevel.none,
    this.stableKey,
    this.customName,
    this.note,
    this.familiarity = DeviceFamiliarity.unclassified,
    this.firstSeenAt,
    this.lastSeenAt,
  });

  final String id;
  final String ipAddress;
  final String displayName;
  final String? macAddress;
  final MacStatus macStatus;
  final String? vendor;
  final List<String> services;
  final String discoveryMethod;
  final List<DeviceEvidence> evidence;
  final DeviceCategory category;
  final DeviceCategory? categoryOverride;
  final bool isOwned;
  final ConfidenceLevel confidence;
  final String? stableKey;
  final String? customName;
  final String? note;
  final DeviceFamiliarity familiarity;
  final DateTime? firstSeenAt;
  final DateTime? lastSeenAt;

  bool get hasKnownVendor => vendor != null && vendor!.trim().isNotEmpty;
  bool get isKnown => familiarity == DeviceFamiliarity.known;
  DeviceCategory get effectiveCategory => categoryOverride ?? category;
  String get effectiveDisplayName =>
      customName?.trim().isNotEmpty == true ? customName!.trim() : displayName;

  DeviceObservation copyWith({
    String? id,
    String? displayName,
    String? macAddress,
    bool clearMacAddress = false,
    MacStatus? macStatus,
    String? vendor,
    bool clearVendor = false,
    List<String>? services,
    String? discoveryMethod,
    List<DeviceEvidence>? evidence,
    DeviceCategory? category,
    DeviceCategory? categoryOverride,
    bool clearCategoryOverride = false,
    bool? isOwned,
    ConfidenceLevel? confidence,
    String? stableKey,
    String? customName,
    bool clearCustomName = false,
    String? note,
    bool clearNote = false,
    DeviceFamiliarity? familiarity,
    DateTime? firstSeenAt,
    DateTime? lastSeenAt,
  }) {
    return DeviceObservation(
      id: id ?? this.id,
      ipAddress: ipAddress,
      displayName: displayName ?? this.displayName,
      macAddress: clearMacAddress ? null : (macAddress ?? this.macAddress),
      macStatus: macStatus ?? this.macStatus,
      vendor: clearVendor ? null : (vendor ?? this.vendor),
      services: services ?? this.services,
      discoveryMethod: discoveryMethod ?? this.discoveryMethod,
      evidence: evidence ?? this.evidence,
      category: category ?? this.category,
      categoryOverride: clearCategoryOverride
          ? null
          : (categoryOverride ?? this.categoryOverride),
      isOwned: isOwned ?? this.isOwned,
      confidence: confidence ?? this.confidence,
      stableKey: stableKey ?? this.stableKey,
      customName: clearCustomName ? null : (customName ?? this.customName),
      note: clearNote ? null : (note ?? this.note),
      familiarity: familiarity ?? this.familiarity,
      firstSeenAt: firstSeenAt ?? this.firstSeenAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }
}
