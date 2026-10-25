import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/environment_provider.dart';
import 'screens/main_shell_screen.dart';
import 'theme/wx_style.dart';

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
          final darkBase = WxTheme.build(Brightness.dark);
          final lightBase = WxTheme.build(Brightness.light);
          return MaterialApp(
            title: 'Environmental Monitor',
            debugShowCheckedModeBanner: false,
            themeMode: env.themeMode,
            darkTheme: darkBase.copyWith(
              textTheme: GoogleFonts.interTextTheme(darkBase.textTheme),
            ),
            theme: lightBase.copyWith(
              textTheme: GoogleFonts.interTextTheme(lightBase.textTheme),
            ),
            home: const MainShellScreen(),
          );
        },
      ),
    );
  }
}
