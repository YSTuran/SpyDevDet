import 'package:spy_dev_det/features/scan/domain/device_evidence.dart';
import 'package:spy_dev_det/features/scan/domain/device_observation.dart';
import 'package:spy_dev_det/features/scan/domain/mac_address.dart';

enum ReferenceComparisonState {
  available,
  currentIsReference,
  notComparable,
  noBaseline,
}

enum ObservedIdentityQuality { weak, networkScoped, strong }

extension ObservedIdentityQualityText on ObservedIdentityQuality {
  String get label => switch (this) {
    ObservedIdentityQuality.weak => 'IP tabanlı',
    ObservedIdentityQuality.networkScoped => 'Ağ kapsamlı servis kimliği',
    ObservedIdentityQuality.strong => 'Güçlü cihaz kimliği',
  };
}

class ComparedDeviceSummary {
  const ComparedDeviceSummary({
    required this.stableKey,
    required this.displayName,
    required this.ipAddress,
    required this.category,
    this.vendor,
  });

  factory ComparedDeviceSummary.fromObservation(DeviceObservation device) =>
      ComparedDeviceSummary(
        stableKey: device.stableKey ?? device.id,
        displayName: device.effectiveDisplayName,
        ipAddress: device.ipAddress,
        category: device.category,
        vendor: device.vendor,
      );

  final String stableKey;
  final String displayName;
  final String ipAddress;
  final DeviceCategory category;
  final String? vendor;
}

class ReferenceDeviceChange {
  const ReferenceDeviceChange({
    required this.device,
    required this.previousIpAddress,
    required this.currentIpAddress,
    required this.addedServices,
    required this.removedServices,
    required this.previousVendor,
    required this.currentVendor,
    required this.previousCategory,
    required this.currentCategory,
    required this.previousConfidence,
    required this.currentConfidence,
    required this.previousIdentityQuality,
    required this.currentIdentityQuality,
  });

  final ComparedDeviceSummary device;
  final String previousIpAddress;
  final String currentIpAddress;
  final List<String> addedServices;
  final List<String> removedServices;
  final String? previousVendor;
  final String? currentVendor;
  final DeviceCategory previousCategory;
  final DeviceCategory currentCategory;
  final ConfidenceLevel previousConfidence;
  final ConfidenceLevel currentConfidence;
  final ObservedIdentityQuality previousIdentityQuality;
  final ObservedIdentityQuality currentIdentityQuality;

  bool get ipChanged => previousIpAddress != currentIpAddress;
  bool get servicesChanged =>
      addedServices.isNotEmpty || removedServices.isNotEmpty;
  bool get vendorChanged =>
      _normalized(previousVendor) != _normalized(currentVendor);
  bool get categoryChanged => previousCategory != currentCategory;
  bool get confidenceChanged => previousConfidence != currentConfidence;
  bool get identityQualityChanged =>
      previousIdentityQuality != currentIdentityQuality;
  bool get identityQualityDegraded =>
      currentIdentityQuality.index < previousIdentityQuality.index;

  static String _normalized(String? value) => value?.trim().toLowerCase() ?? '';
}

class ReferenceScanComparison {
  const ReferenceScanComparison._({
    required this.state,
    this.baselineSessionId,
    this.baselineCompletedAt,
    this.usesExplicitReference = false,
    this.addedDevices = const [],
    this.missingDevices = const [],
    this.changedDevices = const [],
  });

  const ReferenceScanComparison.currentIsReference()
    : this._(state: ReferenceComparisonState.currentIsReference);

  const ReferenceScanComparison.notComparable()
    : this._(state: ReferenceComparisonState.notComparable);

  const ReferenceScanComparison.noBaseline()
    : this._(state: ReferenceComparisonState.noBaseline);

  const ReferenceScanComparison.available({
    required int baselineSessionId,
    required DateTime baselineCompletedAt,
    required bool usesExplicitReference,
    required List<ComparedDeviceSummary> addedDevices,
    required List<ComparedDeviceSummary> missingDevices,
    required List<ReferenceDeviceChange> changedDevices,
  }) : this._(
         state: ReferenceComparisonState.available,
         baselineSessionId: baselineSessionId,
         baselineCompletedAt: baselineCompletedAt,
         usesExplicitReference: usesExplicitReference,
         addedDevices: addedDevices,
         missingDevices: missingDevices,
         changedDevices: changedDevices,
       );

