import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/app_provider.dart';
import 'navigation.dart';
import 'transitions.dart';
import 'screens/login_screen.dart';
import 'screens/tabs_screen.dart';
import 'screens/report_screen.dart';

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Restore the saved session so the app opens signed in. A server data wipe
  // is still handled by AppProvider._checkDataEpoch (sign-out only then).
  String? userId;
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/roadly_session.json');
    if (await file.exists()) {
      final data = json.decode(await file.readAsString());
      userId = data['userId']?.toString();
    }
  } catch (e) {
    debugPrint('main() session read error: $e');
  }
  runApp(MyApp(initialUserId: userId));
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
