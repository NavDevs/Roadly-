import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/app_provider.dart';
import 'navigation.dart';
import 'transitions.dart';
import 'screens/login_screen.dart';
import 'screens/tabs_screen.dart';
import 'screens/report_screen.dart';

import 'dart:io';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Never restore a previous account on launch: drop any stored session so
  // the app always opens on the login screen — no ghost/old-user auto-login.
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(dir.path + '/roadly_session.json');
    if (await file.exists()) await file.delete();
  } catch (e) {
    debugPrint('main() session cleanup error: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  final String? initialUserId;
  const MyApp({super.key, this.initialUserId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(initialUserId),
      child: MaterialApp(
        title: 'Roadly',
        navigatorKey: appNavigatorKey,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: GoogleFonts.inter().fontFamily,
          pageTransitionsTheme: appPageTransitions,
          scaffoldBackgroundColor: const Color(0xFF0B0F12),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF16A34A),
            onPrimary: Colors.white,
            secondary: Color(0xFF1F2933),
            onSecondary: Color(0xFFF5F5F7),
            error: Color(0xFFEF4444),
            onError: Colors.white,
            surface: Color(0xFF0B0F12),
            onSurface: Color(0xFFF5F5F7),
          ),
        ),
        home: Consumer<AppProvider>(
          builder: (context, provider, child) {
            if (!provider.ready) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            return provider.isLoggedIn ? const TabsScreen() : const LoginScreen();
          },
        ),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/tabs': (context) => const TabsScreen(),
          '/report': (context) => const ReportScreen(),
        },
      ),
    );
  }
}
