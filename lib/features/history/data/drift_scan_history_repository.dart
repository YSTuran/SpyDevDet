import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:spy_dev_det/features/history/data/app_database.dart';
import 'package:spy_dev_det/features/history/domain/scan_history_repository.dart';
import 'package:spy_dev_det/features/network/domain/ipv4_address.dart';
import 'package:spy_dev_det/features/scan/domain/device_evidence.dart';
import 'package:spy_dev_det/features/scan/domain/device_identity_resolver.dart';
import 'package:spy_dev_det/features/scan/domain/device_observation.dart';
import 'package:spy_dev_det/features/scan/domain/scan_report.dart';
import 'package:spy_dev_det/features/scan/domain/scan_mode.dart';

class DriftScanHistoryRepository implements ScanHistoryRepository {
  const DriftScanHistoryRepository(
    this.database, {
    this.identityResolver = const DeviceIdentityResolver(),
  });

  final AppDatabase database;
  final DeviceIdentityResolver identityResolver;
  static const _weakIdentityReuseWindow = Duration(days: 7);
  static const _maxSessionsPerNetwork = 100;

  @override
  Future<List<DeviceObservation>> recordCompletedScan(
    CompletedScanRecord record,
  ) {
    return database.transaction(() async {
      final completedAt = record.report.completedAt ?? DateTime.now();
      final decoratedDevices = <DeviceObservation>[];
      final networkIdentityKeys = record.networkIdentityKeys.isEmpty
          ? [record.networkKey]
          : record.networkIdentityKeys;
      final networkKey = await _resolveNetworkKey(networkIdentityKeys);
      await _rememberNetworkIdentity(
        candidateKeys: networkIdentityKeys,
        networkKey: networkKey,
        observedAt: completedAt,
      );

      for (final device in record.devices) {
        final candidateKeys = identityResolver.candidateKeys(
          device,
          networkKey: networkKey,
        );
        final stableKey = await _resolveStableKey(
          candidateKeys,
          observedAt: completedAt,
        );
        final existing = await _knownDevice(stableKey);
        final isLocalDevice = candidateKeys.contains('local:this-installation');
        final familiarity =
            isLocalDevice ||
                existing?.isKnown == true ||
                existing?.isOwned == true
            ? DeviceFamiliarity.known
            : existing == null
            ? DeviceFamiliarity.newDevice
            : DeviceFamiliarity.seenBefore;
        final decorated = device.copyWith(
          stableKey: stableKey,
          customName: existing?.customName,
          note: existing?.note,
          categoryOverride:
              _enumByNameOrNull(
                DeviceCategory.values,
                existing?.categoryOverride,
              ) ??
              device.categoryOverride,
          isOwned: existing?.isOwned ?? device.isOwned,
          familiarity: familiarity,
          firstSeenAt: existing?.firstSeenAt ?? completedAt,
          lastSeenAt: completedAt,
        );
        decoratedDevices.add(decorated);

        await database
            .into(database.knownDevices)
            .insertOnConflictUpdate(
              KnownDevicesCompanion.insert(
                stableKey: stableKey,
                customName: Value(existing?.customName),
                isKnown: Value(existing?.isKnown ?? isLocalDevice),
                note: Value(existing?.note),
                firstSeenAt: existing?.firstSeenAt ?? completedAt,
                lastSeenAt: completedAt,
                lastIpAddress: device.ipAddress,
                lastMacAddress: Value(device.macAddress),
                vendor: Value(device.vendor),
                categoryOverride: Value(
                  existing?.categoryOverride ?? device.categoryOverride?.name,
                ),
                isOwned: Value(existing?.isOwned ?? device.isOwned),
              ),
            );
        await _rememberIdentityAliases(
          candidateKeys: candidateKeys,
          stableKey: stableKey,
          observedAt: completedAt,
        );
      }

      final newDeviceCount = decoratedDevices
          .where((device) => device.familiarity == DeviceFamiliarity.newDevice)
          .length;
      final missingDevices = record.report.canComparePresence
          ? await _missingSincePreviousComparableScan(
              networkKey: networkKey,
              currentKeys: decoratedDevices
                  .map((device) => device.stableKey!)
                  .toSet(),
            )
          : const <MissingDeviceSummary>[];
      final sessionId = await database
          .into(database.scanSessions)
          .insert(
            ScanSessionsCompanion.insert(
              networkKey: networkKey,
              startedAt: record.report.startedAt,
              completedAt: completedAt,
              outcome: record.report.isPartial ? 'partial' : 'completed',
              methodsJson: _encodeMethods(record.report.methods),
              totalDeviceCount: decoratedDevices.length,
              newDeviceCount: newDeviceCount,
              missingDeviceCount: missingDevices.length,
              missingDevicesJson: _encodeMissingDevices(missingDevices),
              presenceComparable: record.report.canComparePresence,
              elapsedMillis: record.elapsed.inMilliseconds,
              scanMode: Value(record.report.scanMode.name),
            ),
          );

      for (final device in decoratedDevices) {
        await database
            .into(database.scanObservations)
            .insert(
              ScanObservationsCompanion.insert(
                scanSessionId: sessionId,
                stableKey: device.stableKey!,
                ipAddress: device.ipAddress,
                displayName: device.displayName,
                macAddress: Value(device.macAddress),
                macStatus: device.macStatus.name,
                vendor: Value(device.vendor),
                category: device.category.name,
                confidence: device.confidence.name,
                discoveryMethod: device.discoveryMethod,
                servicesJson: jsonEncode(device.services),
                evidenceJson: _encodeEvidence(device.evidence),
                wasNew: device.familiarity == DeviceFamiliarity.newDevice,
              ),
            );
      }

      await _pruneOldSessions(networkKey);

      return List.unmodifiable(decoratedDevices);
    });
  }

