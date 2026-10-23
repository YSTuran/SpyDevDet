import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spy_dev_det/features/history/data/app_database.dart';

void main() {
  for (final legacyVersion in [1, 2, 3, 4]) {
    test(
      'şema $legacyVersion verilerini koruyarak güncel şemaya yükselir',
      () async {
        final executor = NativeDatabase.memory(
          setup: (database) => _createLegacySchema(database, legacyVersion),
        );
        final database = AppDatabase.forTesting(executor);
        addTearDown(database.close);

        final known = await database.select(database.knownDevices).getSingle();
        final session = await database
            .select(database.scanSessions)
            .getSingle();
        final tables = await _objectNames(database, 'table');
        final indexes = await _objectNames(database, 'index');

        expect(known.customName, 'Eski cihaz');
        expect(
          known.categoryOverride,
          legacyVersion >= 4 ? 'cameraCandidate' : isNull,
        );
        expect(known.isOwned, legacyVersion >= 4);
        expect(session.scanMode, legacyVersion >= 4 ? 'quick' : 'detailed');
        expect(session.isReference, isFalse);
        expect(
          tables,
          containsAll(const [
            'known_devices',
            'device_identity_aliases',
            'network_profiles',
            'network_identity_aliases',
            'scan_sessions',
            'scan_observations',
          ]),
        );
        expect(
          await _columnNames(database, 'known_devices'),
          containsAll(const ['category_override', 'is_owned']),
        );
        expect(
          await _columnNames(database, 'network_profiles'),
          contains('custom_name'),
        );
        expect(
          await _columnNames(database, 'scan_sessions'),
          containsAll(const ['scan_mode', 'is_reference']),
        );
        expect(indexes, contains('idx_scan_sessions_reference'));
        final foreignKeys = await database
            .customSelect('PRAGMA foreign_keys')
            .getSingle();
        expect(foreignKeys.read<int>('foreign_keys'), 1);

        if (legacyVersion >= 2) {
          final alias = await database
              .select(database.deviceIdentityAliases)
              .getSingle();
          expect(alias.stableKey, known.stableKey);
        }
        if (legacyVersion >= 3) {
          final profile = await database
              .select(database.networkProfiles)
              .getSingle();
          expect(profile.customName, legacyVersion >= 4 ? 'Ev ağı' : isNull);
        }
      },
    );
  }
}

