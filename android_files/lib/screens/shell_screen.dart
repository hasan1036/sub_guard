import 'package:flutter/material.dart';

import '../widgets/ui.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import 'upcoming_screen.dart';

/// Bottom bar: Home, Upcoming, [ + ], History, Settings.
class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _index = 0;

  void _go(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(onOpenTab: _go),
      const UpcomingScreen(),
      const HistoryScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: _BottomBar(
        index: _index,
        onTap: _go,
        onAdd: () => openAddFlow(context),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.index, required this.onTap, required this.onAdd});

  final int index;
  final ValueChanged<int> onTap;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final light = Theme.of(context).brightness == Brightness.light;
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Container(
        height: 74,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: light ? Colors.white : Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(color: Color(0x2A6A3DF0), blurRadius: 30, offset: Offset(0, 10)),
          ],
        ),
        child: Row(
          children: [
            _NavItem(icon: Icons.home_rounded, label: 'Home', selected: index == 0, onTap: () => onTap(0)),
            _NavItem(icon: Icons.event_rounded, label: 'Upcoming', selected: index == 1, onTap: () => onTap(1)),
            Expanded(
              child: Center(
                child: GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: Brand.gradient,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: const [
                        BoxShadow(color: Color(0x666A3DF0), blurRadius: 18, offset: Offset(0, 6)),
                      ],
                    ),
                    child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
                  ),
                ),
              ),
            ),
            _NavItem(icon: Icons.history_rounded, label: 'History', selected: index == 2, onTap: () => onTap(2)),
            _NavItem(icon: Icons.settings_rounded, label: 'Settings', selected: index == 3, onTap: () => onTap(3)),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              gradient: selected ? Brand.gradient : null,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 24, color: selected ? Colors.white : muted),
                const SizedBox(height: 2),
                FittedBox(
                  child: Text(label,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: selected ? Colors.white : muted)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
