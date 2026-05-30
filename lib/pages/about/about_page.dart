import 'package:e_waste/app/widgets/premium_ui.dart';
import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return PremiumShell(
      appBar: AppBar(
        title: const Text('About EcoByte'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            const PremiumSurface(
              borderRadius: 28,
              gradient: LinearGradient(
                colors: [Color(0xFF1A5269), Color(0xFF2C8C6B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EcoByte',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Turning e-waste into value through repair, reuse, and responsible recycling.',
                    style: TextStyle(
                      color: Colors.white,
                      height: 1.45,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PremiumSurface(
              borderRadius: 26,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What EcoByte does',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'EcoByte is a sustainability platform built to reduce electronic waste by helping people list reusable devices, discover nearby recycling options, participate in community knowledge sharing, and learn through daily quizzes.',
                    style: textTheme.bodyMedium?.copyWith(height: 1.6),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PremiumSurface(
              borderRadius: 26,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Built by VioniX',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/vionix.png',
                      fit: BoxFit.contain,
                      height: 96,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 96,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: scheme.outlineVariant),
                          ),
                          child: const Text('VioniX logo will appear here.'),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'EcoByte is designed and engineered by VioniX with a focus on practical climate impact, clean user experience, and real-world digital sustainability workflows.',
                    style: textTheme.bodyMedium?.copyWith(height: 1.6),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PremiumSurface(
              borderRadius: 26,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Version',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upgraded edition (Supabase-first architecture)',
                    style: textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}