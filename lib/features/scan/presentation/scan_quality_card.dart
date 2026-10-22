import 'package:flutter/material.dart';
import 'package:spy_dev_det/features/scan/domain/scan_quality.dart';

class ScanQualityCard extends StatelessWidget {
  const ScanQualityCard({required this.assessment, super.key});

  final ScanQualityAssessment assessment;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (assessment.level) {
      ScanQualityLevel.comprehensive => (
        Icons.verified_outlined,
        Theme.of(context).colorScheme.primary,
      ),
      ScanQualityLevel.limited => (
        Icons.info_outline,
        Theme.of(context).colorScheme.tertiary,
      ),
      ScanQualityLevel.insufficient => (
        Icons.warning_amber_outlined,
        Theme.of(context).colorScheme.error,
      ),
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tarama kalitesi: ${assessment.level.label}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(assessment.level.description),
            if (assessment.reasons.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...assessment.reasons.map(
                (reason) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• $reason'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
