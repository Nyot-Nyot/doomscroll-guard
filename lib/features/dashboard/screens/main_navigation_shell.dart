import 'package:flutter/material.dart';
import 'package:doomscrolling_guard/core/themes/app_colors.dart';
import 'dashboard_screen.dart';
import '../../statistics/screens/statistics_screen.dart';
import '../../settings/screens/settings_screen.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    StatisticsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primaryAccent.withOpacity(0.15),
          height: 65,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.shield_outlined, color: AppColors.textSecondary),
              selectedIcon: Icon(Icons.shield_rounded, color: AppColors.primaryAccent),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.analytics_outlined, color: AppColors.textSecondary),
              selectedIcon: Icon(Icons.analytics_rounded, color: AppColors.primaryAccent),
              label: 'Statistik',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined, color: AppColors.textSecondary),
              selectedIcon: Icon(Icons.settings_rounded, color: AppColors.primaryAccent),
              label: 'Pengaturan',
            ),
          ],
        ),
      ),
    );
  }
}
