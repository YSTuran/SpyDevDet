final class NetworkTextSanitizer {
  const NetworkTextSanitizer._();

  static String sanitize(String value, {required int maxRunes}) {
    if (maxRunes < 1) {
      throw RangeError.value(maxRunes, 'maxRunes', 'Pozitif olmalıdır.');
    }

    return String.fromCharCodes(
      value.runes.where((codePoint) => !_isUnsafe(codePoint)).take(maxRunes),
    ).trim();
  }

  static bool _isUnsafe(int codePoint) =>
      codePoint <= 0x1f ||
      codePoint >= 0x7f && codePoint <= 0x9f ||
      codePoint == 0x00ad ||
      codePoint == 0x034f ||
      codePoint == 0x061c ||
      codePoint == 0x115f ||
      codePoint == 0x1160 ||
      codePoint == 0x17b4 ||
      codePoint == 0x17b5 ||
      codePoint == 0x180e ||
      codePoint >= 0x200b && codePoint <= 0x200f ||
      codePoint >= 0x2028 && codePoint <= 0x202e ||
      codePoint >= 0x2060 && codePoint <= 0x206f ||
      codePoint == 0x3164 ||
      codePoint == 0xfeff ||
      codePoint == 0xffa0 ||
      codePoint == 0xe0001 ||
      codePoint >= 0xe0020 && codePoint <= 0xe007f;
}
