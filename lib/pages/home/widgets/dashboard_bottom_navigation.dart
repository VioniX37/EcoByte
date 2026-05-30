import 'package:e_waste/others/color.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

final ValueNotifier<int> dashboardIndexNotifier = ValueNotifier<int>(0);

class DashboardBottomNavigationWidget extends StatelessWidget {
  const DashboardBottomNavigationWidget({super.key, this.onDestinationSelected});

  final ValueChanged<int>? onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heroGradient = isDark
        ? const [Color(0xFF1A5269), Color(0xFF2C8C6B)]
        : const [Color(0xFF1A5269), Color(0xFF2C8C6B)];

    return ValueListenableBuilder<int>(
      valueListenable: dashboardIndexNotifier,
      builder: (context, index, _) {
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      heroGradient[0].withValues(alpha: isDark ? 0.34 : 0.20),
                      heroGradient[1].withValues(alpha: isDark ? 0.28 : 0.16),
                    ],
                  ),
                  color: isDark
                      ? const Color(0xFF101820).withValues(alpha: 0.72)
                      : Colors.white.withValues(alpha: 0.72),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.10)
                        : heroGradient[0].withValues(alpha: 0.12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _NavItem(
                      icon: Icons.home_outlined,
                      selectedIcon: Icons.home,
                      label: 'Home',
                      selected: index == 0,
                      onTap: () {
                        dashboardIndexNotifier.value = 0;
                        onDestinationSelected?.call(0);
                      },
                    ),
                    _NavItem(
                      icon: Icons.forum_outlined,
                      selectedIcon: Icons.forum,
                      label: 'Connect',
                      selected: index == 1,
                      onTap: () {
                        dashboardIndexNotifier.value = 1;
                        onDestinationSelected?.call(1);
                      },
                    ),
                    _NavItem(
                      icon: Icons.location_on_outlined,
                      selectedIcon: Icons.location_on,
                      label: 'Find',
                      selected: index == 2,
                      onTap: () {
                        dashboardIndexNotifier.value = 2;
                        onDestinationSelected?.call(2);
                      },
                    ),
                    _NavItem(
                      icon: Icons.emoji_events_outlined,
                      selectedIcon: Icons.emoji_events,
                      label: 'Play',
                      selected: index == 3,
                      onTap: () {
                        dashboardIndexNotifier.value = 3;
                        onDestinationSelected?.call(3);
                      },
                    ),
                    _NavItem(
                      icon: Icons.smart_toy_outlined,
                      selectedIcon: Icons.smart_toy,
                      label: 'EcoBot',
                      selected: index == 4,
                      onTap: () {
                        dashboardIndexNotifier.value = 4;
                        onDestinationSelected?.call(4);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heroGradient = const [Color(0xFF1A5269), Color(0xFF2C8C6B)];
    final selectedGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        heroGradient[0].withValues(alpha: isDark ? 0.26 : 0.18),
        heroGradient[1].withValues(alpha: isDark ? 0.22 : 0.14),
      ],
    );

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            gradient: selected ? selectedGradient : null,
            color: selected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? selectedIcon : icon,
                color: selected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
