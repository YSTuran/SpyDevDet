import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class MacAddress {
  const MacAddress._(this.value, this.isLocallyAdministered);

  final String value;
  final bool isLocallyAdministered;

  String get oui => value.substring(0, 8);
  String get compact => value.replaceAll(':', '');

  static MacAddress? tryParse(String input) {
    final compact = input.replaceAll(RegExp(r'[-:.\s]'), '').toUpperCase();
    if (!RegExp(r'^[0-9A-F]{12}$').hasMatch(compact) ||
        compact == '000000000000' ||
        compact == 'FFFFFFFFFFFF') {
      return null;
    }
    final firstOctet = int.parse(compact.substring(0, 2), radix: 16);
    if ((firstOctet & 1) != 0) {
      return null;
    }
    final canonical = List.generate(
      6,
      (index) => compact.substring(index * 2, index * 2 + 2),
    ).join(':');
    return MacAddress._(canonical, (firstOctet & 2) != 0);
  }
}

class MacVendorDatabaseStatus {
  const MacVendorDatabaseStatus({
    required this.loaded,
    required this.entryCount,
    required this.description,
  });

  final bool loaded;
  final int entryCount;
  final String description;
}

abstract interface class MacVendorLookup {
  Future<MacVendorDatabaseStatus> load();

  String? lookup(MacAddress address);
}

class MacVendorRepository implements MacVendorLookup {
  const MacVendorRepository();

  static const _knownVendors = <String, String>{
    '00:17:88': 'Philips Lighting',
    '00:1A:11': 'Google',
    '18:B4:30': 'Nest Labs',
    '44:65:0D': 'Amazon Technologies',
    'B8:27:EB': 'Raspberry Pi Foundation',
    'DC:A6:32': 'Raspberry Pi Trading',
  };

  @override
  Future<MacVendorDatabaseStatus> load() async => const MacVendorDatabaseStatus(
    loaded: true,
    entryCount: 6,
    description: 'Gömülü yedek üretici listesi',
  );

  @override
  String? lookup(MacAddress address) {
    if (address.isLocallyAdministered) {
      return null;
    }
    return _knownVendors[address.oui];
  }
}

class AssetMacVendorRepository implements MacVendorLookup {
  const AssetMacVendorRepository({
    this.assetPath = 'assets/data/oui_registry.tsv',
    this.fallback = const MacVendorRepository(),
  });

  final String assetPath;
  final MacVendorRepository fallback;

  static Future<MacVendorDatabaseStatus>? _sharedLoad;
  static Map<int, String> _prefix24 = const {};
  static Map<int, String> _prefix28 = const {};
  static Map<int, String> _prefix36 = const {};

  @override
  Future<MacVendorDatabaseStatus> load() => _sharedLoad ??= _loadFromAsset();

  Future<MacVendorDatabaseStatus> _loadFromAsset() async {
    try {
      final source = await rootBundle.loadString(assetPath);
      final parsed = await compute(_parseOuiRegistry, source);
      final prefix24 = (parsed['prefix24']! as Map).cast<int, String>();
      final prefix28 = (parsed['prefix28']! as Map).cast<int, String>();
      final prefix36 = (parsed['prefix36']! as Map).cast<int, String>();
      final snapshotDate = parsed['snapshotDate'] as String?;
      final entryCount = prefix24.length + prefix28.length + prefix36.length;
      if (entryCount < 1000) {
        return const MacVendorDatabaseStatus(
          loaded: false,
          entryCount: 6,
          description: 'OUI asset yüklenemedi; gömülü yedek liste kullanılıyor',
        );
      }
      _prefix24 = Map.unmodifiable(prefix24);
      _prefix28 = Map.unmodifiable(prefix28);
      _prefix36 = Map.unmodifiable(prefix36);
      return MacVendorDatabaseStatus(
        loaded: true,
        entryCount: entryCount,
        description: snapshotDate == null || snapshotDate.isEmpty
            ? 'Çevrimdışı IEEE OUI kayıtları'
            : 'Çevrimdışı IEEE OUI kayıtları • snapshot $snapshotDate',
      );
    } on Object {
      return const MacVendorDatabaseStatus(
        loaded: false,
        entryCount: 6,
        description: 'OUI asset yüklenemedi; gömülü yedek liste kullanılıyor',
      );
    }
  }

  @override
  String? lookup(MacAddress address) {
    if (address.isLocallyAdministered) {
      return null;
    }
    final value = int.parse(address.compact, radix: 16);
    return _prefix36[value >> 12] ??
        _prefix28[value >> 20] ??
        _prefix24[value >> 24] ??
        fallback.lookup(address);
  }
}

Map<String, Object?> _parseOuiRegistry(String source) {
  final prefix24 = <int, String>{};
  final prefix28 = <int, String>{};
  final prefix36 = <int, String>{};
  String? snapshotDate;
  for (final line in source.split(RegExp(r'\r?\n'))) {
    if (line.startsWith('# Updated:')) {
      snapshotDate = line
          .substring('# Updated:'.length)
          .trim()
          .split('T')
          .first;
      continue;
    }
    if (line.isEmpty || line.startsWith('#')) {
      continue;
    }
    final columns = line.split('\t');
    if (columns.length != 3) {
      continue;
    }
    final length = int.tryParse(columns[0]);
    final prefix = int.tryParse(columns[1], radix: 16);
    final vendor = columns[2].trim();
    if (length == null || prefix == null || vendor.isEmpty) {
      continue;
    }
    switch (length) {
      case 24:
        prefix24[prefix] = vendor;
      case 28:
        prefix28[prefix] = vendor;
      case 36:
        prefix36[prefix] = vendor;
    }
  }
  return {
    'prefix24': prefix24,
    'prefix28': prefix28,
    'prefix36': prefix36,
    'snapshotDate': snapshotDate,
  };
}