  @override
  Future<void> updateDeviceProfile({
    required String stableKey,
    required bool isKnown,
    required String? customName,
    required String? note,
    bool? isOwned,
    DeviceCategory? categoryOverride,
    bool clearCategoryOverride = false,
  }) async {
    await (database.update(
      database.knownDevices,
    )..where((table) => table.stableKey.equals(stableKey))).write(
      KnownDevicesCompanion(
        customName: Value(_normalizeOptional(customName)),
        isKnown: Value(isKnown || isOwned == true),
        note: Value(_normalizeOptional(note)),
        isOwned: isOwned == null ? const Value.absent() : Value(isOwned),
        categoryOverride: clearCategoryOverride
            ? const Value(null)
            : categoryOverride == null
            ? const Value.absent()
            : Value(categoryOverride.name),
      ),
    );
  }

  @override
  Future<List<ScanHistorySummary>> getHistory({
    int limit = 50,
    String? networkKey,
  }) async {
    final query = database.select(database.scanSessions);
    if (networkKey != null) {
      query.where((table) => table.networkKey.equals(networkKey));
    }
    query
      ..orderBy([(table) => OrderingTerm.desc(table.completedAt)])
      ..limit(limit.clamp(1, 200));
    final rows = await query.get();
    return List.unmodifiable(rows.map(_summaryFromRow));
  }

  @override
  Future<List<NetworkProfileSummary>> getNetworkProfiles() async {
    final profiles = await (database.select(
      database.networkProfiles,
    )..orderBy([(table) => OrderingTerm.desc(table.lastSeenAt)])).get();
    final statistics = await database
        .customSelect(
          '''
      SELECT sessions.network_key,
             COUNT(*) AS scan_count,
             COALESCE((
               SELECT latest.total_device_count
               FROM scan_sessions AS latest
               WHERE latest.network_key = sessions.network_key
               ORDER BY latest.completed_at DESC, latest.id DESC
               LIMIT 1
             ), 0) AS last_device_count
      FROM scan_sessions AS sessions
      GROUP BY sessions.network_key
      ''',
          readsFrom: {database.scanSessions},
        )
        .get();
    final statisticsByNetwork = {
      for (final row in statistics)
        row.read<String>('network_key'): (
          scanCount: row.read<int>('scan_count'),
          lastDeviceCount: row.read<int>('last_device_count'),
        ),
    };
    return List.unmodifiable(
      profiles.map((profile) {
        final profileStatistics = statisticsByNetwork[profile.networkKey];
        return NetworkProfileSummary(
          networkKey: profile.networkKey,
          customName: profile.customName,
          firstSeenAt: profile.firstSeenAt,
          lastSeenAt: profile.lastSeenAt,
          scanCount: profileStatistics?.scanCount ?? 0,
          lastDeviceCount: profileStatistics?.lastDeviceCount ?? 0,
        );
      }),
    );
  }

