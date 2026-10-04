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
      child: MaterialApp(
        title: 'Integrated Environmental Monitoring Platform',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0F172A),
          primaryColor: const Color(0xFF38BDF8),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF38BDF8),
            secondary: Color(0xFFFB923C),
            surface: Color(0xFF1E293B),
            background: Color(0xFF0F172A),
            error: Color(0xFFEF4444),
          ),
          textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
          useMaterial3: true,
        ),
        home: const MainShellScreen(),
      ),
    );
  }
}
