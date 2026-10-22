import 'package:flutter/material.dart';
import 'package:spy_dev_det/features/history/presentation/history_screen.dart';
import 'package:spy_dev_det/features/history/presentation/known_devices_screen.dart';
import 'package:spy_dev_det/features/history/presentation/network_profiles_screen.dart';
import 'package:spy_dev_det/features/scan/presentation/scan_screen.dart';
import 'package:spy_dev_det/features/settings/presentation/settings_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  var _selectedIndex = 0;
  final List<Widget?> _pages = [const ScanScreen(), null, null, null, null];

  static const _destinations = [
    _ShellDestination(
      label: 'Tarama',
      icon: Icons.radar_outlined,
      selectedIcon: Icons.radar,
    ),
    _ShellDestination(
      label: 'Cihazlar',
      icon: Icons.devices_outlined,
      selectedIcon: Icons.devices,
    ),
    _ShellDestination(
      label: 'Ağlar',
      icon: Icons.router_outlined,
      selectedIcon: Icons.router,
    ),
    _ShellDestination(
      label: 'Geçmiş',
      icon: Icons.history_outlined,
      selectedIcon: Icons.history,
    ),
    _ShellDestination(
      label: 'Ayarlar',
      icon: Icons.palette_outlined,
      selectedIcon: Icons.palette,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _selectedIndex != 0) {
          _select(0);
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final content = IndexedStack(
            index: _selectedIndex,
            children: [
              for (var index = 0; index < _pages.length; index++)
                _pages[index] ?? const SizedBox.shrink(),
            ],
          );
          if (constraints.maxWidth < 760) {
            return Scaffold(
              body: content,
              bottomNavigationBar: SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: NavigationBar(
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: _select,
                    destinations: _destinations
                        .map(
                          (destination) => NavigationDestination(
                            icon: Icon(destination.icon),
                            selectedIcon: Icon(destination.selectedIcon),
                            label: destination.label,
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
              ),
            );
          }

          final extended = constraints.maxWidth >= 1100;
          return Scaffold(
            body: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                  child: SafeArea(
                    child: NavigationRail(
                      extended: extended,
                      minExtendedWidth: 236,
                      selectedIndex: _selectedIndex,
                      onDestinationSelected: _select,
                      groupAlignment: -0.72,
                      labelType: extended
                          ? NavigationRailLabelType.none
                          : NavigationRailLabelType.all,
                      leading: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 26),
                        child: _BrandMark(extended: extended),
                      ),
                      destinations: _destinations
                          .map(
                            (destination) => NavigationRailDestination(
                              icon: Icon(destination.icon),
                              selectedIcon: Icon(destination.selectedIcon),
                              label: Text(destination.label),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                ),
                Expanded(child: content),
              ],
            ),
          );
        },
      ),
    );
  }

  void _select(int value) {
    setState(() {
      _pages[value] ??= switch (value) {
        0 => const ScanScreen(),
        1 => const KnownDevicesScreen(),
        2 => const NetworkProfilesScreen(),
        3 => const HistoryScreen(),
        4 => const SettingsScreen(),
        _ => throw RangeError.index(value, _pages),
      };
      _selectedIndex = value;
    });
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.extended});

  final bool extended;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mark = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, scheme.tertiary],
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.2),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Icon(Icons.security_outlined, color: scheme.onPrimary),
    );
    if (!extended) return mark;
    return SizedBox(
      width: 188,
      child: Row(
        children: [
          mark,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SpyDevDet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  'Yerel ağ keşfi',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShellDestination {
  const _ShellDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
