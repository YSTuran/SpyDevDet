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
              bottomNavigationBar: NavigationBar(
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
            );
          }

          final extended = constraints.maxWidth >= 1100;
          return Scaffold(
            body: Row(
              children: [
                SafeArea(
                  child: NavigationRail(
                    extended: extended,
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: _select,
                    labelType: extended
                        ? NavigationRailLabelType.none
                        : NavigationRailLabelType.all,
                    leading: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Icon(
                        Icons.security_outlined,
                        color: Theme.of(context).colorScheme.primary,
                        size: 30,
                      ),
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
                const VerticalDivider(width: 1),
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
