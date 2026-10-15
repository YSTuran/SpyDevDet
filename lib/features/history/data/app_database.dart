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

  @override
  Set<Column<Object>> get primaryKey => {stableKey};
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

@DriftDatabase(tables: [KnownDevices, ScanSessions, ScanObservations])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'spydevdet_history'));

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
