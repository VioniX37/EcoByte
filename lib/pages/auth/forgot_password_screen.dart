import 'dart:ui';

import 'package:e_waste/app/data/supabase_repository.dart';
import 'package:e_waste/app/widgets/premium_mode_ui.dart';
import 'package:e_waste/app/widgets/theme_toggle_icon_button.dart';
import 'package:e_waste/pages/auth/widgets/textfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool _isSending = false;

  static const String _defaultResetRedirect = 'ecobyte://auth-callback';

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final configuredRedirect = dotenv.maybeGet('SUPABASE_RESET_PASSWORD_REDIRECT_TO');
      final redirectTo = configuredRedirect == null || configuredRedirect.trim().isEmpty
          ? _defaultResetRedirect
          : configuredRedirect.trim();
      await SupabaseRepository.client.auth.resetPasswordForEmail(
        _emailController.text.trim(),
        redirectTo: redirectTo,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reset link sent. Check your email inbox.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    } on AuthException catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message.isNotEmpty ? e.message : 'Could not send reset email.'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PremiumModeShell(
      appBar: AppBar(
        title: const Text('Forgot password'),
        actions: const [ThemeToggleIconButton()],
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    color: isDark
                        ? const Color(0xFF111111).withValues(alpha: 0.95)
                        : Colors.white.withValues(alpha: 0.88),
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: isDark ? 0.35 : 0.45),
                    ),
                  ),
                  padding: const EdgeInsets.all(22),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Reset your password',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Enter your account email. You will receive a secure reset link.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 18),
                        Textfield(
                          controller: _emailController,
                          label: 'Email',
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            final input = value?.trim() ?? '';
                            if (input.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!input.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _isSending ? null : _sendResetEmail,
                          child: _isSending
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Send reset link'),
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
    );
  }
}
