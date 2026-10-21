String formatHistoryDateTime(DateTime value) {
  final local = value.toLocal();
  String twoDigits(int number) => number.toString().padLeft(2, '0');
  return '${twoDigits(local.day)}.${twoDigits(local.month)}.${local.year} '
      '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
}

String formatHistoryDuration(Duration value) {
  final seconds = value.inMilliseconds / 1000;
  return '${seconds.toStringAsFixed(1)} sn';
}
