import 'package:e_waste/app/data/supabase_repository.dart';
import 'package:e_waste/app/widgets/premium_ui.dart';
import 'package:e_waste/app/widgets/theme_toggle_icon_button.dart';
import 'package:e_waste/pages/quiz/quiz_page.dart';
import 'package:flutter/material.dart';

const String _ewasteGameSlug = 'ewaste-sorter';

class QuizMain extends StatefulWidget {
  const QuizMain({super.key});

  @override
  State<QuizMain> createState() => _QuizMainState();
}

class _QuizMainState extends State<QuizMain> {
  late Future<_GameHubData> _hubFuture;

  @override
  void initState() {
    super.initState();
    _hubFuture = _loadHubData();
  }

  Future<_GameHubData> _loadHubData() async {
    final rewardPoints = await SupabaseRepository.fetchCurrentRewardPoints();
    final game = await SupabaseRepository.fetchGameBySlug(_ewasteGameSlug);

    final leaderboard = game == null
        ? <Map<String, dynamic>>[]
        : await _loadLeaderboard(game['id'].toString());

    return _GameHubData(
      rewardPoints: rewardPoints,
      game: game,
      leaderboard: leaderboard,
    );
  }

  Future<List<Map<String, dynamic>>> _loadLeaderboard(String gameId) async {
    final rows = await SupabaseRepository.fetchLeaderboard(gameId: gameId, limit: 5);

    return Future.wait(rows.map((row) async {
      final userId = row['user_id']?.toString() ?? '';
      final profile = userId.isEmpty ? null : await SupabaseRepository.fetchProfile(userId);

      return {
        ...row,
        'display_name': (profile?['name'] ?? '').toString().trim(),
      };
    }));
  }

  void _refresh() {
    setState(() {
      _hubFuture = _loadHubData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_GameHubData>(
      future: _hubFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const PremiumShell(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data ?? const _GameHubData(rewardPoints: 0, game: null, leaderboard: []);
        final game = data.game;
        final leaderboard = data.leaderboard;
        final canPlay = game != null;

        return PremiumShell(
          appBar: AppBar(
            title: const Text('E-waste Game Lab'),
            actions: [
              const ThemeToggleIconButton(),
              IconButton(
                onPressed: _refresh,
                tooltip: 'Refresh game hub',
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
                PremiumSurface(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF123447), Color(0xFF2C8C6B)],
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
                            child: const Icon(Icons.sports_esports, color: Colors.white, size: 30),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Play to clean the planet.',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Sort e-waste correctly, earn rewards, and climb the leaderboard.',
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
                      Row(
                        children: [
                          Expanded(
                            child: _StatChip(label: 'Rewards', value: '${data.rewardPoints} pts'),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: _StatChip(label: 'Rounds', value: '8 missions'),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: _StatChip(label: 'Mode', value: 'Timed sorter'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: canPlay
                            ? () {
                                Navigator.of(context).push(
                                  premiumPageRoute(const QuizPage()),
                                );
                              }
                            : null,
                        icon: const Icon(Icons.play_arrow),
                        label: Text(canPlay ? 'Start mission' : 'Seed game first'),
                      ),
                      if (!canPlay) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Seed a `games` row with slug `ewaste-sorter` before launching the game.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.84),
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                PremiumSurface(
                  borderRadius: 22,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How it works',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 12),
                      const _GameRule(
                        icon: Icons.recycling_outlined,
                        title: 'Sort the item',
                        subtitle: 'Choose the right action: recycle, reuse, repair, or hazardous.',
                      ),
                      const _GameRule(
                        icon: Icons.local_fire_department_outlined,
                        title: 'Build streaks',
                        subtitle: 'Correct answers add combo points and boost your score.',
                      ),
                      const _GameRule(
                        icon: Icons.emoji_events_outlined,
                        title: 'Unlock rewards',
                        subtitle: 'The same score powers the Rewards screen and leaderboard.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                PremiumSurface(
                  borderRadius: 22,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Leaderboard',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ),
                          Text(
                            canPlay ? 'Top 5' : 'Waiting for seed',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (!canPlay)
                        Text(
                          'The leaderboard appears after you seed the game row in Supabase.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        )
                      else if (leaderboard.isEmpty)
                        Text(
                          'No scores yet. Be the first to set the pace for eco play.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        )
                      else
                        ...leaderboard.map(
                          (row) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _LeaderboardRow(
                              rank: (row['rank'] as num?)?.toInt() ?? 0,
                              userId: row['user_id']?.toString() ?? '',
                              displayName: row['display_name']?.toString() ?? '',
                              score: (row['best_score'] as num?)?.toInt() ?? 0,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GameHubData {
  const _GameHubData({
    required this.rewardPoints,
    required this.game,
    required this.leaderboard,
  });

  final int rewardPoints;
  final Map<String, dynamic>? game;
  final List<Map<String, dynamic>> leaderboard;
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 78,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameRule extends StatelessWidget {
  const _GameRule({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF1A5269).withValues(alpha: 0.10),
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
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({
    required this.rank,
    required this.userId,
    required this.displayName,
    required this.score,
  });

  final int rank;
  final String userId;
  final String displayName;
  final int score;

  String get _displayName {
    if (displayName.isNotEmpty) {
      return displayName;
    }

    if (userId.isEmpty) {
      return 'Player';
    }

    if (userId.length <= 8) {
      return 'Player $userId';
    }

    return 'Player ${userId.substring(0, 8)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF1A5269).withValues(alpha: 0.16),
            child: Text(
              '#$rank',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
          Text(
            '$score',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}