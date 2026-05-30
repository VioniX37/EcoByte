import 'package:e_waste/app/widgets/premium_ui.dart';
import 'package:flutter/material.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    Widget section(String title, String body) {
      return PremiumSurface(
        borderRadius: 24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: textTheme.bodyMedium?.copyWith(height: 1.6),
            ),
          ],
        ),
      );
    }

    return PremiumShell(
      appBar: AppBar(
        title: const Text('Terms and Conditions'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            PremiumSurface(
              borderRadius: 28,
              gradient: const LinearGradient(
                colors: [Color(0xFF1A5269), Color(0xFF2C8C6B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EcoByte Terms',
                    style: textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please read these terms before using EcoByte. By creating an account or continuing to use the app, you agree to these conditions.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            section(
              '1. Acceptance',
              'By signing up, logging in, or using EcoByte, you confirm that you have read, understood, and agreed to these Terms and Conditions.',
            ),
            const SizedBox(height: 12),
            section(
              '2. Permitted use',
              'EcoByte is provided for personal, educational, and non-commercial sustainability use. You may browse listings, post community content, manage your profile, and use the app features in a lawful and respectful manner.',
            ),
            const SizedBox(height: 12),
            section(
              '3. Prohibited use',
              'You must not misuse the platform, attempt unauthorized access, submit harmful, abusive, or misleading content, interfere with the service, or use the application for commercial resale or redistribution without written permission from VioniX.',
            ),
            const SizedBox(height: 12),
            section(
              '4. User content',
              'You are responsible for the content you upload or publish. You confirm that your posts, images, and listing details do not infringe the rights of others and are accurate to the best of your knowledge.',
            ),
            const SizedBox(height: 12),
            section(
              '5. Account security',
              'Keep your credentials secure and do not share your account with others. You are responsible for activity performed under your account unless unauthorized use is reported promptly.',
            ),
            const SizedBox(height: 12),
            section(
              '6. Availability and changes',
              'EcoByte may be updated, modified, or temporarily unavailable at any time. Features may change as the product evolves.',
            ),
            const SizedBox(height: 12),
            section(
              '7. Limitation of liability',
              'EcoByte is provided as-is. VioniX is not liable for losses, disputes, data loss, or damages arising from use of the app, except where required by law.',
            ),
            const SizedBox(height: 12),
            section(
              '8. Contact',
              'For support or questions about these terms, contact vionix37@gmail.com.',
            ),
          ],
        ),
      ),
    );
  }
}