void _createLegacySchema(dynamic database, int version) {
  final knownVersion4Columns = version >= 4
      ? ', category_override TEXT NULL, '
            'is_owned INTEGER NOT NULL DEFAULT 0'
      : '';
  final sessionVersion4Columns = version >= 4
      ? ", scan_mode TEXT NOT NULL DEFAULT 'detailed'"
      : '';
  final networkVersion4Column = version >= 4 ? 'custom_name TEXT NULL,' : '';

  database
    ..execute('''
      CREATE TABLE known_devices (
        stable_key TEXT NOT NULL PRIMARY KEY,
        custom_name TEXT NULL,
        is_known INTEGER NOT NULL DEFAULT 0,
        note TEXT NULL,
        first_seen_at INTEGER NOT NULL,
        last_seen_at INTEGER NOT NULL,
        last_ip_address TEXT NOT NULL,
        last_mac_address TEXT NULL,
        vendor TEXT NULL
        $knownVersion4Columns
      )
    ''')
    ..execute('''
      CREATE TABLE scan_sessions (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        network_key TEXT NOT NULL,
        started_at INTEGER NOT NULL,
        completed_at INTEGER NOT NULL,
        outcome TEXT NOT NULL,
        methods_json TEXT NOT NULL,
        total_device_count INTEGER NOT NULL,
        new_device_count INTEGER NOT NULL,
        missing_device_count INTEGER NOT NULL,
        missing_devices_json TEXT NOT NULL,
        presence_comparable INTEGER NOT NULL,
        elapsed_millis INTEGER NOT NULL
        $sessionVersion4Columns
      )
    ''')
    ..execute('''
      CREATE TABLE scan_observations (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        scan_session_id INTEGER NOT NULL REFERENCES scan_sessions(id)
          ON DELETE CASCADE,
        stable_key TEXT NOT NULL,
        ip_address TEXT NOT NULL,
        display_name TEXT NOT NULL,
        mac_address TEXT NULL,
        mac_status TEXT NOT NULL,
        vendor TEXT NULL,
        category TEXT NOT NULL,
        confidence TEXT NOT NULL,
        discovery_method TEXT NOT NULL,
        services_json TEXT NOT NULL,
        evidence_json TEXT NOT NULL,
        was_new INTEGER NOT NULL
      )
    ''');

  if (version >= 2) {
    database.execute('''
      CREATE TABLE device_identity_aliases (
        alias_key TEXT NOT NULL PRIMARY KEY,
        stable_key TEXT NOT NULL REFERENCES known_devices(stable_key)
          ON DELETE CASCADE,
        last_seen_at INTEGER NOT NULL
      )
    ''');
  }
  if (version >= 3) {
    database
      ..execute('''
        CREATE TABLE network_profiles (
          network_key TEXT NOT NULL PRIMARY KEY,
          $networkVersion4Column
          first_seen_at INTEGER NOT NULL,
          last_seen_at INTEGER NOT NULL
        )
      ''')
      ..execute('''
        CREATE TABLE network_identity_aliases (
          alias_key TEXT NOT NULL PRIMARY KEY,
          network_key TEXT NOT NULL REFERENCES network_profiles(network_key)
            ON DELETE CASCADE,
          last_seen_at INTEGER NOT NULL
        )
      ''');
  }

  if (version >= 4) {
    database.execute('''
      INSERT INTO known_devices (
        stable_key, custom_name, is_known, note, first_seen_at, last_seen_at,
        last_ip_address, last_mac_address, vendor, category_override, is_owned
      ) VALUES (
        'mac:B8:27:EB:12:34:56', 'Eski cihaz', 1, NULL, 1, 2,
        '192.168.1.20', 'B8:27:EB:12:34:56', 'Üretici', 'cameraCandidate', 1
      )
    ''');
  } else {
    database.execute('''
      INSERT INTO known_devices VALUES (
        'mac:B8:27:EB:12:34:56', 'Eski cihaz', 1, NULL,
        1, 2, '192.168.1.20', 'B8:27:EB:12:34:56', 'Üretici'
      )
    ''');
  }

  if (version >= 2) {
    database.execute('''
      INSERT INTO device_identity_aliases VALUES (
        'ip:192.168.1.20', 'mac:B8:27:EB:12:34:56', 2
      )
    ''');
  }
  if (version >= 3) {
    if (version >= 4) {
      database.execute('''
        INSERT INTO network_profiles VALUES (
          '192.168.1.0/24|gateway:192.168.1.1', 'Ev ağı', 1, 2
        )
      ''');
    } else {
      database.execute('''
        INSERT INTO network_profiles VALUES (
          '192.168.1.0/24|gateway:192.168.1.1', 1, 2
        )
      ''');
    }
  }

  if (version >= 4) {
    database.execute('''
      INSERT INTO scan_sessions (
        id, network_key, started_at, completed_at, outcome, methods_json,
        total_device_count, new_device_count, missing_device_count,
        missing_devices_json, presence_comparable, elapsed_millis, scan_mode
      ) VALUES (
        1, '192.168.1.0/24|gateway:192.168.1.1', 1, 2, 'completed', '{}',
        1, 1, 0, '[]', 1, 1000, 'quick'
      )
    ''');
  } else {
    database.execute('''
      INSERT INTO scan_sessions VALUES (
        1, '192.168.1.0/24|gateway:192.168.1.1', 1, 2,
        'completed', '{}', 1, 1, 0, '[]', 1, 1000
      )
    ''');
  }
  database.execute('PRAGMA user_version = $version');
}

Future<Set<String>> _objectNames(AppDatabase database, String type) async {
  final rows = await database
      .customSelect(
        'SELECT name FROM sqlite_master WHERE type = ?',
        variables: [Variable<String>(type)],
      )
      .get();
  return rows.map((row) => row.read<String>('name')).toSet();
}

Future<Set<String>> _columnNames(AppDatabase database, String tableName) async {
  final rows = await database
      .customSelect("PRAGMA table_info('$tableName')")
      .get();
  return rows.map((row) => row.read<String>('name')).toSet();
}
