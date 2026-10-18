import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/environment_provider.dart';
import 'screens/main_shell_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EnvironmentalMonitoringApp());
}

class EnvironmentalMonitoringApp extends StatelessWidget {
  const EnvironmentalMonitoringApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EnvironmentProvider()),
      ],
      child: Consumer<EnvironmentProvider>(
        builder: (context, env, _) {
          return MaterialApp(
            title: 'Integrated Environmental Monitoring Platform',
            debugShowCheckedModeBanner: false,
            themeMode: env.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            // Dark Theme
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              scaffoldBackgroundColor: const Color(0xFF0F172A),
              cardColor: const Color(0xFF1E293B),
              primaryColor: const Color(0xFF38BDF8),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF1E293B),
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF38BDF8),
                secondary: Color(0xFFFB923C),
                surface: Color(0xFF1E293B),
                error: Color(0xFFEF4444),
                outline: Color(0xFF334155),
              ),
              textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
              useMaterial3: true,
            ),
            // Light Theme
            theme: ThemeData(
              brightness: Brightness.light,
              scaffoldBackgroundColor: const Color(0xFFF8FAFC),
              cardColor: Colors.white,
              primaryColor: const Color(0xFF0284C7),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                foregroundColor: Color(0xFF0F172A),
                elevation: 0.5,
              ),
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF0284C7),
                secondary: Color(0xFFEA580C),
                surface: Colors.white,
                error: Color(0xFFDC2626),
                outline: Color(0xFFE2E8F0),
              ),
              textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
              useMaterial3: true,
            ),
            home: const MainShellScreen(),
          );
        },
      ),
    );
  }
}
