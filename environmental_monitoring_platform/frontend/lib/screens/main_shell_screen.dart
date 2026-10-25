import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:environmental_monitoring_platform/providers/environment_provider.dart';
import 'package:environmental_monitoring_platform/theme/wx_style.dart';
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

  static const List<Widget> _screens = [
    DashboardScreen(),
    ComparisonScreen(),
    ChartsScreen(),
    AlertsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final alertCount = context.watch<EnvironmentProvider>().unacknowledgedAlertCount;
    final wx = Wx.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              backgroundColor: wx.card,
              selectedIndex: _currentIndex,
              onDestinationSelected: (i) => setState(() => _currentIndex = i),
              labelType: NavigationRailLabelType.all,
              selectedIconTheme: IconThemeData(color: wx.accent),
              unselectedIconTheme: IconThemeData(color: wx.textDim),
              selectedLabelTextStyle: TextStyle(color: wx.accent, fontWeight: FontWeight.bold),
              unselectedLabelTextStyle: TextStyle(color: wx.textDim),
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Icon(Icons.eco, color: wx.accent, size: 32),
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
                  label: Text('Compare'),
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
            VerticalDivider(thickness: 1, width: 1, color: wx.textDim.withValues(alpha: 0.15)),
            Expanded(child: _screens[_currentIndex]),
          ],
        ),
      );
    }

    return Scaffold(
      extendBody: true,
      body: _screens[_currentIndex],
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: wx.card,
              border: Border(
                top: BorderSide(color: wx.cardBorder, width: 0.8),
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: wx.accent,
              unselectedItemColor: wx.textDim,
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
              label: 'Compare',
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
    ),
  ),
);
  }
}
