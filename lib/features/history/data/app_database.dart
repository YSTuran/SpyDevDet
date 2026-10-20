import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class KnownDevices extends Table {
  TextColumn get stableKey => text()();
  TextColumn get customName => text().nullable()();
  BoolColumn get isKnown => boolean().withDefault(const Constant(false))();
  TextColumn get note => text().nullable()();
  DateTimeColumn get firstSeenAt => dateTime()();
  DateTimeColumn get lastSeenAt => dateTime()();
  TextColumn get lastIpAddress => text()();
  TextColumn get lastMacAddress => text().nullable()();
  TextColumn get vendor => text().nullable()();
  TextColumn get categoryOverride => text().nullable()();
  BoolColumn get isOwned => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {stableKey};
}

@DataClassName('DeviceIdentityAlias')
class DeviceIdentityAliases extends Table {
  TextColumn get aliasKey => text()();
  TextColumn get stableKey => text().references(
    KnownDevices,
    #stableKey,
    onDelete: KeyAction.cascade,
  )();
  DateTimeColumn get lastSeenAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {aliasKey};
}

class NetworkProfiles extends Table {
  TextColumn get networkKey => text()();
  TextColumn get customName => text().nullable()();
  DateTimeColumn get firstSeenAt => dateTime()();
  DateTimeColumn get lastSeenAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {networkKey};
}

@DataClassName('NetworkIdentityAlias')
class NetworkIdentityAliases extends Table {
  TextColumn get aliasKey => text()();
  TextColumn get networkKey => text().references(
    NetworkProfiles,
    #networkKey,
    onDelete: KeyAction.cascade,
  )();
  DateTimeColumn get lastSeenAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {aliasKey};
}

class ScanSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get networkKey => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime()();
  TextColumn get outcome => text()();
  TextColumn get methodsJson => text()();
  IntColumn get totalDeviceCount => integer()();
  IntColumn get newDeviceCount => integer()();
  IntColumn get missingDeviceCount => integer()();
  TextColumn get missingDevicesJson => text()();
  BoolColumn get presenceComparable => boolean()();
  IntColumn get elapsedMillis => integer()();
  TextColumn get scanMode => text().withDefault(const Constant('detailed'))();
}

class ScanObservations extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get scanSessionId =>
      integer().references(ScanSessions, #id, onDelete: KeyAction.cascade)();
  TextColumn get stableKey => text()();
  TextColumn get ipAddress => text()();
  TextColumn get displayName => text()();
  TextColumn get macAddress => text().nullable()();
  TextColumn get macStatus => text()();
  TextColumn get vendor => text().nullable()();
  TextColumn get category => text()();
  TextColumn get confidence => text()();
  TextColumn get discoveryMethod => text()();
  TextColumn get servicesJson => text()();
  TextColumn get evidenceJson => text()();
  BoolColumn get wasNew => boolean()();
}

@DriftDatabase(
  tables: [
    KnownDevices,
    DeviceIdentityAliases,
    NetworkProfiles,
    NetworkIdentityAliases,
    ScanSessions,
    ScanObservations,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'spydevdet_history'));

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(deviceIdentityAliases);
      }
      if (from < 3) {
        await migrator.createTable(networkProfiles);
        await migrator.createTable(networkIdentityAliases);
      }
      if (from < 4) {
        await migrator.addColumn(knownDevices, knownDevices.categoryOverride);
        await migrator.addColumn(knownDevices, knownDevices.isOwned);
        if (from >= 3) {
          await migrator.addColumn(networkProfiles, networkProfiles.customName);
        }
        await migrator.addColumn(scanSessions, scanSessions.scanMode);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_scan_sessions_network_completed '
        'ON scan_sessions (network_key, completed_at DESC)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_scan_sessions_comparable '
        'ON scan_sessions (network_key, presence_comparable, completed_at DESC)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_scan_observations_session '
        'ON scan_observations (scan_session_id)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_device_aliases_stable '
        'ON device_identity_aliases (stable_key)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_network_aliases_network '
        'ON network_identity_aliases (network_key)',
      );
    },
  );
}
