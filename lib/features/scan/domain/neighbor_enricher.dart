import 'package:spy_dev_det/features/scan/domain/device_evidence.dart';
import 'package:spy_dev_det/features/scan/domain/device_observation.dart';
import 'package:spy_dev_det/features/scan/domain/mac_address.dart';
import 'package:spy_dev_det/features/scan/domain/neighbor_snapshot.dart';

class NeighborEnricher {
  const NeighborEnricher({
    this.vendorRepository = const AssetMacVendorRepository(),
  });

  final MacVendorLookup vendorRepository;

  Future<MacVendorDatabaseStatus> prepare() => vendorRepository.load();

  DeviceObservation enrich(
    DeviceObservation device,
    NeighborSnapshot snapshot,
  ) {
    if (!snapshot.available) {
      return device.copyWith(
        macStatus:
            snapshot.unavailableReason ==
                NeighborSnapshotUnavailableReason.androidRestricted
            ? MacStatus.platformRestricted
            : MacStatus.restrictedOrUnavailable,
      );
    }

    NeighborEntry? entry;
    for (final candidate in snapshot.entries) {
      if (candidate.ipAddress == device.ipAddress) {
        entry = candidate;
        break;
      }
    }
    if (entry == null) {
      return device.copyWith(macStatus: MacStatus.notObserved);
    }

    final macAddress = MacAddress.tryParse(entry.macAddress);
    if (macAddress == null) {
      return device.copyWith(
        macStatus: MacStatus.invalid,
        clearMacAddress: true,
        clearVendor: true,
      );
    }

    final evidence = [
      ...device.evidence,
      DeviceEvidence(
        source: DeviceEvidenceSource.neighbor,
        description: macAddress.isLocallyAdministered
            ? 'Yerel/özelleştirilmiş MAC adresi komşu tablosunda görüldü'
            : 'MAC adresi komşu tablosunda görüldü',
      ),
    ];
    return device.copyWith(
      macAddress: macAddress.value,
      macStatus: MacStatus.available,
      vendor: vendorRepository.lookup(macAddress),
      clearVendor: macAddress.isLocallyAdministered,
      evidence: List.unmodifiable(evidence),
    );
  }
}
