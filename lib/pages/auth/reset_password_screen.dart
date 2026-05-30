import 'package:e_waste/app/data/supabase_repository.dart';
import 'package:e_waste/app/auth_flow_controller.dart';
import 'package:e_waste/app/widgets/premium_mode_ui.dart';
import 'package:e_waste/pages/auth/login_screen.dart';
import 'package:e_waste/pages/auth/widgets/textfield.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isUpdating = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      await SupabaseRepository.client.auth.updateUser(
        UserAttributes(password: _passwordController.text),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully. Please sign in again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      passwordRecoveryPending.value = false;
      await SupabaseRepository.client.auth.signOut();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (ctx) => const LoginScreen()),
        (route) => false,
      );
    } on AuthException catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message.isNotEmpty ? e.message : 'Could not update password.'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PremiumModeShell(
      appBar: AppBar(title: const Text('Set new password')),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: PremiumModeSurface(
              borderRadius: 26,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Choose a new password',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Use at least 8 characters for better account security.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 18),
                    Textfield(
                      controller: _passwordController,
                      label: 'New password',
                      obscureText: true,
                      validator: (value) {
                        final input = value ?? '';
                        if (input.isEmpty) {
                          return 'Please enter a new password';
                        }
                        if (input.length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        return null;
                      },
                    ),
                    Textfield(
                      controller: _confirmPasswordController,
                      label: 'Confirm new password',
                      obscureText: true,
                      validator: (value) {
                        if ((value ?? '').isEmpty) {
                          return 'Please confirm your password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _isUpdating ? null : _updatePassword,
                      child: _isUpdating
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Update password'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
