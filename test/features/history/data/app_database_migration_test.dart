import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spy_dev_det/features/history/data/app_database.dart';

void main() {
  test('şema 3 verilerini koruyarak şema 4 alanlarını ekler', () async {
    final executor = NativeDatabase.memory(
      setup: (database) {
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
            )
          ''')
          ..execute('''
            CREATE TABLE network_profiles (
              network_key TEXT NOT NULL PRIMARY KEY,
              first_seen_at INTEGER NOT NULL,
              last_seen_at INTEGER NOT NULL
            )
          ''')
          ..execute('''
            CREATE TABLE device_identity_aliases (
              alias_key TEXT NOT NULL PRIMARY KEY,
              stable_key TEXT NOT NULL REFERENCES known_devices(stable_key)
                ON DELETE CASCADE,
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
          ''')
          ..execute('''
            INSERT INTO known_devices VALUES (
              'mac:B8:27:EB:12:34:56', 'Eski cihaz', 1, NULL,
              1, 2, '192.168.1.20', 'B8:27:EB:12:34:56', 'Üretici'
            )
          ''')
          ..execute('''
            INSERT INTO network_profiles VALUES (
              '192.168.1.0/24|gateway:192.168.1.1', 1, 2
            )
          ''')
          ..execute('''
            INSERT INTO scan_sessions VALUES (
              1, '192.168.1.0/24|gateway:192.168.1.1', 1, 2,
              'completed', '{}', 1, 1, 0, '[]', 1, 1000
            )
          ''')
          ..execute('PRAGMA user_version = 3');
      },
    );
    final database = AppDatabase.forTesting(executor);
    addTearDown(database.close);

    final known = await database.select(database.knownDevices).getSingle();
    final profile = await database.select(database.networkProfiles).getSingle();
    final session = await database.select(database.scanSessions).getSingle();

    expect(known.customName, 'Eski cihaz');
    expect(known.categoryOverride, isNull);
    expect(known.isOwned, isFalse);
    expect(profile.customName, isNull);
    expect(session.scanMode, 'detailed');
  });
}
