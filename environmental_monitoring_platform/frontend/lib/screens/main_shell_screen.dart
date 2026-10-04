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

    if (isDesktop) {
      // Desktop / Web Layout with Navigation Rail
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              backgroundColor: const Color(0xFF1E293B),
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) => setState(() => _currentIndex = index),
              labelType: NavigationRailLabelType.all,
              selectedIconTheme: const IconThemeData(color: Color(0xFF38BDF8)),
              unselectedIconTheme: const IconThemeData(color: Color(0xFF94A3B8)),
              selectedLabelTextStyle: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold),
              unselectedLabelTextStyle: const TextStyle(color: Color(0xFF94A3B8)),
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Icon(Icons.eco, color: Color(0xFF38BDF8), size: 32),
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
            const VerticalDivider(thickness: 1, width: 1, color: Color(0xFF334155)),
            Expanded(child: _screens[_currentIndex]),
          ],
        ),
      );
    }

    // Mobile Layout with Bottom Navigation Bar
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFF334155), width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF1E293B),
          selectedItemColor: const Color(0xFF38BDF8),
          unselectedItemColor: const Color(0xFF94A3B8),
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
