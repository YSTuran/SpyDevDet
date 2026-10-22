import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spy_dev_det/features/history/application/history_providers.dart';
import 'package:spy_dev_det/features/history/domain/scan_history_repository.dart';
import 'package:spy_dev_det/features/history/presentation/history_formatters.dart';
import 'package:spy_dev_det/features/history/presentation/scan_comparison_screen.dart';

Future<void> openScanComparisonFlow(
  BuildContext context,
  WidgetRef ref, {
  String? networkKey,
}) async {
  try {
    final repository = ref.read(scanHistoryRepositoryProvider);
    final history = (await repository.getHistory(
      limit: 200,
      networkKey: networkKey,
    )).where((item) => item.isPresenceComparable).toList(growable: false);
    final profiles = await repository.getNetworkProfiles();
    final networkNames = {
      for (final profile in profiles) profile.networkKey: profile.displayName,
    };
    final groups = <String, List<ScanHistorySummary>>{};
    for (final item in history) {
      groups.putIfAbsent(item.networkKey, () => []).add(item);
    }
    final eligibleGroups = groups.entries
        .where((entry) => entry.value.length >= 2)
        .toList(growable: false);
    if (eligibleGroups.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aynı ağda en az iki tam kapsamlı tarama gerekiyor.'),
          ),
        );
      }
      return;
    }
    final initialGroup = eligibleGroups.first.value;
    var baselineId = initialGroup.last.id;
    var currentId = initialGroup.first.id;
    if (!context.mounted) return;
    final selection = await showDialog<({int first, int second})>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final baseline = history.singleWhere((item) => item.id == baselineId);
          final currentCandidates = history
              .where(
                (item) =>
                    item.networkKey == baseline.networkKey &&
                    item.id != baselineId,
              )
              .toList(growable: false);
          if (!currentCandidates.any((item) => item.id == currentId)) {
            currentId = currentCandidates.first.id;
          }
          String label(ScanHistorySummary item) =>
              '${networkNames[item.networkKey] ?? 'Yerel ağ'} • '
              '${formatHistoryDateTime(item.completedAt)}';
          return AlertDialog(
            title: const Text('Taramaları karşılaştır'),
            content: SizedBox(
              width: 520,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: baselineId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Temel tarama',
                    ),
                    items: history
                        .where(
                          (item) => (groups[item.networkKey]?.length ?? 0) >= 2,
                        )
                        .map(
                          (item) => DropdownMenuItem(
                            value: item.id,
                            child: Text(
                              label(item),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() {
                        baselineId = value;
                        final selected = history.singleWhere(
                          (item) => item.id == value,
                        );
                        currentId = history
                            .firstWhere(
                              (item) =>
                                  item.networkKey == selected.networkKey &&
                                  item.id != value,
                            )
                            .id;
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<int>(
                    key: ValueKey('$baselineId-$currentId'),
                    initialValue: currentId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Diğer tarama',
                    ),
                    items: currentCandidates
                        .map(
                          (item) => DropdownMenuItem(
                            value: item.id,
                            child: Text(
                              label(item),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => currentId = value);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Vazgeç'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pop(dialogContext, (
                  first: baselineId,
                  second: currentId,
                )),
                icon: const Icon(Icons.compare_arrows),
                label: const Text('Karşılaştır'),
              ),
            ],
          );
        },
      ),
    );
    if (selection == null || !context.mounted) return;
    final comparison = await repository.compareSessions(
      firstSessionId: selection.first,
      secondSessionId: selection.second,
    );
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ScanComparisonScreen(result: comparison),
      ),
    );
  } on Object catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Karşılaştırma yapılamadı: $error')),
      );
    }
  }
}