  @override
  Future<void> renameNetworkProfile({
    required String networkKey,
    required String? customName,
  }) async {
    await (database.update(
      database.networkProfiles,
    )..where((table) => table.networkKey.equals(networkKey))).write(
      NetworkProfilesCompanion(
        customName: Value(_normalizeOptional(customName)),
      ),
    );
  }

  @override
  Future<ScanHistoryDetails?> getDetails(int sessionId) async {
    final session = await (database.select(
      database.scanSessions,
    )..where((table) => table.id.equals(sessionId))).getSingleOrNull();
    if (session == null) {
      return null;
    }
    final rows = await (database.select(
      database.scanObservations,
    )..where((table) => table.scanSessionId.equals(sessionId))).get();
    final profiles = await _knownDevices(
      rows.map((row) => row.stableKey).toSet(),
    );
    final devices = rows
        .map((row) => _observationFromRow(row, profiles[row.stableKey]))
        .toList();
    devices.sort(
      (first, second) => Ipv4Address.compare(first.ipAddress, second.ipAddress),
    );
    return ScanHistoryDetails(
      summary: _summaryFromRow(session),
      devices: List.unmodifiable(devices),
    );
  }

  @override
  Future<void> deleteSession(int sessionId) async {
    await (database.delete(
      database.scanSessions,
    )..where((table) => table.id.equals(sessionId))).go();
  }

  @override
  Future<void> clearHistory() async {
    await database.delete(database.scanSessions).go();
  }

  @override
  Future<void> clearAllData() {
    return database.transaction(() async {
      await database.delete(database.scanSessions).go();
      await database.delete(database.deviceIdentityAliases).go();
      await database.delete(database.knownDevices).go();
      await database.delete(database.networkIdentityAliases).go();
      await database.delete(database.networkProfiles).go();
    });
  }

  Future<String> _resolveNetworkKey(List<String> candidateKeys) async {
    final keys = candidateKeys.toSet().toList(growable: false);
    final strongKeys = keys.where(_isStrongNetworkKey).toList(growable: false);
    final weakKeys = keys
        .where((key) => !_isStrongNetworkKey(key))
        .toList(growable: false);

    for (final key in strongKeys) {
      final alias = await _networkIdentityAlias(key);
      if (alias != null && await _networkProfileExists(alias.networkKey)) {
        return alias.networkKey;
      }
      if (await _networkProfileExists(key)) {
        return key;
      }
    }

    for (final key in weakKeys) {
      final alias = await _networkIdentityAlias(key);
      if (alias != null && await _networkProfileExists(alias.networkKey)) {
        if (strongKeys.isEmpty ||
            !await _hasDifferentStrongNetworkAlias(
              alias.networkKey,
              strongKeys.toSet(),
            )) {
          return alias.networkKey;
        }
      }
      if (await _networkProfileExists(key) &&
          (strongKeys.isEmpty ||
              !await _hasDifferentStrongNetworkAlias(
                key,
                strongKeys.toSet(),
              ))) {
        return key;
      }
    }

    if (strongKeys.isEmpty) {
      for (final key in weakKeys) {
        final legacyStrongKey = await _legacyStrongNetworkKeyForBase(key);
        if (legacyStrongKey != null) {
          return legacyStrongKey;
        }
      }
    }

    return strongKeys.isNotEmpty ? strongKeys.first : keys.first;
  }

