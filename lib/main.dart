import 'package:e_waste/app/theme_controller.dart';
import 'package:e_waste/pages/main_screen.dart';
import 'package:e_waste/pages/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  Gemini.init(apiKey: dotenv.get('GEMINI_API_KEY'));

  await supa.Supabase.initialize(
    url: dotenv.get('SUPABASE_URL'),
    anonKey: dotenv.get('SUPABASE_ANON_KEY'),
  );
  runApp(const EcoByteRoot());
}

class EcoByteRoot extends StatelessWidget {
  const EcoByteRoot({super.key});

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF1A5269);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance.themeMode,
      builder: (context, mode, _) {
        final baseLightTheme = ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: seedColor,
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFE5F5F0),
          appBarTheme: const AppBarTheme(
            backgroundColor: seedColor,
            foregroundColor: Colors.white,
          ),
        );

        final baseDarkTheme = ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: seedColor,
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: Colors.black,
          canvasColor: Colors.black,
          appBarTheme: const AppBarTheme(
            backgroundColor: seedColor,
            foregroundColor: Colors.white,
          ),
        );

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: baseLightTheme.copyWith(
            textTheme: GoogleFonts.poppinsTextTheme(baseLightTheme.textTheme),
          ),
          darkTheme: baseDarkTheme.copyWith(
            textTheme: GoogleFonts.poppinsTextTheme(baseDarkTheme.textTheme),
          ),
          home: const _AuthGate(),
        );
      },
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = supa.Supabase.instance.client.auth;

    return StreamBuilder<supa.AuthState>(
      stream: auth.onAuthStateChange,
      initialData: supa.AuthState(
        supa.AuthChangeEvent.initialSession,
        auth.currentSession,
      ),
      builder: (context, snapshot) {
        final session = snapshot.data?.session ?? auth.currentSession;
        return session == null ? LoginScreen() : MainScreen();
      },
    );
  }
}
