import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spy_dev_det/features/history/application/history_providers.dart';
import 'package:spy_dev_det/features/history/domain/reference_scan_comparison.dart';
import 'package:spy_dev_det/features/history/domain/scan_history_repository.dart';
import 'package:spy_dev_det/features/history/presentation/history_formatters.dart';
import 'package:spy_dev_det/features/scan/domain/device_evidence.dart';
import 'package:spy_dev_det/features/scan/domain/device_observation.dart';

class DeviceTimelineScreen extends ConsumerWidget {
  const DeviceTimelineScreen({
    required this.stableKey,
    this.initialTitle,
    super.key,
  });

  final String stableKey;
  final String? initialTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeline = ref.watch(deviceTimelineProvider(stableKey));
    return Scaffold(
      appBar: AppBar(title: Text(initialTitle ?? 'Cihaz geçmişi')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: timeline.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => _TimelineMessage(
                icon: Icons.error_outline,
                message: 'Cihaz geçmişi okunamadı.',
                action: OutlinedButton.icon(
                  onPressed: () =>
                      ref.invalidate(deviceTimelineProvider(stableKey)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tekrar dene'),
                ),
              ),
              data: (value) => value == null
                  ? const _TimelineMessage(
                      icon: Icons.search_off,
                      message: 'Cihaz profili artık bulunamıyor.',
                    )
                  : _TimelineView(timeline: value),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimelineView extends StatelessWidget {
  const _TimelineView({required this.timeline});

  final DeviceTimeline timeline;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timeline.device.effectiveDisplayName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'İlk görülme: '
                  '${formatHistoryDateTime(timeline.device.firstSeenAt)}',
                ),
                Text(
                  'Son görülme: '
                  '${formatHistoryDateTime(timeline.device.lastSeenAt)}',
                ),
                Text('${timeline.observedScanCount} taramada gözlemlendi'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      label: Text(
                        timeline.device.isKnown ? 'Bilinen' : 'Tanımlanmadı',
                      ),
                    ),
                    if (timeline.device.isOwned)
                      const Chip(label: Text('Bana ait')),
                    if (timeline.device.categoryOverride != null)
                      Chip(
                        label: Text(
                          'Tür: ${timeline.device.categoryOverride!.label}',
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text('Zaman çizelgesi', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(
          'Yalnız cihazın gözlemlendiği veya karşılaştırılabilir bir taramada '
          'görülmediği kayıtlar gösterilir.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 10),
        if (timeline.entries.isEmpty)
          const _TimelineMessage(
            icon: Icons.history_toggle_off,
            message: 'Saklanan taramalarda bu cihaz için ayrıntı bulunamadı.',
          )
        else
          for (var index = 0; index < timeline.entries.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _TimelineEntryCard(
                entry: timeline.entries[index],
                changes: _changesFromPrevious(index),
              ),
            ),
      ],
    );
  }

  List<String> _changesFromPrevious(int currentIndex) {
    final current = timeline.entries[currentIndex].observation;
    if (current == null) return const [];
    DeviceObservation? previous;
    for (
      var index = currentIndex + 1;
      index < timeline.entries.length;
      index++
    ) {
      previous = timeline.entries[index].observation;
      if (previous != null) break;
    }
    if (previous == null) return const [];
    final changes = <String>[];
    if (current.ipAddress != previous.ipAddress) {
      changes.add('IP: ${previous.ipAddress} → ${current.ipAddress}');
    }
    final previousServices = previous.services.toSet();
    final currentServices = current.services.toSet();
    final added = currentServices.difference(previousServices).toList()..sort();
    final removed = previousServices.difference(currentServices).toList()
      ..sort();
    if (added.isNotEmpty) changes.add('Eklenen servis: ${added.join(', ')}');
    if (removed.isNotEmpty) {
      changes.add('Kaldırılan servis: ${removed.join(', ')}');
    }
    if ((previous.vendor ?? '') != (current.vendor ?? '')) {
      changes.add(
        'Üretici: ${previous.vendor ?? 'Bilinmiyor'} → '
        '${current.vendor ?? 'Bilinmiyor'}',
      );
    }
    if (previous.category != current.category) {
      changes.add(
        'Tür: ${previous.category.label} → ${current.category.label}',
      );
    }
    if (previous.confidence != current.confidence) {
      changes.add(
        'Güven: ${previous.confidence.label} → ${current.confidence.label}',
      );
    }
    final comparator = const ReferenceScanComparator();
    final previousIdentity = comparator.identityQuality(previous);
    final currentIdentity = comparator.identityQuality(current);
    if (previousIdentity != currentIdentity) {
      changes.add(
        'Kimlik: ${previousIdentity.label} → ${currentIdentity.label}',
      );
    }
    return List.unmodifiable(changes);
  }
}

class _TimelineEntryCard extends StatelessWidget {
  const _TimelineEntryCard({required this.entry, required this.changes});

  final DeviceTimelineEntry entry;
  final List<String> changes;

  @override
  Widget build(BuildContext context) {
    final observation = entry.observation;
    final missing = entry.presence == DeviceTimelinePresence.missing;
    return Card(
      child: ExpansionTile(
        leading: Icon(
          missing ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        ),
        title: Text(formatHistoryDateTime(entry.completedAt)),
        subtitle: Text(
          '${entry.networkDisplayName} • '
          '${missing ? 'Bu taramada görülmedi' : 'Gözlemlendi'}',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          if (missing)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Son bilinen IP: ${entry.lastKnownIpAddress ?? 'Bilinmiyor'}',
              ),
            )
          else if (observation != null) ...[
            _TimelineLine(label: 'IP', value: observation.ipAddress),
            _TimelineLine(
              label: 'Tür',
              value: observation.effectiveCategory.label,
            ),
            _TimelineLine(label: 'Güven', value: observation.confidence.label),
            _TimelineLine(
              label: 'Servisler',
              value: observation.services.isEmpty
                  ? 'Gözlemlenmedi'
                  : observation.services.join(', '),
            ),
            if (changes.isNotEmpty) ...[
              const Divider(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Önceki gözleme göre değişiklikler',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const SizedBox(height: 6),
              for (final change in changes)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('• $change'),
                ),
            ],
          ],
        ],
      ),
    );
  }
}

class _TimelineLine extends StatelessWidget {
  const _TimelineLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text('$label: $value'),
    ),
  );
}

class _TimelineMessage extends StatelessWidget {
  const _TimelineMessage({
    required this.icon,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 12), action!],
          ],
        ),
      ),
    ),
  );
}