  Future<void> _rememberNetworkIdentity({
    required List<String> candidateKeys,
    required String networkKey,
    required DateTime observedAt,
  }) async {
    final existing = await _networkProfile(networkKey);
    await database
        .into(database.networkProfiles)
        .insertOnConflictUpdate(
          NetworkProfilesCompanion.insert(
            networkKey: networkKey,
            customName: Value(existing?.customName),
            firstSeenAt: existing?.firstSeenAt ?? observedAt,
            lastSeenAt: observedAt,
          ),
        );
    for (final aliasKey in candidateKeys.toSet()) {
      await database
          .into(database.networkIdentityAliases)
          .insertOnConflictUpdate(
            NetworkIdentityAliasesCompanion.insert(
              aliasKey: aliasKey,
              networkKey: networkKey,
              lastSeenAt: observedAt,
            ),
          );
    }
  }

  Future<NetworkProfile?> _networkProfile(String networkKey) {
    return (database.select(
      database.networkProfiles,
    )..where((table) => table.networkKey.equals(networkKey))).getSingleOrNull();
  }

  Future<NetworkIdentityAlias?> _networkIdentityAlias(String aliasKey) {
    return (database.select(
      database.networkIdentityAliases,
    )..where((table) => table.aliasKey.equals(aliasKey))).getSingleOrNull();
  }

  Future<bool> _networkProfileExists(String networkKey) async {
    if (await _networkProfile(networkKey) != null) {
      return true;
    }
    final existingSession =
        await (database.select(database.scanSessions)
              ..where((table) => table.networkKey.equals(networkKey))
              ..limit(1))
            .getSingleOrNull();
    return existingSession != null;
  }

  Future<bool> _hasDifferentStrongNetworkAlias(
    String networkKey,
    Set<String> currentStrongKeys,
  ) async {
    final aliases = await (database.select(
      database.networkIdentityAliases,
    )..where((table) => table.networkKey.equals(networkKey))).get();
    return aliases.any(
      (alias) =>
          _isStrongNetworkKey(alias.aliasKey) &&
          !currentStrongKeys.contains(alias.aliasKey),
    );
  }

  Future<String?> _legacyStrongNetworkKeyForBase(String baseKey) async {
    final sessions =
        await (database.select(database.scanSessions)
              ..where(
                (table) =>
                    table.networkKey.like('$baseKey|gateway-mac:%') |
                    table.networkKey.like('$baseKey|gateway-service:%'),
              )
              ..orderBy([(table) => OrderingTerm.desc(table.completedAt)]))
            .get();
    final matchingKeys = sessions.map((session) => session.networkKey).toSet();
    return matchingKeys.length == 1 ? matchingKeys.single : null;
  }

  bool _isStrongNetworkKey(String key) =>
      key.contains('|gateway-mac:') || key.contains('|gateway-service:');

  Future<String> _resolveStableKey(
    List<String> candidateKeys, {
    required DateTime observedAt,
  }) async {
    final strongKeys = candidateKeys.where((key) => !_isWeakKey(key)).toList();
    final weakKeys = candidateKeys.where(_isWeakKey).toList();
    var foundExpiredWeakIdentity = false;

    for (final key in strongKeys) {
      final alias = await _identityAlias(key);
      if (alias != null && await _knownDevice(alias.stableKey) != null) {
        return alias.stableKey;
      }
      if (await _knownDevice(key) != null) {
        return key;
      }
    }

    for (final key in weakKeys) {
      final alias = await _identityAlias(key);
      if (alias != null && await _knownDevice(alias.stableKey) != null) {
        if (_isRecent(alias.lastSeenAt, observedAt)) {
          if (strongKeys.isEmpty ||
              !await _hasDifferentStrongAlias(
                alias.stableKey,
                strongKeys.toSet(),
              )) {
            return alias.stableKey;
          }
        } else {
          foundExpiredWeakIdentity = true;
        }
      }
      final known = await _knownDevice(key);
      if (known != null) {
        if (_isRecent(known.lastSeenAt, observedAt)) {
          return key;
        }
        foundExpiredWeakIdentity = true;
      }
    }

    if (strongKeys.isNotEmpty) {
      return strongKeys.first;
    }
    if (foundExpiredWeakIdentity) {
      return '${candidateKeys.first}|first-seen:'
          '${observedAt.microsecondsSinceEpoch}';
    }
    return candidateKeys.first;
  }

