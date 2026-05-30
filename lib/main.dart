import 'package:e_waste/app/theme_controller.dart';
import 'package:e_waste/app/auth_flow_controller.dart';
import 'package:e_waste/pages/auth/reset_password_screen.dart';
import 'package:e_waste/pages/auth/verify_email_screen.dart';
import 'package:e_waste/pages/main_screen.dart';
import 'package:e_waste/pages/auth/login_screen.dart';
import 'package:app_links/app_links.dart';
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

class EcoByteRoot extends StatefulWidget {
  const EcoByteRoot({super.key});

  @override
  State<EcoByteRoot> createState() => _EcoByteRootState();
}

class _EcoByteRootState extends State<EcoByteRoot> {
  final AppLinks _appLinks = AppLinks();
  bool _initialLinkHandled = false;

  @override
  void initState() {
    super.initState();
    _listenToDeepLinks();
  }

  Future<void> _listenToDeepLinks() async {
    if (_initialLinkHandled) {
      return;
    }
    _initialLinkHandled = true;

    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        await _handleIncomingLink(initialLink);
      }

      _appLinks.uriLinkStream.listen((uri) {
        _handleIncomingLink(uri);
      });
    } catch (_) {
      // Deep-link startup failures should not block the app.
    }
  }

  Future<void> _handleIncomingLink(Uri uri) async {
    if (uri.scheme != 'ecobyte' || uri.host != 'auth-callback') {
      return;
    }

    try {
      await supa.Supabase.instance.client.auth.getSessionFromUrl(uri);
      passwordRecoveryPending.value = true;
    } catch (_) {
      // Let Supabase's internal handler or the current app state continue.
    }
  }

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

    return ValueListenableBuilder<bool>(
      valueListenable: passwordRecoveryPending,
      builder: (context, isPasswordRecoveryPending, _) {
        return StreamBuilder<supa.AuthState>(
          stream: auth.onAuthStateChange,
          initialData: supa.AuthState(
            supa.AuthChangeEvent.initialSession,
            auth.currentSession,
          ),
          builder: (context, snapshot) {
            final authEvent = snapshot.data?.event;
            if (authEvent == supa.AuthChangeEvent.passwordRecovery &&
                !isPasswordRecoveryPending) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                passwordRecoveryPending.value = true;
              });
            }

            final session = snapshot.data?.session ?? auth.currentSession;
            if (isPasswordRecoveryPending) {
              return const ResetPasswordScreen();
            }

            if (session == null) {
              return const LoginScreen();
            }

            final user = auth.currentUser;
            if (user == null || user.emailConfirmedAt == null) {
              return const VerifyEmailScreen();
            }

            return MainScreen();
          },
        );
      },
    );
  }
}
