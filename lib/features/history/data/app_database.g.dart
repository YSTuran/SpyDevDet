// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $KnownDevicesTable extends KnownDevices
    with TableInfo<$KnownDevicesTable, KnownDevice> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KnownDevicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _stableKeyMeta = const VerificationMeta(
    'stableKey',
  );
  @override
  late final GeneratedColumn<String> stableKey = GeneratedColumn<String>(
    'stable_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customNameMeta = const VerificationMeta(
    'customName',
  );
  @override
  late final GeneratedColumn<String> customName = GeneratedColumn<String>(
    'custom_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isKnownMeta = const VerificationMeta(
    'isKnown',
  );
  @override
  late final GeneratedColumn<bool> isKnown = GeneratedColumn<bool>(
    'is_known',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_known" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _firstSeenAtMeta = const VerificationMeta(
    'firstSeenAt',
  );
  @override
  late final GeneratedColumn<DateTime> firstSeenAt = GeneratedColumn<DateTime>(
    'first_seen_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSeenAtMeta = const VerificationMeta(
    'lastSeenAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSeenAt = GeneratedColumn<DateTime>(
    'last_seen_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastIpAddressMeta = const VerificationMeta(
    'lastIpAddress',
  );
  @override
  late final GeneratedColumn<String> lastIpAddress = GeneratedColumn<String>(
    'last_ip_address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastMacAddressMeta = const VerificationMeta(
    'lastMacAddress',
  );
  @override
  late final GeneratedColumn<String> lastMacAddress = GeneratedColumn<String>(
    'last_mac_address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _vendorMeta = const VerificationMeta('vendor');
  @override
  late final GeneratedColumn<String> vendor = GeneratedColumn<String>(
    'vendor',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    stableKey,
    customName,
    isKnown,
    note,
    firstSeenAt,
    lastSeenAt,
    lastIpAddress,
    lastMacAddress,
    vendor,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'known_devices';
  @override
  VerificationContext validateIntegrity(
    Insertable<KnownDevice> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('stable_key')) {
      context.handle(
        _stableKeyMeta,
        stableKey.isAcceptableOrUnknown(data['stable_key']!, _stableKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_stableKeyMeta);
    }
    if (data.containsKey('custom_name')) {
      context.handle(
        _customNameMeta,
        customName.isAcceptableOrUnknown(data['custom_name']!, _customNameMeta),
      );
    }
    if (data.containsKey('is_known')) {
      context.handle(
        _isKnownMeta,
        isKnown.isAcceptableOrUnknown(data['is_known']!, _isKnownMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('first_seen_at')) {
      context.handle(
        _firstSeenAtMeta,
        firstSeenAt.isAcceptableOrUnknown(
          data['first_seen_at']!,
          _firstSeenAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_firstSeenAtMeta);
    }
    if (data.containsKey('last_seen_at')) {
      context.handle(
        _lastSeenAtMeta,
        lastSeenAt.isAcceptableOrUnknown(
          data['last_seen_at']!,
          _lastSeenAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastSeenAtMeta);
    }
    if (data.containsKey('last_ip_address')) {
      context.handle(
        _lastIpAddressMeta,
        lastIpAddress.isAcceptableOrUnknown(
          data['last_ip_address']!,
          _lastIpAddressMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastIpAddressMeta);
    }
    if (data.containsKey('last_mac_address')) {
      context.handle(
        _lastMacAddressMeta,
        lastMacAddress.isAcceptableOrUnknown(
          data['last_mac_address']!,
          _lastMacAddressMeta,
        ),
      );
    }
    if (data.containsKey('vendor')) {
      context.handle(
        _vendorMeta,
        vendor.isAcceptableOrUnknown(data['vendor']!, _vendorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {stableKey};
  @override
  KnownDevice map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KnownDevice(
      stableKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stable_key'],
      )!,
      customName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_name'],
      ),
      isKnown: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_known'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      firstSeenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}first_seen_at'],
      )!,
      lastSeenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_seen_at'],
      )!,
      lastIpAddress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_ip_address'],
      )!,
      lastMacAddress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_mac_address'],
      ),
      vendor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vendor'],
      ),
    );
  }

  @override
  $KnownDevicesTable createAlias(String alias) {
    return $KnownDevicesTable(attachedDatabase, alias);
  }
}

class KnownDevice extends DataClass implements Insertable<KnownDevice> {
  final String stableKey;
  final String? customName;
  final bool isKnown;
  final String? note;
  final DateTime firstSeenAt;
  final DateTime lastSeenAt;
  final String lastIpAddress;
  final String? lastMacAddress;
  final String? vendor;
  const KnownDevice({
    required this.stableKey,
    this.customName,
    required this.isKnown,
    this.note,
    required this.firstSeenAt,
    required this.lastSeenAt,
    required this.lastIpAddress,
    this.lastMacAddress,
    this.vendor,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['stable_key'] = Variable<String>(stableKey);
    if (!nullToAbsent || customName != null) {
      map['custom_name'] = Variable<String>(customName);
    }
    map['is_known'] = Variable<bool>(isKnown);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['first_seen_at'] = Variable<DateTime>(firstSeenAt);
    map['last_seen_at'] = Variable<DateTime>(lastSeenAt);
    map['last_ip_address'] = Variable<String>(lastIpAddress);
    if (!nullToAbsent || lastMacAddress != null) {
      map['last_mac_address'] = Variable<String>(lastMacAddress);
    }
    if (!nullToAbsent || vendor != null) {
      map['vendor'] = Variable<String>(vendor);
    }
    return map;
  }

  KnownDevicesCompanion toCompanion(bool nullToAbsent) {
    return KnownDevicesCompanion(
      stableKey: Value(stableKey),
      customName: customName == null && nullToAbsent
          ? const Value.absent()
          : Value(customName),
      isKnown: Value(isKnown),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      firstSeenAt: Value(firstSeenAt),
      lastSeenAt: Value(lastSeenAt),
      lastIpAddress: Value(lastIpAddress),
      lastMacAddress: lastMacAddress == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMacAddress),
      vendor: vendor == null && nullToAbsent
          ? const Value.absent()
          : Value(vendor),
    );
  }

  factory KnownDevice.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KnownDevice(
      stableKey: serializer.fromJson<String>(json['stableKey']),
      customName: serializer.fromJson<String?>(json['customName']),
      isKnown: serializer.fromJson<bool>(json['isKnown']),
      note: serializer.fromJson<String?>(json['note']),
      firstSeenAt: serializer.fromJson<DateTime>(json['firstSeenAt']),
      lastSeenAt: serializer.fromJson<DateTime>(json['lastSeenAt']),
      lastIpAddress: serializer.fromJson<String>(json['lastIpAddress']),
      lastMacAddress: serializer.fromJson<String?>(json['lastMacAddress']),
      vendor: serializer.fromJson<String?>(json['vendor']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'stableKey': serializer.toJson<String>(stableKey),
      'customName': serializer.toJson<String?>(customName),
      'isKnown': serializer.toJson<bool>(isKnown),
      'note': serializer.toJson<String?>(note),
      'firstSeenAt': serializer.toJson<DateTime>(firstSeenAt),
      'lastSeenAt': serializer.toJson<DateTime>(lastSeenAt),
      'lastIpAddress': serializer.toJson<String>(lastIpAddress),
      'lastMacAddress': serializer.toJson<String?>(lastMacAddress),
      'vendor': serializer.toJson<String?>(vendor),
    };
  }

  KnownDevice copyWith({
    String? stableKey,
    Value<String?> customName = const Value.absent(),
    bool? isKnown,
    Value<String?> note = const Value.absent(),
    DateTime? firstSeenAt,
    DateTime? lastSeenAt,
    String? lastIpAddress,
    Value<String?> lastMacAddress = const Value.absent(),
    Value<String?> vendor = const Value.absent(),
  }) => KnownDevice(
    stableKey: stableKey ?? this.stableKey,
    customName: customName.present ? customName.value : this.customName,
    isKnown: isKnown ?? this.isKnown,
    note: note.present ? note.value : this.note,
    firstSeenAt: firstSeenAt ?? this.firstSeenAt,
    lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    lastIpAddress: lastIpAddress ?? this.lastIpAddress,
    lastMacAddress: lastMacAddress.present
        ? lastMacAddress.value
        : this.lastMacAddress,
    vendor: vendor.present ? vendor.value : this.vendor,
  );
  KnownDevice copyWithCompanion(KnownDevicesCompanion data) {
    return KnownDevice(
      stableKey: data.stableKey.present ? data.stableKey.value : this.stableKey,
      customName: data.customName.present
          ? data.customName.value
          : this.customName,
      isKnown: data.isKnown.present ? data.isKnown.value : this.isKnown,
      note: data.note.present ? data.note.value : this.note,
      firstSeenAt: data.firstSeenAt.present
          ? data.firstSeenAt.value
          : this.firstSeenAt,
      lastSeenAt: data.lastSeenAt.present
          ? data.lastSeenAt.value
          : this.lastSeenAt,
      lastIpAddress: data.lastIpAddress.present
          ? data.lastIpAddress.value
          : this.lastIpAddress,
      lastMacAddress: data.lastMacAddress.present
          ? data.lastMacAddress.value
          : this.lastMacAddress,
      vendor: data.vendor.present ? data.vendor.value : this.vendor,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KnownDevice(')
          ..write('stableKey: $stableKey, ')
          ..write('customName: $customName, ')
          ..write('isKnown: $isKnown, ')
          ..write('note: $note, ')
          ..write('firstSeenAt: $firstSeenAt, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('lastIpAddress: $lastIpAddress, ')
          ..write('lastMacAddress: $lastMacAddress, ')
          ..write('vendor: $vendor')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    stableKey,
    customName,
    isKnown,
    note,
    firstSeenAt,
    lastSeenAt,
    lastIpAddress,
    lastMacAddress,
    vendor,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KnownDevice &&
          other.stableKey == this.stableKey &&
          other.customName == this.customName &&
          other.isKnown == this.isKnown &&
          other.note == this.note &&
          other.firstSeenAt == this.firstSeenAt &&
          other.lastSeenAt == this.lastSeenAt &&
          other.lastIpAddress == this.lastIpAddress &&
          other.lastMacAddress == this.lastMacAddress &&
          other.vendor == this.vendor);
}

class KnownDevicesCompanion extends UpdateCompanion<KnownDevice> {
  final Value<String> stableKey;
  final Value<String?> customName;
  final Value<bool> isKnown;
  final Value<String?> note;
  final Value<DateTime> firstSeenAt;
  final Value<DateTime> lastSeenAt;
  final Value<String> lastIpAddress;
  final Value<String?> lastMacAddress;
  final Value<String?> vendor;
  final Value<int> rowid;
  const KnownDevicesCompanion({
    this.stableKey = const Value.absent(),
    this.customName = const Value.absent(),
    this.isKnown = const Value.absent(),
    this.note = const Value.absent(),
    this.firstSeenAt = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
    this.lastIpAddress = const Value.absent(),
    this.lastMacAddress = const Value.absent(),
    this.vendor = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KnownDevicesCompanion.insert({
    required String stableKey,
    this.customName = const Value.absent(),
    this.isKnown = const Value.absent(),
    this.note = const Value.absent(),
    required DateTime firstSeenAt,
    required DateTime lastSeenAt,
    required String lastIpAddress,
    this.lastMacAddress = const Value.absent(),
    this.vendor = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : stableKey = Value(stableKey),
       firstSeenAt = Value(firstSeenAt),
       lastSeenAt = Value(lastSeenAt),
       lastIpAddress = Value(lastIpAddress);
  static Insertable<KnownDevice> custom({
    Expression<String>? stableKey,
    Expression<String>? customName,
    Expression<bool>? isKnown,
    Expression<String>? note,
    Expression<DateTime>? firstSeenAt,
    Expression<DateTime>? lastSeenAt,
    Expression<String>? lastIpAddress,
    Expression<String>? lastMacAddress,
    Expression<String>? vendor,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (stableKey != null) 'stable_key': stableKey,
      if (customName != null) 'custom_name': customName,
      if (isKnown != null) 'is_known': isKnown,
      if (note != null) 'note': note,
      if (firstSeenAt != null) 'first_seen_at': firstSeenAt,
      if (lastSeenAt != null) 'last_seen_at': lastSeenAt,
      if (lastIpAddress != null) 'last_ip_address': lastIpAddress,
      if (lastMacAddress != null) 'last_mac_address': lastMacAddress,
      if (vendor != null) 'vendor': vendor,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KnownDevicesCompanion copyWith({
    Value<String>? stableKey,
    Value<String?>? customName,
    Value<bool>? isKnown,
    Value<String?>? note,
    Value<DateTime>? firstSeenAt,
    Value<DateTime>? lastSeenAt,
    Value<String>? lastIpAddress,
    Value<String?>? lastMacAddress,
    Value<String?>? vendor,
    Value<int>? rowid,
  }) {
    return KnownDevicesCompanion(
      stableKey: stableKey ?? this.stableKey,
      customName: customName ?? this.customName,
      isKnown: isKnown ?? this.isKnown,
      note: note ?? this.note,
      firstSeenAt: firstSeenAt ?? this.firstSeenAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      lastIpAddress: lastIpAddress ?? this.lastIpAddress,
      lastMacAddress: lastMacAddress ?? this.lastMacAddress,
      vendor: vendor ?? this.vendor,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (stableKey.present) {
      map['stable_key'] = Variable<String>(stableKey.value);
    }
    if (customName.present) {
      map['custom_name'] = Variable<String>(customName.value);
    }
    if (isKnown.present) {
      map['is_known'] = Variable<bool>(isKnown.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (firstSeenAt.present) {
      map['first_seen_at'] = Variable<DateTime>(firstSeenAt.value);
    }
    if (lastSeenAt.present) {
      map['last_seen_at'] = Variable<DateTime>(lastSeenAt.value);
    }
    if (lastIpAddress.present) {
      map['last_ip_address'] = Variable<String>(lastIpAddress.value);
    }
    if (lastMacAddress.present) {
      map['last_mac_address'] = Variable<String>(lastMacAddress.value);
    }
    if (vendor.present) {
      map['vendor'] = Variable<String>(vendor.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KnownDevicesCompanion(')
          ..write('stableKey: $stableKey, ')
          ..write('customName: $customName, ')
          ..write('isKnown: $isKnown, ')
          ..write('note: $note, ')
          ..write('firstSeenAt: $firstSeenAt, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('lastIpAddress: $lastIpAddress, ')
          ..write('lastMacAddress: $lastMacAddress, ')
          ..write('vendor: $vendor, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ScanSessionsTable extends ScanSessions
    with TableInfo<$ScanSessionsTable, ScanSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScanSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _networkKeyMeta = const VerificationMeta(
    'networkKey',
  );
  @override
  late final GeneratedColumn<String> networkKey = GeneratedColumn<String>(
    'network_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _outcomeMeta = const VerificationMeta(
    'outcome',
  );
  @override
  late final GeneratedColumn<String> outcome = GeneratedColumn<String>(
    'outcome',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _methodsJsonMeta = const VerificationMeta(
    'methodsJson',
  );
  @override
  late final GeneratedColumn<String> methodsJson = GeneratedColumn<String>(
    'methods_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalDeviceCountMeta = const VerificationMeta(
    'totalDeviceCount',
  );
  @override
  late final GeneratedColumn<int> totalDeviceCount = GeneratedColumn<int>(
    'total_device_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _newDeviceCountMeta = const VerificationMeta(
    'newDeviceCount',
  );
  @override
  late final GeneratedColumn<int> newDeviceCount = GeneratedColumn<int>(
    'new_device_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _missingDeviceCountMeta =
      const VerificationMeta('missingDeviceCount');
  @override
  late final GeneratedColumn<int> missingDeviceCount = GeneratedColumn<int>(
    'missing_device_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _missingDevicesJsonMeta =
      const VerificationMeta('missingDevicesJson');
  @override
  late final GeneratedColumn<String> missingDevicesJson =
      GeneratedColumn<String>(
        'missing_devices_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _presenceComparableMeta =
      const VerificationMeta('presenceComparable');
  @override
  late final GeneratedColumn<bool> presenceComparable = GeneratedColumn<bool>(
    'presence_comparable',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("presence_comparable" IN (0, 1))',
    ),
  );
  static const VerificationMeta _elapsedMillisMeta = const VerificationMeta(
    'elapsedMillis',
  );
  @override
  late final GeneratedColumn<int> elapsedMillis = GeneratedColumn<int>(
    'elapsed_millis',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    networkKey,
    startedAt,
    completedAt,
    outcome,
    methodsJson,
    totalDeviceCount,
    newDeviceCount,
    missingDeviceCount,
    missingDevicesJson,
    presenceComparable,
    elapsedMillis,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scan_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScanSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('network_key')) {
      context.handle(
        _networkKeyMeta,
        networkKey.isAcceptableOrUnknown(data['network_key']!, _networkKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_networkKeyMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedAtMeta);
    }
    if (data.containsKey('outcome')) {
      context.handle(
        _outcomeMeta,
        outcome.isAcceptableOrUnknown(data['outcome']!, _outcomeMeta),
      );
    } else if (isInserting) {
      context.missing(_outcomeMeta);
    }
    if (data.containsKey('methods_json')) {
      context.handle(
        _methodsJsonMeta,
        methodsJson.isAcceptableOrUnknown(
          data['methods_json']!,
          _methodsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_methodsJsonMeta);
    }
    if (data.containsKey('total_device_count')) {
      context.handle(
        _totalDeviceCountMeta,
        totalDeviceCount.isAcceptableOrUnknown(
          data['total_device_count']!,
          _totalDeviceCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalDeviceCountMeta);
    }
    if (data.containsKey('new_device_count')) {
      context.handle(
        _newDeviceCountMeta,
        newDeviceCount.isAcceptableOrUnknown(
          data['new_device_count']!,
          _newDeviceCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_newDeviceCountMeta);
    }
    if (data.containsKey('missing_device_count')) {
      context.handle(
        _missingDeviceCountMeta,
        missingDeviceCount.isAcceptableOrUnknown(
          data['missing_device_count']!,
          _missingDeviceCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_missingDeviceCountMeta);
    }
    if (data.containsKey('missing_devices_json')) {
      context.handle(
        _missingDevicesJsonMeta,
        missingDevicesJson.isAcceptableOrUnknown(
          data['missing_devices_json']!,
          _missingDevicesJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_missingDevicesJsonMeta);
    }
    if (data.containsKey('presence_comparable')) {
      context.handle(
        _presenceComparableMeta,
        presenceComparable.isAcceptableOrUnknown(
          data['presence_comparable']!,
          _presenceComparableMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_presenceComparableMeta);
    }
    if (data.containsKey('elapsed_millis')) {
      context.handle(
        _elapsedMillisMeta,
        elapsedMillis.isAcceptableOrUnknown(
          data['elapsed_millis']!,
          _elapsedMillisMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_elapsedMillisMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ScanSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScanSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      networkKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}network_key'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      )!,
      outcome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}outcome'],
      )!,
      methodsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}methods_json'],
      )!,
      totalDeviceCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_device_count'],
      )!,
      newDeviceCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}new_device_count'],
      )!,
      missingDeviceCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}missing_device_count'],
      )!,
      missingDevicesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}missing_devices_json'],
      )!,
      presenceComparable: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}presence_comparable'],
      )!,
      elapsedMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}elapsed_millis'],
      )!,
    );
  }

  @override
  $ScanSessionsTable createAlias(String alias) {
    return $ScanSessionsTable(attachedDatabase, alias);
  }
}

class ScanSession extends DataClass implements Insertable<ScanSession> {
  final int id;
  final String networkKey;
  final DateTime startedAt;
  final DateTime completedAt;
  final String outcome;
  final String methodsJson;
  final int totalDeviceCount;
  final int newDeviceCount;
  final int missingDeviceCount;
  final String missingDevicesJson;
  final bool presenceComparable;
  final int elapsedMillis;
  const ScanSession({
    required this.id,
    required this.networkKey,
    required this.startedAt,
    required this.completedAt,
    required this.outcome,
    required this.methodsJson,
    required this.totalDeviceCount,
    required this.newDeviceCount,
    required this.missingDeviceCount,
    required this.missingDevicesJson,
    required this.presenceComparable,
    required this.elapsedMillis,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['network_key'] = Variable<String>(networkKey);
    map['started_at'] = Variable<DateTime>(startedAt);
    map['completed_at'] = Variable<DateTime>(completedAt);
    map['outcome'] = Variable<String>(outcome);
    map['methods_json'] = Variable<String>(methodsJson);
    map['total_device_count'] = Variable<int>(totalDeviceCount);
    map['new_device_count'] = Variable<int>(newDeviceCount);
    map['missing_device_count'] = Variable<int>(missingDeviceCount);
    map['missing_devices_json'] = Variable<String>(missingDevicesJson);
    map['presence_comparable'] = Variable<bool>(presenceComparable);
    map['elapsed_millis'] = Variable<int>(elapsedMillis);
    return map;
  }

  ScanSessionsCompanion toCompanion(bool nullToAbsent) {
    return ScanSessionsCompanion(
      id: Value(id),
      networkKey: Value(networkKey),
      startedAt: Value(startedAt),
      completedAt: Value(completedAt),
      outcome: Value(outcome),
      methodsJson: Value(methodsJson),
      totalDeviceCount: Value(totalDeviceCount),
      newDeviceCount: Value(newDeviceCount),
      missingDeviceCount: Value(missingDeviceCount),
      missingDevicesJson: Value(missingDevicesJson),
      presenceComparable: Value(presenceComparable),
      elapsedMillis: Value(elapsedMillis),
    );
  }

  factory ScanSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScanSession(
      id: serializer.fromJson<int>(json['id']),
      networkKey: serializer.fromJson<String>(json['networkKey']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
      outcome: serializer.fromJson<String>(json['outcome']),
      methodsJson: serializer.fromJson<String>(json['methodsJson']),
      totalDeviceCount: serializer.fromJson<int>(json['totalDeviceCount']),
      newDeviceCount: serializer.fromJson<int>(json['newDeviceCount']),
      missingDeviceCount: serializer.fromJson<int>(json['missingDeviceCount']),
      missingDevicesJson: serializer.fromJson<String>(
        json['missingDevicesJson'],
      ),
      presenceComparable: serializer.fromJson<bool>(json['presenceComparable']),
      elapsedMillis: serializer.fromJson<int>(json['elapsedMillis']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'networkKey': serializer.toJson<String>(networkKey),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'completedAt': serializer.toJson<DateTime>(completedAt),
      'outcome': serializer.toJson<String>(outcome),
      'methodsJson': serializer.toJson<String>(methodsJson),
      'totalDeviceCount': serializer.toJson<int>(totalDeviceCount),
      'newDeviceCount': serializer.toJson<int>(newDeviceCount),
      'missingDeviceCount': serializer.toJson<int>(missingDeviceCount),
      'missingDevicesJson': serializer.toJson<String>(missingDevicesJson),
      'presenceComparable': serializer.toJson<bool>(presenceComparable),
      'elapsedMillis': serializer.toJson<int>(elapsedMillis),
    };
  }

  ScanSession copyWith({
    int? id,
    String? networkKey,
    DateTime? startedAt,
    DateTime? completedAt,
    String? outcome,
    String? methodsJson,
    int? totalDeviceCount,
    int? newDeviceCount,
    int? missingDeviceCount,
    String? missingDevicesJson,
    bool? presenceComparable,
    int? elapsedMillis,
  }) => ScanSession(
    id: id ?? this.id,
    networkKey: networkKey ?? this.networkKey,
    startedAt: startedAt ?? this.startedAt,
    completedAt: completedAt ?? this.completedAt,
    outcome: outcome ?? this.outcome,
    methodsJson: methodsJson ?? this.methodsJson,
    totalDeviceCount: totalDeviceCount ?? this.totalDeviceCount,
    newDeviceCount: newDeviceCount ?? this.newDeviceCount,
    missingDeviceCount: missingDeviceCount ?? this.missingDeviceCount,
    missingDevicesJson: missingDevicesJson ?? this.missingDevicesJson,
    presenceComparable: presenceComparable ?? this.presenceComparable,
    elapsedMillis: elapsedMillis ?? this.elapsedMillis,
  );
  ScanSession copyWithCompanion(ScanSessionsCompanion data) {
    return ScanSession(
      id: data.id.present ? data.id.value : this.id,
      networkKey: data.networkKey.present
          ? data.networkKey.value
          : this.networkKey,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      outcome: data.outcome.present ? data.outcome.value : this.outcome,
      methodsJson: data.methodsJson.present
          ? data.methodsJson.value
          : this.methodsJson,
      totalDeviceCount: data.totalDeviceCount.present
          ? data.totalDeviceCount.value
          : this.totalDeviceCount,
      newDeviceCount: data.newDeviceCount.present
          ? data.newDeviceCount.value
          : this.newDeviceCount,
      missingDeviceCount: data.missingDeviceCount.present
          ? data.missingDeviceCount.value
          : this.missingDeviceCount,
      missingDevicesJson: data.missingDevicesJson.present
          ? data.missingDevicesJson.value
          : this.missingDevicesJson,
      presenceComparable: data.presenceComparable.present
          ? data.presenceComparable.value
          : this.presenceComparable,
      elapsedMillis: data.elapsedMillis.present
          ? data.elapsedMillis.value
          : this.elapsedMillis,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScanSession(')
          ..write('id: $id, ')
          ..write('networkKey: $networkKey, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('outcome: $outcome, ')
          ..write('methodsJson: $methodsJson, ')
          ..write('totalDeviceCount: $totalDeviceCount, ')
          ..write('newDeviceCount: $newDeviceCount, ')
          ..write('missingDeviceCount: $missingDeviceCount, ')
          ..write('missingDevicesJson: $missingDevicesJson, ')
          ..write('presenceComparable: $presenceComparable, ')
          ..write('elapsedMillis: $elapsedMillis')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    networkKey,
    startedAt,
    completedAt,
    outcome,
    methodsJson,
    totalDeviceCount,
    newDeviceCount,
    missingDeviceCount,
    missingDevicesJson,
    presenceComparable,
    elapsedMillis,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScanSession &&
          other.id == this.id &&
          other.networkKey == this.networkKey &&
          other.startedAt == this.startedAt &&
          other.completedAt == this.completedAt &&
          other.outcome == this.outcome &&
          other.methodsJson == this.methodsJson &&
          other.totalDeviceCount == this.totalDeviceCount &&
          other.newDeviceCount == this.newDeviceCount &&
          other.missingDeviceCount == this.missingDeviceCount &&
          other.missingDevicesJson == this.missingDevicesJson &&
          other.presenceComparable == this.presenceComparable &&
          other.elapsedMillis == this.elapsedMillis);
}

class ScanSessionsCompanion extends UpdateCompanion<ScanSession> {
  final Value<int> id;
  final Value<String> networkKey;
  final Value<DateTime> startedAt;
  final Value<DateTime> completedAt;
  final Value<String> outcome;
  final Value<String> methodsJson;
  final Value<int> totalDeviceCount;
  final Value<int> newDeviceCount;
  final Value<int> missingDeviceCount;
  final Value<String> missingDevicesJson;
  final Value<bool> presenceComparable;
  final Value<int> elapsedMillis;
  const ScanSessionsCompanion({
    this.id = const Value.absent(),
    this.networkKey = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.outcome = const Value.absent(),
    this.methodsJson = const Value.absent(),
    this.totalDeviceCount = const Value.absent(),
    this.newDeviceCount = const Value.absent(),
    this.missingDeviceCount = const Value.absent(),
    this.missingDevicesJson = const Value.absent(),
    this.presenceComparable = const Value.absent(),
    this.elapsedMillis = const Value.absent(),
  });
  ScanSessionsCompanion.insert({
    this.id = const Value.absent(),
    required String networkKey,
    required DateTime startedAt,
    required DateTime completedAt,
    required String outcome,
    required String methodsJson,
    required int totalDeviceCount,
    required int newDeviceCount,
    required int missingDeviceCount,
    required String missingDevicesJson,
    required bool presenceComparable,
    required int elapsedMillis,
  }) : networkKey = Value(networkKey),
       startedAt = Value(startedAt),
       completedAt = Value(completedAt),
       outcome = Value(outcome),
       methodsJson = Value(methodsJson),
       totalDeviceCount = Value(totalDeviceCount),
       newDeviceCount = Value(newDeviceCount),
       missingDeviceCount = Value(missingDeviceCount),
       missingDevicesJson = Value(missingDevicesJson),
       presenceComparable = Value(presenceComparable),
       elapsedMillis = Value(elapsedMillis);
  static Insertable<ScanSession> custom({
    Expression<int>? id,
    Expression<String>? networkKey,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? completedAt,
    Expression<String>? outcome,
    Expression<String>? methodsJson,
    Expression<int>? totalDeviceCount,
    Expression<int>? newDeviceCount,
    Expression<int>? missingDeviceCount,
    Expression<String>? missingDevicesJson,
    Expression<bool>? presenceComparable,
    Expression<int>? elapsedMillis,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (networkKey != null) 'network_key': networkKey,
      if (startedAt != null) 'started_at': startedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (outcome != null) 'outcome': outcome,
      if (methodsJson != null) 'methods_json': methodsJson,
      if (totalDeviceCount != null) 'total_device_count': totalDeviceCount,
      if (newDeviceCount != null) 'new_device_count': newDeviceCount,
      if (missingDeviceCount != null)
        'missing_device_count': missingDeviceCount,
      if (missingDevicesJson != null)
        'missing_devices_json': missingDevicesJson,
      if (presenceComparable != null) 'presence_comparable': presenceComparable,
      if (elapsedMillis != null) 'elapsed_millis': elapsedMillis,
    });
  }

  ScanSessionsCompanion copyWith({
    Value<int>? id,
    Value<String>? networkKey,
    Value<DateTime>? startedAt,
    Value<DateTime>? completedAt,
    Value<String>? outcome,
    Value<String>? methodsJson,
    Value<int>? totalDeviceCount,
    Value<int>? newDeviceCount,
    Value<int>? missingDeviceCount,
    Value<String>? missingDevicesJson,
    Value<bool>? presenceComparable,
    Value<int>? elapsedMillis,
  }) {
    return ScanSessionsCompanion(
      id: id ?? this.id,
      networkKey: networkKey ?? this.networkKey,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      outcome: outcome ?? this.outcome,
      methodsJson: methodsJson ?? this.methodsJson,
      totalDeviceCount: totalDeviceCount ?? this.totalDeviceCount,
      newDeviceCount: newDeviceCount ?? this.newDeviceCount,
      missingDeviceCount: missingDeviceCount ?? this.missingDeviceCount,
      missingDevicesJson: missingDevicesJson ?? this.missingDevicesJson,
      presenceComparable: presenceComparable ?? this.presenceComparable,
      elapsedMillis: elapsedMillis ?? this.elapsedMillis,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (networkKey.present) {
      map['network_key'] = Variable<String>(networkKey.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (outcome.present) {
      map['outcome'] = Variable<String>(outcome.value);
    }
    if (methodsJson.present) {
      map['methods_json'] = Variable<String>(methodsJson.value);
    }
    if (totalDeviceCount.present) {
      map['total_device_count'] = Variable<int>(totalDeviceCount.value);
    }
    if (newDeviceCount.present) {
      map['new_device_count'] = Variable<int>(newDeviceCount.value);
    }
    if (missingDeviceCount.present) {
      map['missing_device_count'] = Variable<int>(missingDeviceCount.value);
    }
    if (missingDevicesJson.present) {
      map['missing_devices_json'] = Variable<String>(missingDevicesJson.value);
    }
    if (presenceComparable.present) {
      map['presence_comparable'] = Variable<bool>(presenceComparable.value);
    }
    if (elapsedMillis.present) {
      map['elapsed_millis'] = Variable<int>(elapsedMillis.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScanSessionsCompanion(')
          ..write('id: $id, ')
          ..write('networkKey: $networkKey, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('outcome: $outcome, ')
          ..write('methodsJson: $methodsJson, ')
          ..write('totalDeviceCount: $totalDeviceCount, ')
          ..write('newDeviceCount: $newDeviceCount, ')
          ..write('missingDeviceCount: $missingDeviceCount, ')
          ..write('missingDevicesJson: $missingDevicesJson, ')
          ..write('presenceComparable: $presenceComparable, ')
          ..write('elapsedMillis: $elapsedMillis')
          ..write(')'))
        .toString();
  }
}

class $ScanObservationsTable extends ScanObservations
    with TableInfo<$ScanObservationsTable, ScanObservation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScanObservationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _scanSessionIdMeta = const VerificationMeta(
    'scanSessionId',
  );
  @override
  late final GeneratedColumn<int> scanSessionId = GeneratedColumn<int>(
    'scan_session_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES scan_sessions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _stableKeyMeta = const VerificationMeta(
    'stableKey',
  );
  @override
  late final GeneratedColumn<String> stableKey = GeneratedColumn<String>(
    'stable_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ipAddressMeta = const VerificationMeta(
    'ipAddress',
  );
  @override
  late final GeneratedColumn<String> ipAddress = GeneratedColumn<String>(
    'ip_address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _macAddressMeta = const VerificationMeta(
    'macAddress',
  );
  @override
  late final GeneratedColumn<String> macAddress = GeneratedColumn<String>(
    'mac_address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _macStatusMeta = const VerificationMeta(
    'macStatus',
  );
  @override
  late final GeneratedColumn<String> macStatus = GeneratedColumn<String>(
    'mac_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vendorMeta = const VerificationMeta('vendor');
  @override
  late final GeneratedColumn<String> vendor = GeneratedColumn<String>(
    'vendor',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _confidenceMeta = const VerificationMeta(
    'confidence',
  );
  @override
  late final GeneratedColumn<String> confidence = GeneratedColumn<String>(
    'confidence',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _discoveryMethodMeta = const VerificationMeta(
    'discoveryMethod',
  );
  @override
  late final GeneratedColumn<String> discoveryMethod = GeneratedColumn<String>(
    'discovery_method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _servicesJsonMeta = const VerificationMeta(
    'servicesJson',
  );
  @override
  late final GeneratedColumn<String> servicesJson = GeneratedColumn<String>(
    'services_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _evidenceJsonMeta = const VerificationMeta(
    'evidenceJson',
  );
  @override
  late final GeneratedColumn<String> evidenceJson = GeneratedColumn<String>(
    'evidence_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wasNewMeta = const VerificationMeta('wasNew');
  @override
  late final GeneratedColumn<bool> wasNew = GeneratedColumn<bool>(
    'was_new',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("was_new" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    scanSessionId,
    stableKey,
    ipAddress,
    displayName,
    macAddress,
    macStatus,
    vendor,
    category,
    confidence,
    discoveryMethod,
    servicesJson,
    evidenceJson,
    wasNew,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scan_observations';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScanObservation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('scan_session_id')) {
      context.handle(
        _scanSessionIdMeta,
        scanSessionId.isAcceptableOrUnknown(
          data['scan_session_id']!,
          _scanSessionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scanSessionIdMeta);
    }
    if (data.containsKey('stable_key')) {
      context.handle(
        _stableKeyMeta,
        stableKey.isAcceptableOrUnknown(data['stable_key']!, _stableKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_stableKeyMeta);
    }
    if (data.containsKey('ip_address')) {
      context.handle(
        _ipAddressMeta,
        ipAddress.isAcceptableOrUnknown(data['ip_address']!, _ipAddressMeta),
      );
    } else if (isInserting) {
      context.missing(_ipAddressMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('mac_address')) {
      context.handle(
        _macAddressMeta,
        macAddress.isAcceptableOrUnknown(data['mac_address']!, _macAddressMeta),
      );
    }
    if (data.containsKey('mac_status')) {
      context.handle(
        _macStatusMeta,
        macStatus.isAcceptableOrUnknown(data['mac_status']!, _macStatusMeta),
      );
    } else if (isInserting) {
      context.missing(_macStatusMeta);
    }
    if (data.containsKey('vendor')) {
      context.handle(
        _vendorMeta,
        vendor.isAcceptableOrUnknown(data['vendor']!, _vendorMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('confidence')) {
      context.handle(
        _confidenceMeta,
        confidence.isAcceptableOrUnknown(data['confidence']!, _confidenceMeta),
      );
    } else if (isInserting) {
      context.missing(_confidenceMeta);
    }
    if (data.containsKey('discovery_method')) {
      context.handle(
        _discoveryMethodMeta,
        discoveryMethod.isAcceptableOrUnknown(
          data['discovery_method']!,
          _discoveryMethodMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_discoveryMethodMeta);
    }
    if (data.containsKey('services_json')) {
      context.handle(
        _servicesJsonMeta,
        servicesJson.isAcceptableOrUnknown(
          data['services_json']!,
          _servicesJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_servicesJsonMeta);
    }
    if (data.containsKey('evidence_json')) {
      context.handle(
        _evidenceJsonMeta,
        evidenceJson.isAcceptableOrUnknown(
          data['evidence_json']!,
          _evidenceJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_evidenceJsonMeta);
    }
    if (data.containsKey('was_new')) {
      context.handle(
        _wasNewMeta,
        wasNew.isAcceptableOrUnknown(data['was_new']!, _wasNewMeta),
      );
    } else if (isInserting) {
      context.missing(_wasNewMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ScanObservation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScanObservation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      scanSessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}scan_session_id'],
      )!,
      stableKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stable_key'],
      )!,
      ipAddress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ip_address'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      macAddress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mac_address'],
      ),
      macStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mac_status'],
      )!,
      vendor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vendor'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      confidence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}confidence'],
      )!,
      discoveryMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}discovery_method'],
      )!,
      servicesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}services_json'],
      )!,
      evidenceJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}evidence_json'],
      )!,
      wasNew: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}was_new'],
      )!,
    );
  }

  @override
  $ScanObservationsTable createAlias(String alias) {
    return $ScanObservationsTable(attachedDatabase, alias);
  }
}

class ScanObservation extends DataClass implements Insertable<ScanObservation> {
  final int id;
  final int scanSessionId;
  final String stableKey;
  final String ipAddress;
  final String displayName;
  final String? macAddress;
  final String macStatus;
  final String? vendor;
  final String category;
  final String confidence;
  final String discoveryMethod;
  final String servicesJson;
  final String evidenceJson;
  final bool wasNew;
  const ScanObservation({
    required this.id,
    required this.scanSessionId,
    required this.stableKey,
    required this.ipAddress,
    required this.displayName,
    this.macAddress,
    required this.macStatus,
    this.vendor,
    required this.category,
    required this.confidence,
    required this.discoveryMethod,
    required this.servicesJson,
    required this.evidenceJson,
    required this.wasNew,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['scan_session_id'] = Variable<int>(scanSessionId);
    map['stable_key'] = Variable<String>(stableKey);
    map['ip_address'] = Variable<String>(ipAddress);
    map['display_name'] = Variable<String>(displayName);
    if (!nullToAbsent || macAddress != null) {
      map['mac_address'] = Variable<String>(macAddress);
    }
    map['mac_status'] = Variable<String>(macStatus);
    if (!nullToAbsent || vendor != null) {
      map['vendor'] = Variable<String>(vendor);
    }
    map['category'] = Variable<String>(category);
    map['confidence'] = Variable<String>(confidence);
    map['discovery_method'] = Variable<String>(discoveryMethod);
    map['services_json'] = Variable<String>(servicesJson);
    map['evidence_json'] = Variable<String>(evidenceJson);
    map['was_new'] = Variable<bool>(wasNew);
    return map;
  }

  ScanObservationsCompanion toCompanion(bool nullToAbsent) {
    return ScanObservationsCompanion(
      id: Value(id),
      scanSessionId: Value(scanSessionId),
      stableKey: Value(stableKey),
      ipAddress: Value(ipAddress),
      displayName: Value(displayName),
      macAddress: macAddress == null && nullToAbsent
          ? const Value.absent()
          : Value(macAddress),
      macStatus: Value(macStatus),
      vendor: vendor == null && nullToAbsent
          ? const Value.absent()
          : Value(vendor),
      category: Value(category),
      confidence: Value(confidence),
      discoveryMethod: Value(discoveryMethod),
      servicesJson: Value(servicesJson),
      evidenceJson: Value(evidenceJson),
      wasNew: Value(wasNew),
    );
  }

  factory ScanObservation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScanObservation(
      id: serializer.fromJson<int>(json['id']),
      scanSessionId: serializer.fromJson<int>(json['scanSessionId']),
      stableKey: serializer.fromJson<String>(json['stableKey']),
      ipAddress: serializer.fromJson<String>(json['ipAddress']),
      displayName: serializer.fromJson<String>(json['displayName']),
      macAddress: serializer.fromJson<String?>(json['macAddress']),
      macStatus: serializer.fromJson<String>(json['macStatus']),
      vendor: serializer.fromJson<String?>(json['vendor']),
      category: serializer.fromJson<String>(json['category']),
      confidence: serializer.fromJson<String>(json['confidence']),
      discoveryMethod: serializer.fromJson<String>(json['discoveryMethod']),
      servicesJson: serializer.fromJson<String>(json['servicesJson']),
      evidenceJson: serializer.fromJson<String>(json['evidenceJson']),
      wasNew: serializer.fromJson<bool>(json['wasNew']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'scanSessionId': serializer.toJson<int>(scanSessionId),
      'stableKey': serializer.toJson<String>(stableKey),
      'ipAddress': serializer.toJson<String>(ipAddress),
      'displayName': serializer.toJson<String>(displayName),
      'macAddress': serializer.toJson<String?>(macAddress),
      'macStatus': serializer.toJson<String>(macStatus),
      'vendor': serializer.toJson<String?>(vendor),
      'category': serializer.toJson<String>(category),
      'confidence': serializer.toJson<String>(confidence),
      'discoveryMethod': serializer.toJson<String>(discoveryMethod),
      'servicesJson': serializer.toJson<String>(servicesJson),
      'evidenceJson': serializer.toJson<String>(evidenceJson),
      'wasNew': serializer.toJson<bool>(wasNew),
    };
  }

  ScanObservation copyWith({
    int? id,
    int? scanSessionId,
    String? stableKey,
    String? ipAddress,
    String? displayName,
    Value<String?> macAddress = const Value.absent(),
    String? macStatus,
    Value<String?> vendor = const Value.absent(),
    String? category,
    String? confidence,
    String? discoveryMethod,
    String? servicesJson,
    String? evidenceJson,
    bool? wasNew,
  }) => ScanObservation(
    id: id ?? this.id,
    scanSessionId: scanSessionId ?? this.scanSessionId,
    stableKey: stableKey ?? this.stableKey,
    ipAddress: ipAddress ?? this.ipAddress,
    displayName: displayName ?? this.displayName,
    macAddress: macAddress.present ? macAddress.value : this.macAddress,
    macStatus: macStatus ?? this.macStatus,
    vendor: vendor.present ? vendor.value : this.vendor,
    category: category ?? this.category,
    confidence: confidence ?? this.confidence,
    discoveryMethod: discoveryMethod ?? this.discoveryMethod,
    servicesJson: servicesJson ?? this.servicesJson,
    evidenceJson: evidenceJson ?? this.evidenceJson,
    wasNew: wasNew ?? this.wasNew,
  );
  ScanObservation copyWithCompanion(ScanObservationsCompanion data) {
    return ScanObservation(
      id: data.id.present ? data.id.value : this.id,
      scanSessionId: data.scanSessionId.present
          ? data.scanSessionId.value
          : this.scanSessionId,
      stableKey: data.stableKey.present ? data.stableKey.value : this.stableKey,
      ipAddress: data.ipAddress.present ? data.ipAddress.value : this.ipAddress,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      macAddress: data.macAddress.present
          ? data.macAddress.value
          : this.macAddress,
      macStatus: data.macStatus.present ? data.macStatus.value : this.macStatus,
      vendor: data.vendor.present ? data.vendor.value : this.vendor,
      category: data.category.present ? data.category.value : this.category,
      confidence: data.confidence.present
          ? data.confidence.value
          : this.confidence,
      discoveryMethod: data.discoveryMethod.present
          ? data.discoveryMethod.value
          : this.discoveryMethod,
      servicesJson: data.servicesJson.present
          ? data.servicesJson.value
          : this.servicesJson,
      evidenceJson: data.evidenceJson.present
          ? data.evidenceJson.value
          : this.evidenceJson,
      wasNew: data.wasNew.present ? data.wasNew.value : this.wasNew,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScanObservation(')
          ..write('id: $id, ')
          ..write('scanSessionId: $scanSessionId, ')
          ..write('stableKey: $stableKey, ')
          ..write('ipAddress: $ipAddress, ')
          ..write('displayName: $displayName, ')
          ..write('macAddress: $macAddress, ')
          ..write('macStatus: $macStatus, ')
          ..write('vendor: $vendor, ')
          ..write('category: $category, ')
          ..write('confidence: $confidence, ')
          ..write('discoveryMethod: $discoveryMethod, ')
          ..write('servicesJson: $servicesJson, ')
          ..write('evidenceJson: $evidenceJson, ')
          ..write('wasNew: $wasNew')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    scanSessionId,
    stableKey,
    ipAddress,
    displayName,
    macAddress,
    macStatus,
    vendor,
    category,
    confidence,
    discoveryMethod,
    servicesJson,
    evidenceJson,
    wasNew,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScanObservation &&
          other.id == this.id &&
          other.scanSessionId == this.scanSessionId &&
          other.stableKey == this.stableKey &&
          other.ipAddress == this.ipAddress &&
          other.displayName == this.displayName &&
          other.macAddress == this.macAddress &&
          other.macStatus == this.macStatus &&
          other.vendor == this.vendor &&
          other.category == this.category &&
          other.confidence == this.confidence &&
          other.discoveryMethod == this.discoveryMethod &&
          other.servicesJson == this.servicesJson &&
          other.evidenceJson == this.evidenceJson &&
          other.wasNew == this.wasNew);
}

class ScanObservationsCompanion extends UpdateCompanion<ScanObservation> {
  final Value<int> id;
  final Value<int> scanSessionId;
  final Value<String> stableKey;
  final Value<String> ipAddress;
  final Value<String> displayName;
  final Value<String?> macAddress;
  final Value<String> macStatus;
  final Value<String?> vendor;
  final Value<String> category;
  final Value<String> confidence;
  final Value<String> discoveryMethod;
  final Value<String> servicesJson;
  final Value<String> evidenceJson;
  final Value<bool> wasNew;
  const ScanObservationsCompanion({
    this.id = const Value.absent(),
    this.scanSessionId = const Value.absent(),
    this.stableKey = const Value.absent(),
    this.ipAddress = const Value.absent(),
    this.displayName = const Value.absent(),
    this.macAddress = const Value.absent(),
    this.macStatus = const Value.absent(),
    this.vendor = const Value.absent(),
    this.category = const Value.absent(),
    this.confidence = const Value.absent(),
    this.discoveryMethod = const Value.absent(),
    this.servicesJson = const Value.absent(),
    this.evidenceJson = const Value.absent(),
    this.wasNew = const Value.absent(),
  });
  ScanObservationsCompanion.insert({
    this.id = const Value.absent(),
    required int scanSessionId,
    required String stableKey,
    required String ipAddress,
    required String displayName,
    this.macAddress = const Value.absent(),
    required String macStatus,
    this.vendor = const Value.absent(),
    required String category,
    required String confidence,
    required String discoveryMethod,
    required String servicesJson,
    required String evidenceJson,
    required bool wasNew,
  }) : scanSessionId = Value(scanSessionId),
       stableKey = Value(stableKey),
       ipAddress = Value(ipAddress),
       displayName = Value(displayName),
       macStatus = Value(macStatus),
       category = Value(category),
       confidence = Value(confidence),
       discoveryMethod = Value(discoveryMethod),
       servicesJson = Value(servicesJson),
       evidenceJson = Value(evidenceJson),
       wasNew = Value(wasNew);
  static Insertable<ScanObservation> custom({
    Expression<int>? id,
    Expression<int>? scanSessionId,
    Expression<String>? stableKey,
    Expression<String>? ipAddress,
    Expression<String>? displayName,
    Expression<String>? macAddress,
    Expression<String>? macStatus,
    Expression<String>? vendor,
    Expression<String>? category,
    Expression<String>? confidence,
    Expression<String>? discoveryMethod,
    Expression<String>? servicesJson,
    Expression<String>? evidenceJson,
    Expression<bool>? wasNew,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (scanSessionId != null) 'scan_session_id': scanSessionId,
      if (stableKey != null) 'stable_key': stableKey,
      if (ipAddress != null) 'ip_address': ipAddress,
      if (displayName != null) 'display_name': displayName,
      if (macAddress != null) 'mac_address': macAddress,
      if (macStatus != null) 'mac_status': macStatus,
      if (vendor != null) 'vendor': vendor,
      if (category != null) 'category': category,
      if (confidence != null) 'confidence': confidence,
      if (discoveryMethod != null) 'discovery_method': discoveryMethod,
      if (servicesJson != null) 'services_json': servicesJson,
      if (evidenceJson != null) 'evidence_json': evidenceJson,
      if (wasNew != null) 'was_new': wasNew,
    });
  }

  ScanObservationsCompanion copyWith({
    Value<int>? id,
    Value<int>? scanSessionId,
    Value<String>? stableKey,
    Value<String>? ipAddress,
    Value<String>? displayName,
    Value<String?>? macAddress,
    Value<String>? macStatus,
    Value<String?>? vendor,
    Value<String>? category,
    Value<String>? confidence,
    Value<String>? discoveryMethod,
    Value<String>? servicesJson,
    Value<String>? evidenceJson,
    Value<bool>? wasNew,
  }) {
    return ScanObservationsCompanion(
      id: id ?? this.id,
      scanSessionId: scanSessionId ?? this.scanSessionId,
      stableKey: stableKey ?? this.stableKey,
      ipAddress: ipAddress ?? this.ipAddress,
      displayName: displayName ?? this.displayName,
      macAddress: macAddress ?? this.macAddress,
      macStatus: macStatus ?? this.macStatus,
      vendor: vendor ?? this.vendor,
      category: category ?? this.category,
      confidence: confidence ?? this.confidence,
      discoveryMethod: discoveryMethod ?? this.discoveryMethod,
      servicesJson: servicesJson ?? this.servicesJson,
      evidenceJson: evidenceJson ?? this.evidenceJson,
      wasNew: wasNew ?? this.wasNew,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (scanSessionId.present) {
      map['scan_session_id'] = Variable<int>(scanSessionId.value);
    }
    if (stableKey.present) {
      map['stable_key'] = Variable<String>(stableKey.value);
    }
    if (ipAddress.present) {
      map['ip_address'] = Variable<String>(ipAddress.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (macAddress.present) {
      map['mac_address'] = Variable<String>(macAddress.value);
    }
    if (macStatus.present) {
      map['mac_status'] = Variable<String>(macStatus.value);
    }
    if (vendor.present) {
      map['vendor'] = Variable<String>(vendor.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<String>(confidence.value);
    }
    if (discoveryMethod.present) {
      map['discovery_method'] = Variable<String>(discoveryMethod.value);
    }
    if (servicesJson.present) {
      map['services_json'] = Variable<String>(servicesJson.value);
    }
    if (evidenceJson.present) {
      map['evidence_json'] = Variable<String>(evidenceJson.value);
    }
    if (wasNew.present) {
      map['was_new'] = Variable<bool>(wasNew.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScanObservationsCompanion(')
          ..write('id: $id, ')
          ..write('scanSessionId: $scanSessionId, ')
          ..write('stableKey: $stableKey, ')
          ..write('ipAddress: $ipAddress, ')
          ..write('displayName: $displayName, ')
          ..write('macAddress: $macAddress, ')
          ..write('macStatus: $macStatus, ')
          ..write('vendor: $vendor, ')
          ..write('category: $category, ')
          ..write('confidence: $confidence, ')
          ..write('discoveryMethod: $discoveryMethod, ')
          ..write('servicesJson: $servicesJson, ')
          ..write('evidenceJson: $evidenceJson, ')
          ..write('wasNew: $wasNew')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $KnownDevicesTable knownDevices = $KnownDevicesTable(this);
  late final $ScanSessionsTable scanSessions = $ScanSessionsTable(this);
  late final $ScanObservationsTable scanObservations = $ScanObservationsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    knownDevices,
    scanSessions,
    scanObservations,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'scan_sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('scan_observations', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$KnownDevicesTableCreateCompanionBuilder =
    KnownDevicesCompanion Function({
      required String stableKey,
      Value<String?> customName,
      Value<bool> isKnown,
      Value<String?> note,
      required DateTime firstSeenAt,
      required DateTime lastSeenAt,
      required String lastIpAddress,
      Value<String?> lastMacAddress,
      Value<String?> vendor,
      Value<int> rowid,
    });
typedef $$KnownDevicesTableUpdateCompanionBuilder =
    KnownDevicesCompanion Function({
      Value<String> stableKey,
      Value<String?> customName,
      Value<bool> isKnown,
      Value<String?> note,
      Value<DateTime> firstSeenAt,
      Value<DateTime> lastSeenAt,
      Value<String> lastIpAddress,
      Value<String?> lastMacAddress,
      Value<String?> vendor,
      Value<int> rowid,
    });

class $$KnownDevicesTableFilterComposer
    extends Composer<_$AppDatabase, $KnownDevicesTable> {
  $$KnownDevicesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get stableKey => $composableBuilder(
    column: $table.stableKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customName => $composableBuilder(
    column: $table.customName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isKnown => $composableBuilder(
    column: $table.isKnown,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get firstSeenAt => $composableBuilder(
    column: $table.firstSeenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastIpAddress => $composableBuilder(
    column: $table.lastIpAddress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastMacAddress => $composableBuilder(
    column: $table.lastMacAddress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vendor => $composableBuilder(
    column: $table.vendor,
    builder: (column) => ColumnFilters(column),
  );
}

class $$KnownDevicesTableOrderingComposer
    extends Composer<_$AppDatabase, $KnownDevicesTable> {
  $$KnownDevicesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get stableKey => $composableBuilder(
    column: $table.stableKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customName => $composableBuilder(
    column: $table.customName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isKnown => $composableBuilder(
    column: $table.isKnown,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get firstSeenAt => $composableBuilder(
    column: $table.firstSeenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastIpAddress => $composableBuilder(
    column: $table.lastIpAddress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastMacAddress => $composableBuilder(
    column: $table.lastMacAddress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vendor => $composableBuilder(
    column: $table.vendor,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KnownDevicesTableAnnotationComposer
    extends Composer<_$AppDatabase, $KnownDevicesTable> {
  $$KnownDevicesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get stableKey =>
      $composableBuilder(column: $table.stableKey, builder: (column) => column);

  GeneratedColumn<String> get customName => $composableBuilder(
    column: $table.customName,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isKnown =>
      $composableBuilder(column: $table.isKnown, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get firstSeenAt => $composableBuilder(
    column: $table.firstSeenAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastIpAddress => $composableBuilder(
    column: $table.lastIpAddress,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastMacAddress => $composableBuilder(
    column: $table.lastMacAddress,
    builder: (column) => column,
  );

  GeneratedColumn<String> get vendor =>
      $composableBuilder(column: $table.vendor, builder: (column) => column);
}

class $$KnownDevicesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $KnownDevicesTable,
          KnownDevice,
          $$KnownDevicesTableFilterComposer,
          $$KnownDevicesTableOrderingComposer,
          $$KnownDevicesTableAnnotationComposer,
          $$KnownDevicesTableCreateCompanionBuilder,
          $$KnownDevicesTableUpdateCompanionBuilder,
          (
            KnownDevice,
            BaseReferences<_$AppDatabase, $KnownDevicesTable, KnownDevice>,
          ),
          KnownDevice,
          PrefetchHooks Function()
        > {
  $$KnownDevicesTableTableManager(_$AppDatabase db, $KnownDevicesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KnownDevicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KnownDevicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KnownDevicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> stableKey = const Value.absent(),
                Value<String?> customName = const Value.absent(),
                Value<bool> isKnown = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> firstSeenAt = const Value.absent(),
                Value<DateTime> lastSeenAt = const Value.absent(),
                Value<String> lastIpAddress = const Value.absent(),
                Value<String?> lastMacAddress = const Value.absent(),
                Value<String?> vendor = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KnownDevicesCompanion(
                stableKey: stableKey,
                customName: customName,
                isKnown: isKnown,
                note: note,
                firstSeenAt: firstSeenAt,
                lastSeenAt: lastSeenAt,
                lastIpAddress: lastIpAddress,
                lastMacAddress: lastMacAddress,
                vendor: vendor,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String stableKey,
                Value<String?> customName = const Value.absent(),
                Value<bool> isKnown = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required DateTime firstSeenAt,
                required DateTime lastSeenAt,
                required String lastIpAddress,
                Value<String?> lastMacAddress = const Value.absent(),
                Value<String?> vendor = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KnownDevicesCompanion.insert(
                stableKey: stableKey,
                customName: customName,
                isKnown: isKnown,
                note: note,
                firstSeenAt: firstSeenAt,
                lastSeenAt: lastSeenAt,
                lastIpAddress: lastIpAddress,
                lastMacAddress: lastMacAddress,
                vendor: vendor,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$KnownDevicesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $KnownDevicesTable,
      KnownDevice,
      $$KnownDevicesTableFilterComposer,
      $$KnownDevicesTableOrderingComposer,
      $$KnownDevicesTableAnnotationComposer,
      $$KnownDevicesTableCreateCompanionBuilder,
      $$KnownDevicesTableUpdateCompanionBuilder,
      (
        KnownDevice,
        BaseReferences<_$AppDatabase, $KnownDevicesTable, KnownDevice>,
      ),
      KnownDevice,
      PrefetchHooks Function()
    >;
typedef $$ScanSessionsTableCreateCompanionBuilder =
    ScanSessionsCompanion Function({
      Value<int> id,
      required String networkKey,
      required DateTime startedAt,
      required DateTime completedAt,
      required String outcome,
      required String methodsJson,
      required int totalDeviceCount,
      required int newDeviceCount,
      required int missingDeviceCount,
      required String missingDevicesJson,
      required bool presenceComparable,
      required int elapsedMillis,
    });
typedef $$ScanSessionsTableUpdateCompanionBuilder =
    ScanSessionsCompanion Function({
      Value<int> id,
      Value<String> networkKey,
      Value<DateTime> startedAt,
      Value<DateTime> completedAt,
      Value<String> outcome,
      Value<String> methodsJson,
      Value<int> totalDeviceCount,
      Value<int> newDeviceCount,
      Value<int> missingDeviceCount,
      Value<String> missingDevicesJson,
      Value<bool> presenceComparable,
      Value<int> elapsedMillis,
    });

final class $$ScanSessionsTableReferences
    extends BaseReferences<_$AppDatabase, $ScanSessionsTable, ScanSession> {
  $$ScanSessionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ScanObservationsTable, List<ScanObservation>>
  _scanObservationsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.scanObservations,
    aliasName: $_aliasNameGenerator(
      db.scanSessions.id,
      db.scanObservations.scanSessionId,
    ),
  );

  $$ScanObservationsTableProcessedTableManager get scanObservationsRefs {
    final manager = $$ScanObservationsTableTableManager(
      $_db,
      $_db.scanObservations,
    ).filter((f) => f.scanSessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _scanObservationsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ScanSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $ScanSessionsTable> {
  $$ScanSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get networkKey => $composableBuilder(
    column: $table.networkKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get methodsJson => $composableBuilder(
    column: $table.methodsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalDeviceCount => $composableBuilder(
    column: $table.totalDeviceCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get newDeviceCount => $composableBuilder(
    column: $table.newDeviceCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get missingDeviceCount => $composableBuilder(
    column: $table.missingDeviceCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get missingDevicesJson => $composableBuilder(
    column: $table.missingDevicesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get presenceComparable => $composableBuilder(
    column: $table.presenceComparable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get elapsedMillis => $composableBuilder(
    column: $table.elapsedMillis,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> scanObservationsRefs(
    Expression<bool> Function($$ScanObservationsTableFilterComposer f) f,
  ) {
    final $$ScanObservationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scanObservations,
      getReferencedColumn: (t) => t.scanSessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScanObservationsTableFilterComposer(
            $db: $db,
            $table: $db.scanObservations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ScanSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ScanSessionsTable> {
  $$ScanSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get networkKey => $composableBuilder(
    column: $table.networkKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get methodsJson => $composableBuilder(
    column: $table.methodsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalDeviceCount => $composableBuilder(
    column: $table.totalDeviceCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get newDeviceCount => $composableBuilder(
    column: $table.newDeviceCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get missingDeviceCount => $composableBuilder(
    column: $table.missingDeviceCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get missingDevicesJson => $composableBuilder(
    column: $table.missingDevicesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get presenceComparable => $composableBuilder(
    column: $table.presenceComparable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get elapsedMillis => $composableBuilder(
    column: $table.elapsedMillis,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ScanSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScanSessionsTable> {
  $$ScanSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get networkKey => $composableBuilder(
    column: $table.networkKey,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get outcome =>
      $composableBuilder(column: $table.outcome, builder: (column) => column);

  GeneratedColumn<String> get methodsJson => $composableBuilder(
    column: $table.methodsJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalDeviceCount => $composableBuilder(
    column: $table.totalDeviceCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get newDeviceCount => $composableBuilder(
    column: $table.newDeviceCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get missingDeviceCount => $composableBuilder(
    column: $table.missingDeviceCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get missingDevicesJson => $composableBuilder(
    column: $table.missingDevicesJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get presenceComparable => $composableBuilder(
    column: $table.presenceComparable,
    builder: (column) => column,
  );

  GeneratedColumn<int> get elapsedMillis => $composableBuilder(
    column: $table.elapsedMillis,
    builder: (column) => column,
  );

  Expression<T> scanObservationsRefs<T extends Object>(
    Expression<T> Function($$ScanObservationsTableAnnotationComposer a) f,
  ) {
    final $$ScanObservationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scanObservations,
      getReferencedColumn: (t) => t.scanSessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScanObservationsTableAnnotationComposer(
            $db: $db,
            $table: $db.scanObservations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ScanSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ScanSessionsTable,
          ScanSession,
          $$ScanSessionsTableFilterComposer,
          $$ScanSessionsTableOrderingComposer,
          $$ScanSessionsTableAnnotationComposer,
          $$ScanSessionsTableCreateCompanionBuilder,
          $$ScanSessionsTableUpdateCompanionBuilder,
          (ScanSession, $$ScanSessionsTableReferences),
          ScanSession,
          PrefetchHooks Function({bool scanObservationsRefs})
        > {
  $$ScanSessionsTableTableManager(_$AppDatabase db, $ScanSessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScanSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScanSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScanSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> networkKey = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime> completedAt = const Value.absent(),
                Value<String> outcome = const Value.absent(),
                Value<String> methodsJson = const Value.absent(),
                Value<int> totalDeviceCount = const Value.absent(),
                Value<int> newDeviceCount = const Value.absent(),
                Value<int> missingDeviceCount = const Value.absent(),
                Value<String> missingDevicesJson = const Value.absent(),
                Value<bool> presenceComparable = const Value.absent(),
                Value<int> elapsedMillis = const Value.absent(),
              }) => ScanSessionsCompanion(
                id: id,
                networkKey: networkKey,
                startedAt: startedAt,
                completedAt: completedAt,
                outcome: outcome,
                methodsJson: methodsJson,
                totalDeviceCount: totalDeviceCount,
                newDeviceCount: newDeviceCount,
                missingDeviceCount: missingDeviceCount,
                missingDevicesJson: missingDevicesJson,
                presenceComparable: presenceComparable,
                elapsedMillis: elapsedMillis,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String networkKey,
                required DateTime startedAt,
                required DateTime completedAt,
                required String outcome,
                required String methodsJson,
                required int totalDeviceCount,
                required int newDeviceCount,
                required int missingDeviceCount,
                required String missingDevicesJson,
                required bool presenceComparable,
                required int elapsedMillis,
              }) => ScanSessionsCompanion.insert(
                id: id,
                networkKey: networkKey,
                startedAt: startedAt,
                completedAt: completedAt,
                outcome: outcome,
                methodsJson: methodsJson,
                totalDeviceCount: totalDeviceCount,
                newDeviceCount: newDeviceCount,
                missingDeviceCount: missingDeviceCount,
                missingDevicesJson: missingDevicesJson,
                presenceComparable: presenceComparable,
                elapsedMillis: elapsedMillis,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ScanSessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({scanObservationsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (scanObservationsRefs) db.scanObservations,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (scanObservationsRefs)
                    await $_getPrefetchedData<
                      ScanSession,
                      $ScanSessionsTable,
                      ScanObservation
                    >(
                      currentTable: table,
                      referencedTable: $$ScanSessionsTableReferences
                          ._scanObservationsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ScanSessionsTableReferences(
                            db,
                            table,
                            p0,
                          ).scanObservationsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.scanSessionId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ScanSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ScanSessionsTable,
      ScanSession,
      $$ScanSessionsTableFilterComposer,
      $$ScanSessionsTableOrderingComposer,
      $$ScanSessionsTableAnnotationComposer,
      $$ScanSessionsTableCreateCompanionBuilder,
      $$ScanSessionsTableUpdateCompanionBuilder,
      (ScanSession, $$ScanSessionsTableReferences),
      ScanSession,
      PrefetchHooks Function({bool scanObservationsRefs})
    >;
typedef $$ScanObservationsTableCreateCompanionBuilder =
    ScanObservationsCompanion Function({
      Value<int> id,
      required int scanSessionId,
      required String stableKey,
      required String ipAddress,
      required String displayName,
      Value<String?> macAddress,
      required String macStatus,
      Value<String?> vendor,
      required String category,
      required String confidence,
      required String discoveryMethod,
      required String servicesJson,
      required String evidenceJson,
      required bool wasNew,
    });
typedef $$ScanObservationsTableUpdateCompanionBuilder =
    ScanObservationsCompanion Function({
      Value<int> id,
      Value<int> scanSessionId,
      Value<String> stableKey,
      Value<String> ipAddress,
      Value<String> displayName,
      Value<String?> macAddress,
      Value<String> macStatus,
      Value<String?> vendor,
      Value<String> category,
      Value<String> confidence,
      Value<String> discoveryMethod,
      Value<String> servicesJson,
      Value<String> evidenceJson,
      Value<bool> wasNew,
    });

final class $$ScanObservationsTableReferences
    extends
        BaseReferences<_$AppDatabase, $ScanObservationsTable, ScanObservation> {
  $$ScanObservationsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ScanSessionsTable _scanSessionIdTable(_$AppDatabase db) =>
      db.scanSessions.createAlias(
        $_aliasNameGenerator(
          db.scanObservations.scanSessionId,
          db.scanSessions.id,
        ),
      );

  $$ScanSessionsTableProcessedTableManager get scanSessionId {
    final $_column = $_itemColumn<int>('scan_session_id')!;

    final manager = $$ScanSessionsTableTableManager(
      $_db,
      $_db.scanSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_scanSessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ScanObservationsTableFilterComposer
    extends Composer<_$AppDatabase, $ScanObservationsTable> {
  $$ScanObservationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stableKey => $composableBuilder(
    column: $table.stableKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ipAddress => $composableBuilder(
    column: $table.ipAddress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get macAddress => $composableBuilder(
    column: $table.macAddress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get macStatus => $composableBuilder(
    column: $table.macStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vendor => $composableBuilder(
    column: $table.vendor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get discoveryMethod => $composableBuilder(
    column: $table.discoveryMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get servicesJson => $composableBuilder(
    column: $table.servicesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get evidenceJson => $composableBuilder(
    column: $table.evidenceJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get wasNew => $composableBuilder(
    column: $table.wasNew,
    builder: (column) => ColumnFilters(column),
  );

  $$ScanSessionsTableFilterComposer get scanSessionId {
    final $$ScanSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scanSessionId,
      referencedTable: $db.scanSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScanSessionsTableFilterComposer(
            $db: $db,
            $table: $db.scanSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScanObservationsTableOrderingComposer
    extends Composer<_$AppDatabase, $ScanObservationsTable> {
  $$ScanObservationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stableKey => $composableBuilder(
    column: $table.stableKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ipAddress => $composableBuilder(
    column: $table.ipAddress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get macAddress => $composableBuilder(
    column: $table.macAddress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get macStatus => $composableBuilder(
    column: $table.macStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vendor => $composableBuilder(
    column: $table.vendor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get discoveryMethod => $composableBuilder(
    column: $table.discoveryMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get servicesJson => $composableBuilder(
    column: $table.servicesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get evidenceJson => $composableBuilder(
    column: $table.evidenceJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get wasNew => $composableBuilder(
    column: $table.wasNew,
    builder: (column) => ColumnOrderings(column),
  );

  $$ScanSessionsTableOrderingComposer get scanSessionId {
    final $$ScanSessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scanSessionId,
      referencedTable: $db.scanSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScanSessionsTableOrderingComposer(
            $db: $db,
            $table: $db.scanSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScanObservationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScanObservationsTable> {
  $$ScanObservationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get stableKey =>
      $composableBuilder(column: $table.stableKey, builder: (column) => column);

  GeneratedColumn<String> get ipAddress =>
      $composableBuilder(column: $table.ipAddress, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get macAddress => $composableBuilder(
    column: $table.macAddress,
    builder: (column) => column,
  );

  GeneratedColumn<String> get macStatus =>
      $composableBuilder(column: $table.macStatus, builder: (column) => column);

  GeneratedColumn<String> get vendor =>
      $composableBuilder(column: $table.vendor, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get discoveryMethod => $composableBuilder(
    column: $table.discoveryMethod,
    builder: (column) => column,
  );

  GeneratedColumn<String> get servicesJson => $composableBuilder(
    column: $table.servicesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get evidenceJson => $composableBuilder(
    column: $table.evidenceJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get wasNew =>
      $composableBuilder(column: $table.wasNew, builder: (column) => column);

  $$ScanSessionsTableAnnotationComposer get scanSessionId {
    final $$ScanSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scanSessionId,
      referencedTable: $db.scanSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScanSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.scanSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScanObservationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ScanObservationsTable,
          ScanObservation,
          $$ScanObservationsTableFilterComposer,
          $$ScanObservationsTableOrderingComposer,
          $$ScanObservationsTableAnnotationComposer,
          $$ScanObservationsTableCreateCompanionBuilder,
          $$ScanObservationsTableUpdateCompanionBuilder,
          (ScanObservation, $$ScanObservationsTableReferences),
          ScanObservation,
          PrefetchHooks Function({bool scanSessionId})
        > {
  $$ScanObservationsTableTableManager(
    _$AppDatabase db,
    $ScanObservationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScanObservationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScanObservationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScanObservationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> scanSessionId = const Value.absent(),
                Value<String> stableKey = const Value.absent(),
                Value<String> ipAddress = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String?> macAddress = const Value.absent(),
                Value<String> macStatus = const Value.absent(),
                Value<String?> vendor = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> confidence = const Value.absent(),
                Value<String> discoveryMethod = const Value.absent(),
                Value<String> servicesJson = const Value.absent(),
                Value<String> evidenceJson = const Value.absent(),
                Value<bool> wasNew = const Value.absent(),
              }) => ScanObservationsCompanion(
                id: id,
                scanSessionId: scanSessionId,
                stableKey: stableKey,
                ipAddress: ipAddress,
                displayName: displayName,
                macAddress: macAddress,
                macStatus: macStatus,
                vendor: vendor,
                category: category,
                confidence: confidence,
                discoveryMethod: discoveryMethod,
                servicesJson: servicesJson,
                evidenceJson: evidenceJson,
                wasNew: wasNew,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int scanSessionId,
                required String stableKey,
                required String ipAddress,
                required String displayName,
                Value<String?> macAddress = const Value.absent(),
                required String macStatus,
                Value<String?> vendor = const Value.absent(),
                required String category,
                required String confidence,
                required String discoveryMethod,
                required String servicesJson,
                required String evidenceJson,
                required bool wasNew,
              }) => ScanObservationsCompanion.insert(
                id: id,
                scanSessionId: scanSessionId,
                stableKey: stableKey,
                ipAddress: ipAddress,
                displayName: displayName,
                macAddress: macAddress,
                macStatus: macStatus,
                vendor: vendor,
                category: category,
                confidence: confidence,
                discoveryMethod: discoveryMethod,
                servicesJson: servicesJson,
                evidenceJson: evidenceJson,
                wasNew: wasNew,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ScanObservationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({scanSessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (scanSessionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.scanSessionId,
                                referencedTable:
                                    $$ScanObservationsTableReferences
                                        ._scanSessionIdTable(db),
                                referencedColumn:
                                    $$ScanObservationsTableReferences
                                        ._scanSessionIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ScanObservationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ScanObservationsTable,
      ScanObservation,
      $$ScanObservationsTableFilterComposer,
      $$ScanObservationsTableOrderingComposer,
      $$ScanObservationsTableAnnotationComposer,
      $$ScanObservationsTableCreateCompanionBuilder,
      $$ScanObservationsTableUpdateCompanionBuilder,
      (ScanObservation, $$ScanObservationsTableReferences),
      ScanObservation,
      PrefetchHooks Function({bool scanSessionId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$KnownDevicesTableTableManager get knownDevices =>
      $$KnownDevicesTableTableManager(_db, _db.knownDevices);
  $$ScanSessionsTableTableManager get scanSessions =>
      $$ScanSessionsTableTableManager(_db, _db.scanSessions);
  $$ScanObservationsTableTableManager get scanObservations =>
      $$ScanObservationsTableTableManager(_db, _db.scanObservations);
}