  Future<void> _rememberIdentityAliases({
    required List<String> candidateKeys,
    required String stableKey,
    required DateTime observedAt,
  }) async {
    for (final aliasKey in candidateKeys) {
      await database
          .into(database.deviceIdentityAliases)
          .insertOnConflictUpdate(
            DeviceIdentityAliasesCompanion.insert(
              aliasKey: aliasKey,
              stableKey: stableKey,
              lastSeenAt: observedAt,
            ),
          );
    }
  }

  Future<DeviceIdentityAlias?> _identityAlias(String aliasKey) {
    return (database.select(
      database.deviceIdentityAliases,
    )..where((table) => table.aliasKey.equals(aliasKey))).getSingleOrNull();
  }

  Future<bool> _hasDifferentStrongAlias(
    String stableKey,
    Set<String> currentStrongKeys,
  ) async {
    final aliases = await (database.select(
      database.deviceIdentityAliases,
    )..where((table) => table.stableKey.equals(stableKey))).get();
    return aliases.any(
      (alias) =>
          !_isWeakKey(alias.aliasKey) &&
          !currentStrongKeys.contains(alias.aliasKey),
    );
  }

  bool _isWeakKey(String key) =>
      key.startsWith('network:') || key.startsWith('mdns:');

  bool _isRecent(DateTime lastSeenAt, DateTime observedAt) =>
      observedAt.difference(lastSeenAt) <= _weakIdentityReuseWindow;

  Future<KnownDevice?> _knownDevice(String stableKey) {
    return (database.select(
      database.knownDevices,
    )..where((table) => table.stableKey.equals(stableKey))).getSingleOrNull();
  }

  Future<Map<String, KnownDevice>> _knownDevices(Set<String> stableKeys) async {
    if (stableKeys.isEmpty) {
      return const {};
    }
    final profiles = await (database.select(
      database.knownDevices,
    )..where((table) => table.stableKey.isIn(stableKeys))).get();
    return {for (final profile in profiles) profile.stableKey: profile};
  }

  Future<void> _pruneOldSessions(String networkKey) async {
    final sessions =
        await (database.select(database.scanSessions)
              ..where((table) => table.networkKey.equals(networkKey))
              ..orderBy([
                (table) => OrderingTerm.desc(table.completedAt),
                (table) => OrderingTerm.desc(table.id),
              ]))
            .get();
    final oldSessions = sessions.skip(_maxSessionsPerNetwork).toList();
    if (oldSessions.isEmpty) {
      return;
    }
    await (database.delete(
      database.scanSessions,
    )..where((table) => table.id.isIn(oldSessions.map((row) => row.id)))).go();
  }

  ScanHistorySummary _summaryFromRow(ScanSession row) {
    return ScanHistorySummary(
      id: row.id,
      networkKey: row.networkKey,
      startedAt: row.startedAt,
      completedAt: row.completedAt,
      isPartial: row.outcome == 'partial',
      totalDeviceCount: row.totalDeviceCount,
      newDeviceCount: row.newDeviceCount,
      missingDevices: _decodeMissingDevices(row.missingDevicesJson),
      elapsed: Duration(milliseconds: row.elapsedMillis),
      methods: _decodeMethods(row.methodsJson),
      scanMode: _enumByName(ScanMode.values, row.scanMode, ScanMode.detailed),
    );
  }

