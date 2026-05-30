import 'dart:ui';

import 'package:e_waste/app/data/supabase_repository.dart';
import 'package:e_waste/app/widgets/premium_mode_ui.dart';
import 'package:e_waste/app/widgets/theme_toggle_icon_button.dart';
import 'package:e_waste/pages/auth/login_screen.dart';
import 'package:e_waste/pages/auth/widgets/textfield.dart';
import 'package:e_waste/pages/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmpasswordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmpasswordController.dispose();
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.dispose();
  }

  Future<void> register() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (passwordController.text != confirmpasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final auth = SupabaseRepository.client.auth;
      final response = await auth.signUp(
        email: emailController.text.trim(),
        password: passwordController.text,
        data: {
          'name': nameController.text.trim(),
          'phone': phoneController.text.trim(),
          'address': addressController.text.trim(),
        },
      );

      final user = response.user;
      if (user == null) {
        throw const AuthException('Signup failed');
      }

      if (response.session != null) {
        await SupabaseRepository.ensureCurrentProfileExists();
      }

      if (!mounted) {
        return;
      }

      if (response.session != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created successfully!')),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (ctx) => MainScreen()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check your email to verify the account, then sign in.'),
          ),
        );
        Navigator.of(context).pop();
      }
    } on AuthException catch (e) {
      if (!mounted) {
        return;
      }

      final message = e.message.isNotEmpty
          ? e.message
          : 'Registration failed. Please try again';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red.shade600),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An unexpected error occurred'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
            constraints: const BoxConstraints(maxWidth: 520),
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
                        key: formKey,
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
                              'Create your account',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Join the circular economy and start selling, learning, and earning.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                            const SizedBox(height: 24),
                            Textfield(
                              controller: nameController,
                              label: 'Name',
                              validator: (value) => value == null || value.isEmpty
                                  ? 'Please enter your name'
                                  : null,
                            ),
                            Textfield(
                              controller: phoneController,
                              label: 'Phone',
                              keyboardType: TextInputType.phone,
                              validator: (value) => value == null || value.isEmpty
                                  ? 'Please enter your phone number'
                                  : null,
                            ),
                            Textfield(
                              controller: addressController,
                              label: 'Address',
                              validator: (value) => value == null || value.isEmpty
                                  ? 'Please enter your address'
                                  : null,
                            ),
                            Textfield(
                              controller: emailController,
                              label: 'Email',
                              keyboardType: TextInputType.emailAddress,
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
                            Textfield(
                              controller: confirmpasswordController,
                              label: 'Confirm password',
                              obscureText: true,
                              validator: (value) => value == null || value.isEmpty
                                  ? 'Please confirm your password'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _isLoading ? null : register,
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
                                  : const Text('Create account'),
                            ),
                            const SizedBox(height: 14),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (ctx) => const LoginScreen(),
                                  ),
                                );
                              },
                              child: const Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Already have an account?'),
                                  SizedBox(height: 2),
                                  Text('Sign in'),
                                ],
                              ),
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
