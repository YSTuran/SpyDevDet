class MacAddress {
  const MacAddress._(this.value, this.isLocallyAdministered);

  final String value;
  final bool isLocallyAdministered;

  String get oui => value.substring(0, 8);

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

class MacVendorRepository {
  const MacVendorRepository();

  static const _knownVendors = <String, String>{
    '00:17:88': 'Philips Lighting',
    '00:1A:11': 'Google',
    '18:B4:30': 'Nest Labs',
    '44:65:0D': 'Amazon Technologies',
    'B8:27:EB': 'Raspberry Pi Foundation',
    'DC:A6:32': 'Raspberry Pi Trading',
  };

  String? lookup(MacAddress address) {
    if (address.isLocallyAdministered) {
      return null;
    }
    return _knownVendors[address.oui];
  }
}
