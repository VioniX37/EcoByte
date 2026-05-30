import 'dart:ui';

import 'package:e_waste/app/data/supabase_repository.dart';
import 'package:e_waste/app/widgets/premium_mode_ui.dart';
import 'package:e_waste/app/widgets/theme_toggle_icon_button.dart';
import 'package:e_waste/pages/auth/signup_screen.dart';
import 'package:e_waste/pages/auth/widgets/textfield.dart';
import 'package:e_waste/pages/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await SupabaseRepository.client.auth.signInWithPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      await SupabaseRepository.ensureCurrentProfileExists();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Welcome back!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (ctx) => MainScreen()),
        (route) => false,
      );
    } on AuthException catch (e) {
      if (!mounted) {
        return;
      }

      final lower = e.message.toLowerCase();
      final message = lower.contains('invalid login credentials')
          ? 'Incorrect email or password'
          : lower.contains('email not confirmed')
              ? 'Please confirm your email before signing in'
              : 'Login failed. Please try again';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardGradient = isDark
        ? [
        const Color(0xFF101010).withValues(alpha: 0.98),
        const Color(0xFF1A1A1A).withValues(alpha: 0.94),
          ]
        : [
            Colors.white.withValues(alpha: 0.92),
            Colors.white.withValues(alpha: 0.78),
          ];

    return PremiumModeShell(
      appBar: AppBar(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(
          bottom: BorderSide(
            color: scheme.onPrimary.withValues(alpha: 0.22),
          ),
        ),
        title: Text(
          'EcoByte',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: scheme.onPrimary,
              ),
        ),
        actions: const [ThemeToggleIconButton()],
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
                child: Material(
                  color: Colors.transparent,
                  elevation: 10,
                  shadowColor: scheme.shadow.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: cardGradient),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(
                          alpha: isDark ? 0.35 : 0.45,
                        ),
                        width: 1.1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 8),
                            Hero(
                              tag: 'app_logo',
                              child: Center(
                                child: Image.asset('assets/logo.png', height: 84),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Welcome back',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Sign in to continue your EcoByte journey.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                            const SizedBox(height: 26),
                            Textfield(
                              controller: emailController,
                              label: 'Email',
                              validator: (value) => value == null || value.isEmpty
                                  ? 'Please enter your email'
                                  : null,
                            ),
                            Textfield(
                              controller: passwordController,
                              label: 'Password',
                              obscureText: true,
                              validator: (value) => value == null || value.isEmpty
                                  ? 'Please enter your password'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _isLoading ? null : login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: scheme.primary,
                                foregroundColor: scheme.onPrimary,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Login'),
                            ),
                            const SizedBox(height: 14),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (ctx) => const SignupScreen(),
                                  ),
                                );
                              },
                              child: const Text('Don\'t have an account? Sign up'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}