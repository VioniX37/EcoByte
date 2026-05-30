import 'package:e_waste/app/data/supabase_repository.dart';
import 'package:e_waste/app/widgets/premium_ui.dart';
import 'package:e_waste/pages/main_screen.dart';
import 'package:e_waste/pages/home/widgets/dashboard_bottom_navigation.dart';
import 'package:e_waste/pages/profile/rewards.dart';
import 'package:flutter/material.dart';

class ResultPage extends StatelessWidget {
  const ResultPage({
    super.key,
    required this.gameName,
    required this.score,
    required this.correctCount,
    required this.totalRounds,
    this.rewardsPoints,
  });

  final String gameName;
  final int score;
  final int correctCount;
  final int totalRounds;
  final int? rewardsPoints;

  Future<int> _resolveRewards() async {
    if (rewardsPoints != null) {
      return rewardsPoints!;
    }

    return SupabaseRepository.fetchCurrentRewardPoints();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: _resolveRewards(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const PremiumShell(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final rewardBalance = snapshot.data ?? rewardsPoints ?? score;

        return PremiumShell(
          appBar: AppBar(
            title: const Text('Mission complete'),
            automaticallyImplyLeading: false,
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            children: [
              PremiumSurface(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A5269), Color(0xFF2C8C6B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                child: Column(
                  children: [
                    const Icon(Icons.emoji_events, color: Colors.white, size: 40),
                    const SizedBox(height: 10),
                    Text(
                      '$score points',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$correctCount / $totalRounds correct in $gameName',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              PremiumSurface(
                borderRadius: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reward balance',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$rewardBalance points',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF1A5269),
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'This is the same score shown in Rewards and leaderboard views.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              PremiumSurface(
                borderRadius: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What to do next',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _NextStep(
                      icon: Icons.emoji_events_outlined,
                      title: 'Open Rewards',
                      subtitle: 'Check the same balance and available perks.',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (ctx) => Rewards(score: rewardBalance),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _NextStep(
                      icon: Icons.home_outlined,
                      title: 'Back to Home',
                      subtitle: 'Return to the main EcoByte dashboard.',
                      onTap: () {
                        dashboardIndexNotifier.value = 0;
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (ctx) => const MainScreen()),
                          (route) => false,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NextStep extends StatelessWidget {
  const _NextStep({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        ),
        child: Row(
          children: [
            Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                color: const Color(0xFF1A5269).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: const Color(0xFF1A5269)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}