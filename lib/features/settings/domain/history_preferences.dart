class HistoryPreferences {
  const HistoryPreferences({this.maxScansPerNetwork = 100});

  static const supportedLimits = [25, 50, 100];

  final int maxScansPerNetwork;

  HistoryPreferences copyWith({int? maxScansPerNetwork}) => HistoryPreferences(
    maxScansPerNetwork: maxScansPerNetwork ?? this.maxScansPerNetwork,
  );
}
