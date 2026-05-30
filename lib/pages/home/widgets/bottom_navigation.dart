import 'dart:ui';

import 'package:e_waste/others/color.dart';
import 'package:flutter/material.dart';

ValueNotifier<int> indexNotifier = ValueNotifier(0);

class BottomNavigationWidget extends StatelessWidget {
  const BottomNavigationWidget({
    super.key,
    this.onDestinationSelected,
  });

  final ValueChanged<int>? onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ValueListenableBuilder(
        valueListenable: indexNotifier,
        builder: (context, index, child) {
          return Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? scheme.surfaceContainerHighest.withValues(alpha: 0.72)
                        : Colors.white.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : AppColors.appColor.withValues(alpha: 0.10),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: NavigationBar(
                    selectedIndex: index,
                    onDestinationSelected: (value) {
                      indexNotifier.value = value;
                      onDestinationSelected?.call(value);
                    },
                    backgroundColor: Colors.transparent,
                    surfaceTintColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    indicatorColor: AppColors.appColor.withValues(
                      alpha: isDark ? 0.22 : 0.14,
                    ),
                    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                    destinations: [
                      NavigationDestination(
                        icon: Icon(Icons.home_outlined, color: AppColors.appColor),
                        selectedIcon: Icon(Icons.home, color: AppColors.appColor),
                        label: 'Home',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.forum_outlined, color: AppColors.appColor),
                        selectedIcon: Icon(Icons.forum, color: AppColors.appColor),
                        label: 'Connect',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.location_on_outlined, color: AppColors.appColor),
                        selectedIcon: Icon(Icons.location_on, color: AppColors.appColor),
                        label: 'Find',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.emoji_events_outlined, color: AppColors.appColor),
                        selectedIcon: Icon(Icons.emoji_events, color: AppColors.appColor),
                        label: 'Play',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.smart_toy_outlined, color: AppColors.appColor),
                        selectedIcon: Icon(Icons.smart_toy, color: AppColors.appColor),
                        label: 'Ask',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        });
  }
}

//Color.fromRGBO(54, 116, 181, 1)
