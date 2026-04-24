import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/app_provider.dart';
import 'screens/login_screen.dart';
import 'screens/tabs_screen.dart';
import 'screens/report_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: MaterialApp(
        title: 'Roadly',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: GoogleFonts.inter().fontFamily,
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
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginScreen(),
          '/tabs': (context) => const TabsScreen(),
          '/report': (context) => const ReportScreen(),
        },
      ),
    );
  }
}
