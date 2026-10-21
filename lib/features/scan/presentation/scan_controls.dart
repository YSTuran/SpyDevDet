part of 'scan_screen.dart';

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
            SizedBox(
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
