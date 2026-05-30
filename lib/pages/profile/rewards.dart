import 'package:e_waste/app/data/supabase_repository.dart';
import 'package:e_waste/app/widgets/premium_mode_ui.dart';
import 'package:e_waste/app/widgets/theme_toggle_icon_button.dart';
import 'package:flutter/material.dart';

class Rewards extends StatefulWidget {
  const Rewards({super.key, this.score});

  final int? score;

  @override
  State<Rewards> createState() => _RewardsState();
}

class _RewardsState extends State<Rewards> {
  late Future<int> _scoreFuture;

  @override
  void initState() {
    super.initState();
    _scoreFuture = _resolveScore();
  }

  Future<int> _resolveScore() async {
    if (widget.score != null) {
      return widget.score!;
    }

    return SupabaseRepository.fetchCurrentRewardPoints();
  }

  void _refresh() {
    setState(() {
      _scoreFuture = _resolveScore();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: _scoreFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const PremiumModeShell(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final score = snapshot.data ?? widget.score ?? 0;
        final nextReward = ((score ~/ 100) + 1) * 100;
        final progress = (score % 100) / 100.0;

        return PremiumModeShell(
          appBar: AppBar(
            title: const Text('Rewards'),
            actions: [
              const ThemeToggleIconButton(),
              IconButton(
                onPressed: _refresh,
                tooltip: 'Refresh rewards',
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          child: RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                PremiumModeSurface(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A5269), Color(0xFF2C8C6B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: 28,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 56,
                            width: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(Icons.emoji_events, color: Colors.white, size: 30),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$score points',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Your reward balance is synced with the game backend.',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Colors.white.withValues(alpha: 0.88),
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Next reward at $nextReward points',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.88),
                            ),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progress == 0 ? 0.02 : progress,
                          minHeight: 10,
                          backgroundColor: Colors.white.withValues(alpha: 0.16),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                PremiumModeSurface(
                  borderRadius: 20,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 42,
                        width: 42,
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.info_outline, color: Colors.amber),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Rewards are now synced to the production game backend. The balance shown here is the same score used by the game leaderboard and the rewards page.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                height: 1.45,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const PremiumModeSectionHeader(
                  title: 'Featured rewards',
                  subtitle: 'Premium perks from partner brands, unlocked by your eco game score.',
                ),
                const SizedBox(height: 12),
                ..._rewardCards(context),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _rewardCards(BuildContext context) {
    final rewards = [
      _RewardData('Zomato', '10% discount on selected orders', '100 points required', Colors.red, Icons.fastfood),
      _RewardData('Swiggy', 'Free delivery voucher', '150 points required', Colors.orange, Icons.delivery_dining),
      _RewardData('Amazon', 'Shopping coupon for eco essentials', '200 points required', Colors.black, Icons.shopping_bag_outlined),
      _RewardData('Flipkart', 'Extra savings on marketplace buys', '250 points required', Colors.blue, Icons.local_offer_outlined),
    ];

    return rewards
        .map(
          (reward) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: PremiumModeSurface(
              borderRadius: 24,
              child: Row(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: reward.color,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Icon(reward.icon, color: Colors.white, size: 34),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reward.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          reward.subtitle,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _Pill(label: reward.requirement),
                            _Pill(label: 'EcoByte exclusive'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .toList();
  }
}

class _RewardData {
  _RewardData(this.name, this.subtitle, this.requirement, this.color, this.icon);

  final String name;
  final String subtitle;
  final String requirement;
  final Color color;
  final IconData icon;
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : const Color(0xFF1A5269).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
