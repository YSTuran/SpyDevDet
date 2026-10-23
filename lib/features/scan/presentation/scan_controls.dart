part of 'scan_screen.dart';

class _ScanActionPanel extends StatelessWidget {
  const _ScanActionPanel({required this.state, required this.onPressed});

  final ScanState state;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isSaving = state.phase == ScanPhase.saving;
    final isBusy = state.isBusy;
    final title = isSaving
        ? 'Sonuçlar korunuyor'
        : isBusy
        ? 'Ağ taraması sürüyor'
        : 'Ağındaki cihazları keşfet';
    final description = isSaving
        ? 'Tamamlanan tarama yerel geçmişe kaydediliyor.'
        : isBusy
        ? 'İstersen taramayı güvenli biçimde durdurabilirsin.'
        : 'Hızlı bir genel bakış veya ayrıntılı servis keşfi başlat.';
    final buttonLabel = isSaving
        ? 'Geçmişe kaydediliyor'
        : isBusy
        ? 'Taramayı durdur'
        : 'Yerel ağı tara';
    final buttonIcon = isSaving
        ? Icons.save_outlined
        : isBusy
        ? Icons.stop_rounded
        : Icons.radar_rounded;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primaryContainer, scheme.tertiaryContainer],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final details = Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: scheme.surface.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Icon(buttonIcon, color: scheme.primary, size: 27),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            );
            final button = FilledButton.icon(
              onPressed: onPressed,
              icon: Icon(buttonIcon),
              label: Text(buttonLabel),
            );
            if (constraints.maxWidth < 560) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [details, const SizedBox(height: 16), button],
              );
            }
            return Row(
              children: [
                Expanded(child: details),
                const SizedBox(width: 20),
                button,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ScanModeSelector extends StatelessWidget {
  const _ScanModeSelector({
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  final ScanMode selected;
  final bool enabled;
  final ValueChanged<ScanMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tarama modu', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final textScale = MediaQuery.textScalerOf(context).scale(1);
                final useVerticalOptions =
                    constraints.maxWidth < 440 && textScale > 1.3;
                if (useVerticalOptions) {
                  return Column(
                    children: ScanMode.values
                        .map(
                          (mode) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _ScanModeOption(
                              mode: mode,
                              selected: selected == mode,
                              enabled: enabled,
                              onTap: () => onChanged(mode),
                            ),
                          ),
                        )
                        .toList(growable: false),
                  );
                }
                return SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ScanMode>(
                    segments: ScanMode.values
                        .map(
                          (mode) => ButtonSegment<ScanMode>(
                            value: mode,
                            icon: Icon(
                              mode == ScanMode.quick
                                  ? Icons.bolt_outlined
                                  : Icons.manage_search_outlined,
                            ),
                            label: Text(mode.label),
                          ),
                        )
                        .toList(growable: false),
                    selected: {selected},
                    onSelectionChanged: enabled
                        ? (selection) => onChanged(selection.first)
                        : null,
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              selected.description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanModeOption extends StatelessWidget {
  const _ScanModeOption({
    required this.mode,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final ScanMode mode;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      enabled: enabled,
      label: '${mode.label} tarama modu',
      excludeSemantics: true,
      child: Material(
        color: selected ? scheme.secondaryContainer : scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(14),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    mode == ScanMode.quick
                        ? Icons.bolt_outlined
                        : Icons.manage_search_outlined,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(mode.label)),
                  Icon(
                    selected ? Icons.check_circle : Icons.circle_outlined,
                    color: selected ? scheme.primary : scheme.outline,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DeviceFilters extends StatelessWidget {
  const _DeviceFilters({
    required this.controller,
    required this.filter,
    required this.sort,
    required this.onQueryChanged,
    required this.onFilterChanged,
    required this.onSortChanged,
  });

  final TextEditingController controller;
  final DeviceFilterOption filter;
  final DeviceSortOption sort;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<DeviceFilterOption> onFilterChanged;
  final ValueChanged<DeviceSortOption> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: controller,
              onChanged: onQueryChanged,
              decoration: InputDecoration(
                labelText: 'Cihazlarda ara',
                hintText: 'Ad, IP, MAC, üretici veya servis',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: controller.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Aramayı temizle',
                        onPressed: () {
                          controller.clear();
                          onQueryChanged('');
                        },
                        icon: const Icon(Icons.clear),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final filterField = DropdownButtonFormField<DeviceFilterOption>(
                  initialValue: filter,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Filtre',
                    prefixIcon: Icon(Icons.filter_list),
                  ),
                  items: DeviceFilterOption.values
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(
                            value.label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) onFilterChanged(value);
                  },
                );
                final sortField = DropdownButtonFormField<DeviceSortOption>(
                  initialValue: sort,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Sırala',
                    prefixIcon: Icon(Icons.sort),
                  ),
                  items: DeviceSortOption.values
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(
                            value.label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) onSortChanged(value);
                  },
                );
                if (constraints.maxWidth < 520) {
                  return Column(
                    children: [
                      filterField,
                      const SizedBox(height: 12),
                      sortField,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: filterField),
                    const SizedBox(width: 12),
                    Expanded(child: sortField),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
