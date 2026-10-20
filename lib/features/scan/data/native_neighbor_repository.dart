import 'package:flutter/services.dart';
import 'package:spy_dev_det/features/scan/domain/neighbor_snapshot.dart';

class NativeNeighborRepository implements NeighborRepository {
  const NativeNeighborRepository();

  static const _channel = MethodChannel('yusufs.turan.spydevdet/network_info');

  @override
  Future<NeighborSnapshot> getSnapshot() async {
    try {
      final raw = await _channel.invokeMapMethod<String, dynamic>(
        'getNeighborSnapshot',
      );
      if (raw == null) {
        return const NeighborSnapshot.unavailable();
      }
      final entries = <NeighborEntry>[];
      final rawEntries = raw['entries'];
      if (rawEntries is List) {
        for (final item in rawEntries) {
          if (item is! Map) {
            continue;
          }
          final ipAddress = item['ipAddress'];
          final macAddress = item['macAddress'];
          if (ipAddress is String && macAddress is String) {
            entries.add(
              NeighborEntry(ipAddress: ipAddress, macAddress: macAddress),
            );
          }
        }
      }
      return NeighborSnapshot(
        available: raw['available'] == true,
        entries: List.unmodifiable(entries),
        unavailableReason: switch (raw['unavailableReason']) {
          'androidRestricted' =>
            NeighborSnapshotUnavailableReason.androidRestricted,
          _ when raw['available'] != true =>
            NeighborSnapshotUnavailableReason.operatingSystemUnavailable,
          _ => null,
        },
      );
    } on PlatformException {
      return const NeighborSnapshot.unavailable();
    } on MissingPluginException {
      return const NeighborSnapshot.unavailable();
    }
  }
}
