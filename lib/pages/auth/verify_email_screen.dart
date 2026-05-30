import 'package:e_waste/app/data/supabase_repository.dart';
import 'package:e_waste/app/widgets/premium_mode_ui.dart';
import 'package:e_waste/pages/auth/login_screen.dart';
import 'package:e_waste/pages/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _isSending = false;
  bool _isChecking = false;

  String get _email => SupabaseRepository.client.auth.currentUser?.email ?? 'your email';

  Future<void> _resendVerificationEmail() async {
    final email = SupabaseRepository.client.auth.currentUser?.email;
    if (email == null || email.isEmpty) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      await SupabaseRepository.client.auth.resend(
        type: OtpType.signup,
        email: email,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification email sent again.')),
      );
    } on AuthException catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message.isNotEmpty ? e.message : 'Could not resend verification email.'),
          backgroundColor: Colors.red.shade600,
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

  Future<void> _iHaveVerified() async {
    setState(() {
      _isChecking = true;
    });

    try {
      final userResponse = await SupabaseRepository.client.auth.getUser();
      final user = userResponse.user;

      if (!mounted) {
        return;
      }

      if (user?.emailConfirmedAt != null) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (ctx) => const MainScreen()),
          (route) => false,
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email is still not verified. Please check your inbox.')),
      );
    } on AuthException catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    await SupabaseRepository.client.auth.signOut();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (ctx) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PremiumModeShell(
      appBar: AppBar(title: const Text('Verify your email')),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: PremiumModeSurface(
              borderRadius: 26,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.mark_email_unread_outlined, size: 54),
                  const SizedBox(height: 14),
                  Text(
                    'Check your inbox',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We sent a verification link to $_email. Confirm your email to unlock the app.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: _isChecking ? null : _iHaveVerified,
                    child: _isChecking
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('I have verified my email'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: _isSending ? null : _resendVerificationEmail,
                    child: _isSending
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Resend verification email'),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _signOut,
                    child: const Text('Use another account'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
