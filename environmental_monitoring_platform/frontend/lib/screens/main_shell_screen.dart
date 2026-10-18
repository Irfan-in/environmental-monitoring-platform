import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/environment_provider.dart';
import 'dashboard_screen.dart';
import 'comparison_screen.dart';
import 'charts_screen.dart';
import 'alerts_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    ComparisonScreen(),
    ChartsScreen(),
    AlertsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final alertCount = context.watch<EnvironmentProvider>().unacknowledgedAlertCount;
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (isDesktop) {
      // Desktop / Web Layout with Navigation Rail
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              backgroundColor: theme.cardColor,
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) => setState(() => _currentIndex = index),
              labelType: NavigationRailLabelType.all,
              selectedIconTheme: IconThemeData(color: theme.colorScheme.primary),
              unselectedIconTheme: IconThemeData(
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
              selectedLabelTextStyle: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelTextStyle: TextStyle(
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Icon(Icons.eco, color: theme.colorScheme.primary, size: 32),
              ),
              destinations: [
                const NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: Text('Dashboard'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.compare_arrows_outlined),
                  selectedIcon: Icon(Icons.compare_arrows),
                  label: Text('Comparison'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.show_chart_outlined),
                  selectedIcon: Icon(Icons.show_chart),
                  label: Text('Charts'),
                ),
                NavigationRailDestination(
                  icon: Badge(
                    isLabelVisible: alertCount > 0,
                    label: Text(alertCount.toString()),
                    child: const Icon(Icons.notifications_outlined),
                  ),
                  selectedIcon: Badge(
                    isLabelVisible: alertCount > 0,
                    label: Text(alertCount.toString()),
                    child: const Icon(Icons.notifications),
                  ),
                  label: const Text('Alerts'),
                ),
              ],
            ),
            VerticalDivider(
              thickness: 1,
              width: 1,
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
            Expanded(child: _screens[_currentIndex]),
          ],
        ),
      );
    }

    // Mobile Layout with Bottom Navigation Bar
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: 0.5,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: theme.cardColor,
          selectedItemColor: theme.colorScheme.primary,
          unselectedItemColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          selectedFontSize: 12,
          unselectedFontSize: 11,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.compare_arrows_outlined),
              activeIcon: Icon(Icons.compare_arrows),
              label: 'Comparison',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.show_chart_outlined),
              activeIcon: Icon(Icons.show_chart),
              label: 'Charts',
            ),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: alertCount > 0,
                label: Text(alertCount.toString()),
                child: const Icon(Icons.notifications_outlined),
              ),
              activeIcon: Badge(
                isLabelVisible: alertCount > 0,
                label: Text(alertCount.toString()),
                child: const Icon(Icons.notifications),
              ),
              label: 'Alerts',
            ),
          ],
        ),
      ),
    );
  }
}