  Future<List<MissingDeviceSummary>> _missingSincePreviousComparableScan({
    required String networkKey,
    required Set<String> currentKeys,
  }) async {
    final previousSession =
        await (database.select(database.scanSessions)
              ..where(
                (table) =>
                    table.networkKey.equals(networkKey) &
                    table.presenceComparable.equals(true),
              )
              ..orderBy([(table) => OrderingTerm.desc(table.completedAt)])
              ..limit(1))
            .getSingleOrNull();
    if (previousSession == null) {
      return const [];
    }
    final previousRows = await (database.select(
      database.scanObservations,
    )..where((table) => table.scanSessionId.equals(previousSession.id))).get();
    final profiles = await _knownDevices(
      previousRows.map((row) => row.stableKey).toSet(),
    );
    final missing = <MissingDeviceSummary>[];
    for (final row in previousRows) {
      if (currentKeys.contains(row.stableKey)) {
        continue;
      }
      final profile = profiles[row.stableKey];
      missing.add(
        MissingDeviceSummary(
          stableKey: row.stableKey,
          displayName: profile?.customName ?? row.displayName,
          lastIpAddress: row.ipAddress,
        ),
      );
    }
    return List.unmodifiable(missing);
  }

  DeviceObservation _observationFromRow(
    ScanObservation row,
    KnownDevice? profile,
  ) {
    return DeviceObservation(
      id: 'history-${row.id}',
      ipAddress: row.ipAddress,
      displayName: row.displayName,
      macAddress: row.macAddress,
      macStatus: _enumByName(
        MacStatus.values,
        row.macStatus,
        MacStatus.notObserved,
      ),
      vendor: row.vendor,
      services: _decodeStringList(row.servicesJson),
      discoveryMethod: row.discoveryMethod,
      evidence: _decodeEvidence(row.evidenceJson),
      category: _enumByName(
        DeviceCategory.values,
        row.category,
        DeviceCategory.unknown,
      ),
      categoryOverride: _enumByNameOrNull(
        DeviceCategory.values,
        profile?.categoryOverride,
      ),
      isOwned: profile?.isOwned ?? false,
      confidence: _enumByName(
        ConfidenceLevel.values,
        row.confidence,
        ConfidenceLevel.none,
      ),
      stableKey: row.stableKey,
      customName: profile?.customName,
      note: profile?.note,
      familiarity: profile?.isKnown == true
          ? DeviceFamiliarity.known
          : row.wasNew
          ? DeviceFamiliarity.newDevice
          : DeviceFamiliarity.seenBefore,
      firstSeenAt: profile?.firstSeenAt,
      lastSeenAt: profile?.lastSeenAt,
    );
  }

  String _encodeMethods(Map<DiscoveryMethod, DiscoveryMethodResult> methods) {
    return jsonEncode({
      for (final entry in methods.entries)
        entry.key.name: {
          'phase': entry.value.phase.name,
          'deviceCount': entry.value.deviceCount,
          'elapsedMillis': entry.value.elapsed.inMilliseconds,
          'userMessage': entry.value.userMessage,
          'metrics': {
            'attemptedTargets': entry.value.metrics.attemptedTargets,
            'sentRequests': entry.value.metrics.sentRequests,
            'receivedResponses': entry.value.metrics.receivedResponses,
            'acceptedResponses': entry.value.metrics.acceptedResponses,
            'ignoredResponses': entry.value.metrics.ignoredResponses,
            'timeoutCount': entry.value.metrics.timeoutCount,
            'multicastLockAcquired': entry.value.metrics.multicastLockAcquired,
            'detail': entry.value.metrics.detail,
          },
        },
    });
  }

