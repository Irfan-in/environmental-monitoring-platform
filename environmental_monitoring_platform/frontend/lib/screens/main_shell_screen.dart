import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/environment_provider.dart';
import 'dashboard_screen.dart';
import 'comparison_screen.dart';
import 'charts_screen.dart';
import 'alerts_screen.dart';

import 'sonnet/dashboard_screen.dart' as sonnet;
import 'sonnet/charts_screen.dart' as sonnet;
import 'sonnet/alerts_screen.dart' as sonnet;

import 'argon/dashboard_screen.dart' as argon;
import 'argon/charts_screen.dart' as argon;
import 'argon/alerts_screen.dart' as argon;

enum AppLayoutMode { classic, sonnet, argon }

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;
  AppLayoutMode _layoutMode = AppLayoutMode.sonnet; // Default to Sonnet for immediate preview!

  List<Widget> _getScreens() {
    switch (_layoutMode) {
      case AppLayoutMode.sonnet:
        return const [
          sonnet.DashboardScreen(),
          ComparisonScreen(),
          sonnet.ChartsScreen(),
          sonnet.AlertsScreen(),
        ];
      case AppLayoutMode.argon:
        return const [
          argon.DashboardScreen(),
          ComparisonScreen(),
          argon.ChartsScreen(),
          argon.AlertsScreen(),
        ];
      case AppLayoutMode.classic:
        return const [
          DashboardScreen(),
          ComparisonScreen(),
          ChartsScreen(),
          AlertsScreen(),
        ];
    }
  }

  void _showLayoutPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.palette_outlined, color: Color(0xFF0284C7)),
                    const SizedBox(width: 10),
                    Text(
                      'Choose Layout to Preview',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildLayoutOption(
                  ctx,
                  mode: AppLayoutMode.sonnet,
                  title: 'Design A: Sonnet 3.5 (Google Weather Style)',
                  subtitle: 'Material-You lavender tokens, elegant cards & custom graphs',
                  icon: Icons.wb_sunny_outlined,
                  color: const Color(0xFF8A1FD6),
                ),
                const SizedBox(height: 8),
                _buildLayoutOption(
                  ctx,
                  mode: AppLayoutMode.argon,
                  title: 'Design B: Argon (Dynamic 3-Focus Mode)',
                  subtitle: 'Indoor / Outdoor / Overview tabs with Dew Point calculations',
                  icon: Icons.analytics_outlined,
                  color: const Color(0xFF0284C7),
                ),
                const SizedBox(height: 8),
                _buildLayoutOption(
                  ctx,
                  mode: AppLayoutMode.classic,
                  title: 'Classic UI (Original)',
                  subtitle: 'Original environmental telemetry dashboard',
                  icon: Icons.view_quilt_outlined,
                  color: const Color(0xFF64748B),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLayoutOption(
    BuildContext ctx, {
    required AppLayoutMode mode,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _layoutMode == mode;
    final isDark = Theme.of(ctx).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        setState(() => _layoutMode = mode);
        Navigator.pop(ctx);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? color.withValues(alpha: 0.1)
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.2),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 22),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final alertCount = context.watch<EnvironmentProvider>().unacknowledgedAlertCount;
    final isDesktop = MediaQuery.of(context).size.width >= 768;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screens = _getScreens();

    if (isDesktop) {
      return Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showLayoutPicker,
          icon: const Icon(Icons.style, size: 20),
          label: Text(
            _layoutMode == AppLayoutMode.sonnet
                ? 'Design A (Sonnet)'
                : _layoutMode == AppLayoutMode.argon
                    ? 'Design B (Argon)'
                    : 'Classic UI',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
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
            Expanded(child: screens[_currentIndex]),
          ],
        ),
      );
    }

    // Mobile Layout
    return Scaffold(
      body: screens[_currentIndex],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showLayoutPicker,
        icon: const Icon(Icons.palette_outlined, size: 18),
        label: Text(
          _layoutMode == AppLayoutMode.sonnet
              ? 'Design A (Sonnet)'
              : _layoutMode == AppLayoutMode.argon
                  ? 'Design B (Argon)'
                  : 'Classic UI',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        ),
        backgroundColor: _layoutMode == AppLayoutMode.sonnet
            ? const Color(0xFF8A1FD6)
            : (_layoutMode == AppLayoutMode.argon
                ? const Color(0xFF0284C7)
                : theme.colorScheme.primary),
        foregroundColor: Colors.white,
      ),
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
