final class Ipv4Address {
  const Ipv4Address._();

  static const int maxValue = 0xffffffff;

  static int parse(String value) {
    final parts = value.split('.');
    if (parts.length != 4) {
      throw const FormatException('IPv4 adresi dört parçadan oluşmalıdır.');
    }

    var result = 0;
    for (final part in parts) {
      if (part.isEmpty || part.length > 3 || !_containsOnlyDigits(part)) {
        throw const FormatException('Geçersiz IPv4 adresi.');
      }

      final octet = int.parse(part);
      if (octet > 255) {
        throw const FormatException('IPv4 parçası 255 değerini aşamaz.');
      }
      result = (result << 8) | octet;
    }
    return result;
  }

  static String format(int value) {
    if (value < 0 || value > maxValue) {
      throw RangeError.range(value, 0, maxValue, 'value');
    }

    return [
      (value >> 24) & 0xff,
      (value >> 16) & 0xff,
      (value >> 8) & 0xff,
      value & 0xff,
    ].join('.');
  }

  static int maskForPrefix(int prefixLength) {
    if (prefixLength < 0 || prefixLength > 32) {
      throw RangeError.range(prefixLength, 0, 32, 'prefixLength');
    }
    if (prefixLength == 0) {
      return 0;
    }
    return (maxValue << (32 - prefixLength)) & maxValue;
  }

  static bool isPrivate(int value) {
    final first = (value >> 24) & 0xff;
    final second = (value >> 16) & 0xff;
    return first == 10 ||
        (first == 172 && second >= 16 && second <= 31) ||
        (first == 192 && second == 168);
  }

  static int minimumPrivatePrefix(int value) {
    final first = (value >> 24) & 0xff;
    final second = (value >> 16) & 0xff;
    if (first == 10) {
      return 8;
    }
    if (first == 172 && second >= 16 && second <= 31) {
      return 12;
    }
    if (first == 192 && second == 168) {
      return 16;
    }
    throw const FormatException('Adres özel bir IPv4 aralığında değil.');
  }

  static int compare(String first, String second) {
    return parse(first).compareTo(parse(second));
  }

  static bool _containsOnlyDigits(String value) {
    for (final codeUnit in value.codeUnits) {
      if (codeUnit < 48 || codeUnit > 57) {
        return false;
      }
    }
    return true;
  }
}