  Map<DiscoveryMethod, DiscoveryMethodResult> _decodeMethods(String source) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map<String, dynamic>) {
        return const {};
      }
      final methods = <DiscoveryMethod, DiscoveryMethodResult>{};
      for (final method in DiscoveryMethod.values) {
        final value = decoded[method.name];
        if (value is! Map<String, dynamic>) {
          if (method == DiscoveryMethod.reachability ||
              method == DiscoveryMethod.onvif) {
            methods[method] = DiscoveryMethodResult(
              method: method,
              phase: DiscoveryMethodPhase.unavailable,
              userMessage: 'Bu yöntem eski uygulama sürümünde mevcut değildi.',
            );
          }
          continue;
        }
        methods[method] = DiscoveryMethodResult(
          method: method,
          phase: _enumByName(
            DiscoveryMethodPhase.values,
            value['phase'] as String?,
            DiscoveryMethodPhase.failed,
          ),
          deviceCount: value['deviceCount'] as int? ?? 0,
          elapsed: Duration(milliseconds: value['elapsedMillis'] as int? ?? 0),
          userMessage: value['userMessage'] as String?,
          metrics: _decodeMetrics(value['metrics']),
        );
      }
      return Map.unmodifiable(methods);
    } on FormatException {
      return const {};
    }
  }

  DiscoveryMetrics _decodeMetrics(Object? source) {
    if (source is! Map<String, dynamic>) {
      return const DiscoveryMetrics();
    }
    int readCount(String key) => (source[key] as num?)?.toInt() ?? 0;
    return DiscoveryMetrics(
      attemptedTargets: readCount('attemptedTargets'),
      sentRequests: readCount('sentRequests'),
      receivedResponses: readCount('receivedResponses'),
      acceptedResponses: readCount('acceptedResponses'),
      ignoredResponses: readCount('ignoredResponses'),
      timeoutCount: readCount('timeoutCount'),
      multicastLockAcquired: source['multicastLockAcquired'] as bool?,
      detail: source['detail'] as String?,
    );
  }

  String _encodeEvidence(List<DeviceEvidence> evidence) => jsonEncode(
    evidence
        .map(
          (item) => {
            'source': item.source.name,
            'description': item.description,
            'serviceType': item.serviceType,
            'port': item.port,
            'identifier': item.identifier,
          },
        )
        .toList(),
  );

  String _encodeMissingDevices(List<MissingDeviceSummary> devices) =>
      jsonEncode(
        devices
            .map(
              (device) => {
                'stableKey': device.stableKey,
                'displayName': device.displayName,
                'lastIpAddress': device.lastIpAddress,
              },
            )
            .toList(),
      );

  List<MissingDeviceSummary> _decodeMissingDevices(String source) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is! List) {
        return const [];
      }
      return List.unmodifiable(
        decoded.whereType<Map<String, dynamic>>().map(
          (item) => MissingDeviceSummary(
            stableKey: item['stableKey'] as String? ?? '',
            displayName: item['displayName'] as String? ?? 'Bilinmeyen cihaz',
            lastIpAddress: item['lastIpAddress'] as String? ?? 'Bilinmiyor',
          ),
        ),
      );
    } on FormatException {
      return const [];
    }
  }

  List<DeviceEvidence> _decodeEvidence(String source) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is! List) {
        return const [];
      }
      return List.unmodifiable(
        decoded.whereType<Map<String, dynamic>>().map(
          (item) => DeviceEvidence(
            source: _enumByName(
              DeviceEvidenceSource.values,
              item['source'] as String?,
              DeviceEvidenceSource.network,
            ),
            description: item['description'] as String? ?? 'Kayıtlı kanıt',
            serviceType: item['serviceType'] as String?,
            port: item['port'] as int?,
            identifier: item['identifier'] as String?,
          ),
        ),
      );
    } on FormatException {
      return const [];
    }
  }

  List<String> _decodeStringList(String source) {
    try {
      final decoded = jsonDecode(source);
      return decoded is List
          ? List.unmodifiable(decoded.whereType<String>())
          : const [];
    } on FormatException {
      return const [];
    }
  }

  T _enumByName<T extends Enum>(List<T> values, String? name, T fallback) {
    if (name == null) {
      return fallback;
    }
    for (final value in values) {
      if (value.name == name) {
        return value;
      }
    }
    return fallback;
  }

  T? _enumByNameOrNull<T extends Enum>(List<T> values, String? name) {
    if (name == null) {
      return null;
    }
    for (final value in values) {
      if (value.name == name) {
        return value;
      }
    }
    return null;
  }

  String? _normalizeOptional(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
