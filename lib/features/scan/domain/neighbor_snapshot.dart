enum NeighborSnapshotUnavailableReason {
  androidRestricted,
  operatingSystemUnavailable,
}

class NeighborEntry {
  const NeighborEntry({required this.ipAddress, required this.macAddress});

  final String ipAddress;
  final String macAddress;
}

class NeighborSnapshot {
  const NeighborSnapshot({
    required this.available,
    required this.entries,
    this.unavailableReason,
  });

  const NeighborSnapshot.unavailable({
    this.unavailableReason =
        NeighborSnapshotUnavailableReason.operatingSystemUnavailable,
  }) : available = false,
       entries = const [];

  final bool available;
  final List<NeighborEntry> entries;
  final NeighborSnapshotUnavailableReason? unavailableReason;
}

abstract interface class NeighborRepository {
  Future<NeighborSnapshot> getSnapshot();
}
