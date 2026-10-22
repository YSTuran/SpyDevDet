import 'package:flutter/material.dart';
import 'package:spy_dev_det/features/history/domain/scan_history_repository.dart';
import 'package:spy_dev_det/features/history/presentation/history_formatters.dart';
import 'package:spy_dev_det/features/history/presentation/reference_comparison_card.dart';

class ScanComparisonScreen extends StatelessWidget {
  const ScanComparisonScreen({required this.result, super.key});

  final SelectedScanComparison result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tarama karşılaştırması')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Seçilen taramalar',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        _ComparisonLine(
                          label: 'Temel tarama',
                          value: formatHistoryDateTime(
                            result.baseline.completedAt,
                          ),
                        ),
                        _ComparisonLine(
                          label: 'Güncel tarama',
                          value: formatHistoryDateTime(
                            result.current.completedAt,
                          ),
                        ),
                        _ComparisonLine(
                          label: 'Temel cihaz sayısı',
                          value: '${result.baseline.totalDeviceCount}',
                        ),
                        _ComparisonLine(
                          label: 'Güncel cihaz sayısı',
                          value: '${result.current.totalDeviceCount}',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ReferenceComparisonCard(comparison: result.comparison),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ComparisonLine extends StatelessWidget {
  const _ComparisonLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Text('$label: $value'),
  );
}
