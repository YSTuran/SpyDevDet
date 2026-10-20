import 'package:spy_dev_det/features/network/domain/ipv4_address.dart';
import 'package:spy_dev_det/features/scan/domain/device_attention.dart';
import 'package:spy_dev_det/features/scan/domain/device_evidence.dart';
import 'package:spy_dev_det/features/scan/domain/device_observation.dart';

enum DeviceFilterOption {
  all,
  newDevices,
  known,
  seenBefore,
  cameraCandidates,
  reviewRecommended,
  knownVendor,
  macAvailable,
}

extension DeviceFilterOptionText on DeviceFilterOption {
  String get label => switch (this) {
    DeviceFilterOption.all => 'Tümü',
    DeviceFilterOption.newDevices => 'Yeni',
    DeviceFilterOption.known => 'Bilinen',
    DeviceFilterOption.seenBefore => 'Daha önce görülen',
    DeviceFilterOption.cameraCandidates => 'Kamera adayı',
    DeviceFilterOption.reviewRecommended => 'İncelenecek',
    DeviceFilterOption.knownVendor => 'Üreticisi bilinen',
    DeviceFilterOption.macAvailable => 'MAC bulunan',
  };
}

enum DeviceSortOption { ipAddress, attention, newDevices, name, category }

extension DeviceSortOptionText on DeviceSortOption {
  String get label => switch (this) {
    DeviceSortOption.ipAddress => 'IP adresi',
    DeviceSortOption.attention => 'İnceleme önceliği',
    DeviceSortOption.newDevices => 'Yeni cihazlar',
    DeviceSortOption.name => 'Cihaz adı',
    DeviceSortOption.category => 'Kategori',
  };
}

class DeviceListFilter {
  const DeviceListFilter();

  List<DeviceObservation> apply(
    List<DeviceObservation> devices, {
    String query = '',
    DeviceFilterOption filter = DeviceFilterOption.all,
    DeviceSortOption sort = DeviceSortOption.ipAddress,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    final filtered = devices
        .where((device) {
          if (normalizedQuery.isNotEmpty &&
              !_searchableText(device).contains(normalizedQuery)) {
            return false;
          }
          return _matchesFilter(device, filter);
        })
        .toList(growable: true);
    filtered.sort((first, second) => _compare(first, second, sort));
    return List.unmodifiable(filtered);
  }

  bool _matchesFilter(DeviceObservation device, DeviceFilterOption filter) =>
      switch (filter) {
        DeviceFilterOption.all => true,
        DeviceFilterOption.newDevices =>
          device.familiarity == DeviceFamiliarity.newDevice,
        DeviceFilterOption.known => device.isKnown,
        DeviceFilterOption.seenBefore =>
          device.familiarity == DeviceFamiliarity.seenBefore,
        DeviceFilterOption.cameraCandidates =>
          device.effectiveCategory == DeviceCategory.cameraCandidate,
        DeviceFilterOption.reviewRecommended =>
          const DeviceAttentionEvaluator().evaluate(device).level ==
              AttentionLevel.review,
        DeviceFilterOption.knownVendor => device.hasKnownVendor,
        DeviceFilterOption.macAvailable =>
          device.macStatus == MacStatus.available,
      };

  int _compare(
    DeviceObservation first,
    DeviceObservation second,
    DeviceSortOption sort,
  ) {
    final comparison = switch (sort) {
      DeviceSortOption.ipAddress => Ipv4Address.compare(
        first.ipAddress,
        second.ipAddress,
      ),
      DeviceSortOption.attention =>
        const DeviceAttentionEvaluator()
            .evaluate(second)
            .score
            .compareTo(const DeviceAttentionEvaluator().evaluate(first).score),
      DeviceSortOption.newDevices => _familiarityRank(
        first,
      ).compareTo(_familiarityRank(second)),
      DeviceSortOption.name =>
        first.effectiveDisplayName.toLowerCase().compareTo(
          second.effectiveDisplayName.toLowerCase(),
        ),
      DeviceSortOption.category => first.effectiveCategory.label.compareTo(
        second.effectiveCategory.label,
      ),
    };
    return comparison == 0
        ? Ipv4Address.compare(first.ipAddress, second.ipAddress)
        : comparison;
  }

  int _familiarityRank(DeviceObservation device) =>
      switch (device.familiarity) {
        DeviceFamiliarity.newDevice => 0,
        DeviceFamiliarity.seenBefore => 1,
        DeviceFamiliarity.known => 2,
        DeviceFamiliarity.unclassified => 3,
      };

  String _searchableText(DeviceObservation device) => [
    device.ipAddress,
    device.displayName,
    device.customName,
    device.vendor,
    device.macAddress,
    device.note,
    device.effectiveCategory.label,
    ...device.services,
  ].whereType<String>().join(' ').toLowerCase();
}