  final ReferenceComparisonState state;
  final int? baselineSessionId;
  final DateTime? baselineCompletedAt;
  final bool usesExplicitReference;
  final List<ComparedDeviceSummary> addedDevices;
  final List<ComparedDeviceSummary> missingDevices;
  final List<ReferenceDeviceChange> changedDevices;

  bool get hasChanges =>
      addedDevices.isNotEmpty ||
      missingDevices.isNotEmpty ||
      changedDevices.isNotEmpty;
}

class ReferenceScanComparator {
  const ReferenceScanComparator();

  ReferenceScanComparison compare({
    required int baselineSessionId,
    required DateTime baselineCompletedAt,
    required bool usesExplicitReference,
    required List<DeviceObservation> baselineDevices,
    required List<DeviceObservation> currentDevices,
  }) {
    final baselineByKey = _byStableKey(baselineDevices);
    final currentByKey = _byStableKey(currentDevices);

    final added =
        currentByKey.keys
            .where((key) => !baselineByKey.containsKey(key))
            .map(
              (key) =>
                  ComparedDeviceSummary.fromObservation(currentByKey[key]!),
            )
            .toList()
          ..sort(_compareDevice);
    final missing =
        baselineByKey.keys
            .where((key) => !currentByKey.containsKey(key))
            .map(
              (key) =>
                  ComparedDeviceSummary.fromObservation(baselineByKey[key]!),
            )
            .toList()
          ..sort(_compareDevice);

    final changed = <ReferenceDeviceChange>[];
    for (final key in baselineByKey.keys.where(currentByKey.containsKey)) {
      final previous = baselineByKey[key]!;
      final current = currentByKey[key]!;
      final previousServices = previous.services.toSet();
      final currentServices = current.services.toSet();
      final change = ReferenceDeviceChange(
        device: ComparedDeviceSummary.fromObservation(current),
        previousIpAddress: previous.ipAddress,
        currentIpAddress: current.ipAddress,
        addedServices: _sorted(currentServices.difference(previousServices)),
        removedServices: _sorted(previousServices.difference(currentServices)),
        previousVendor: previous.vendor,
        currentVendor: current.vendor,
        previousCategory: previous.category,
        currentCategory: current.category,
        previousConfidence: previous.confidence,
        currentConfidence: current.confidence,
        previousIdentityQuality: identityQuality(previous),
        currentIdentityQuality: identityQuality(current),
      );
      if (change.ipChanged ||
          change.servicesChanged ||
          change.vendorChanged ||
          change.categoryChanged ||
          change.confidenceChanged ||
          change.identityQualityChanged) {
        changed.add(change);
      }
    }
    changed.sort(
      (first, second) => _compareDevice(first.device, second.device),
    );

    return ReferenceScanComparison.available(
      baselineSessionId: baselineSessionId,
      baselineCompletedAt: baselineCompletedAt,
      usesExplicitReference: usesExplicitReference,
      addedDevices: List.unmodifiable(added),
      missingDevices: List.unmodifiable(missing),
      changedDevices: List.unmodifiable(changed),
    );
  }

  ObservedIdentityQuality identityQuality(DeviceObservation device) {
    final mac = device.macAddress == null
        ? null
        : MacAddress.tryParse(device.macAddress!);
    if (mac != null && !mac.isLocallyAdministered) {
      return ObservedIdentityQuality.strong;
    }
    if (_hasIdentifier(device, DeviceEvidenceSource.onvif) ||
        _hasIdentifier(device, DeviceEvidenceSource.ssdp)) {
      return ObservedIdentityQuality.strong;
    }
    if (_hasIdentifier(device, DeviceEvidenceSource.mdns)) {
      return ObservedIdentityQuality.networkScoped;
    }
    return ObservedIdentityQuality.weak;
  }

  Map<String, DeviceObservation> _byStableKey(
    List<DeviceObservation> devices,
  ) => {for (final device in devices) device.stableKey ?? device.id: device};

  bool _hasIdentifier(DeviceObservation device, DeviceEvidenceSource source) =>
      device.evidence.any(
        (item) =>
            item.source == source && item.identifier?.trim().isNotEmpty == true,
      );

  List<String> _sorted(Set<String> values) => values.toList()..sort();

  int _compareDevice(
    ComparedDeviceSummary first,
    ComparedDeviceSummary second,
  ) => first.displayName.toLowerCase().compareTo(
    second.displayName.toLowerCase(),
  );
}
