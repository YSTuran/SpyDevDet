class NeighborEntry {
  const NeighborEntry({required this.ipAddress, required this.macAddress});

  final String ipAddress;
  final String macAddress;
}

class NeighborSnapshot {
  const NeighborSnapshot({required this.available, required this.entries});

  const NeighborSnapshot.unavailable() : available = false, entries = const [];

  final bool available;
  final List<NeighborEntry> entries;
}

abstract interface class NeighborRepository {
  Future<NeighborSnapshot> getSnapshot();
}
