import 'dart:async';

import 'package:e_waste/app/data/supabase_repository.dart';
import 'package:e_waste/app/widgets/premium_ui.dart';
import 'package:e_waste/pages/quiz/result.dart';
import 'package:flutter/material.dart';

const String _ewasteGameSlug = 'ewaste-sorter';

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  static const Duration _roundDuration = Duration(seconds: 90);

  late Future<Map<String, dynamic>?> _gameFuture;
  Timer? _timer;

  Map<String, dynamic>? _game;
  List<_GameChallenge> _rounds = const <_GameChallenge>[];
  int _secondsRemaining = _roundDuration.inSeconds;
  int _currentRoundIndex = 0;
  int _score = 0;
  int _correct = 0;
  int _wrong = 0;
  int _streak = 0;
  bool _isLocked = false;
  bool _isSubmitting = false;
  bool _hasStarted = false;
  String? _feedback;
  String? _selectedBin;
  DateTime? _startedAt;

  @override
  void initState() {
    super.initState();
    _gameFuture = _loadGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<Map<String, dynamic>?> _loadGame() async {
    final game = await SupabaseRepository.fetchGameBySlug(_ewasteGameSlug);

    if (!mounted) {
      return game;
    }

    List<_GameChallenge> rounds = const <_GameChallenge>[];
    if (game != null) {
      final challengeRows = await SupabaseRepository.fetchGameChallenges(
        gameId: game['id'].toString(),
        limit: 8,
      );

      rounds = challengeRows.map((row) {
        return _GameChallenge(
          item: row['item']?.toString() ?? '',
          hint: row['hint']?.toString() ?? '',
          correctBin: row['correct_bin']?.toString() ?? '',
          points: (row['points'] as num?)?.toInt() ?? 0,
          explanation: row['explanation']?.toString() ?? '',
        );
      }).where((challenge) {
        return challenge.item.isNotEmpty &&
            challenge.hint.isNotEmpty &&
            challenge.correctBin.isNotEmpty &&
            challenge.explanation.isNotEmpty &&
            challenge.points > 0;
      }).toList(growable: false)
        ..shuffle();
    }

    setState(() {
      _game = game;
      _rounds = rounds;
    });

    if (game != null && rounds.isNotEmpty) {
      _startGame();
    }

    return game;
  }

  void _startGame() {
    if (_hasStarted || _game == null) {
      return;
    }

    _hasStarted = true;
    _startedAt = DateTime.now();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_isSubmitting) {
        return;
      }

      if (_secondsRemaining <= 1) {
        setState(() {
          _secondsRemaining = 0;
        });
        timer.cancel();
        _finishGame();
        return;
      }

      setState(() {
        _secondsRemaining--;
      });
    });
  }

  Future<void> _handleChoice(String selectedBin) async {
    if (_game == null || _isLocked || _isSubmitting || _currentRoundIndex >= _rounds.length) {
      return;
    }

    final round = _rounds[_currentRoundIndex];
    final isCorrect = selectedBin == round.correctBin;
    final rewardPoints = isCorrect ? round.points + (_streak * 2) : 0;

    setState(() {
      _isLocked = true;
      _selectedBin = selectedBin;
      _feedback = isCorrect
          ? '${round.item} is correctly sent to ${round.correctBin.toLowerCase()}.'
          : round.explanation;

      if (isCorrect) {
        _score += rewardPoints;
        _correct++;
        _streak++;
      } else {
        _wrong++;
        _streak = 0;
      }
    });

    await Future.delayed(const Duration(milliseconds: 650));

    if (!mounted) {
      return;
    }

    final isLastRound = _currentRoundIndex >= _rounds.length - 1;
    if (isLastRound) {
      setState(() {
        _currentRoundIndex = _rounds.length;
        _isLocked = false;
        _selectedBin = null;
      });
      await _finishGame();
      return;
    }

    setState(() {
      _currentRoundIndex++;
      _isLocked = false;
      _selectedBin = null;
      _feedback = null;
    });
  }

  Future<void> _finishGame() async {
    if (_isSubmitting) {
      return;
    }

    final game = _game;
    if (game == null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });
    _timer?.cancel();

    final durationSeconds = _startedAt == null
        ? null
        : DateTime.now().difference(_startedAt!).inSeconds;

    final submission = await SupabaseRepository.submitGameScore(
      gameId: game['id'].toString(),
      score: _score,
      durationSeconds: durationSeconds,
      metadata: {
        'correct': _correct,
        'wrong': _wrong,
        'rounds': _rounds.length,
        'streak': _streak,
        'game_slug': _ewasteGameSlug,
      },
    );

    if (!mounted) {
      return;
    }

    final rewardsPoints = (submission['rewards_points'] as num?)?.toInt();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (ctx) => ResultPage(
          gameName: game['name']?.toString() ?? 'E-waste Game Lab',
          score: _score,
          correctCount: _correct,
          totalRounds: _rounds.length,
          rewardsPoints: rewardsPoints,
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _gameFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const PremiumShell(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final game = snapshot.data ?? _game;

        if (game == null || _rounds.isEmpty) {
          return PremiumShell(
            appBar: AppBar(title: Text(game?['name']?.toString() ?? 'E-waste Sorter')),
            child: PremiumEmptyState(
              icon: Icons.construction_outlined,
              title: 'No challenges found',
              subtitle: 'Add active rows to the game_challenges table for this game and reopen the screen.',
            ),
          );
        }

        final isComplete = _currentRoundIndex >= _rounds.length;
        final currentRound = isComplete ? null : _rounds[_currentRoundIndex];

        return PremiumShell(
          appBar: AppBar(
            title: Text(game['name']?.toString() ?? 'E-waste Sorter'),
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
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
                                'E-waste sorting mission',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Choose the correct action for each item before the timer runs out.',
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
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _StatusChip(label: 'Score', value: '$_score'),
                        _StatusChip(label: 'Timer', value: _formatTime(_secondsRemaining)),
                        _StatusChip(label: 'Streak', value: '$_streak'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (isComplete)
                PremiumSurface(
                  borderRadius: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mission complete',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your score is being submitted to the leaderboard.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 14),
                      const Center(child: CircularProgressIndicator()),
                    ],
                  ),
                )
              else ...[
                PremiumSurface(
                  borderRadius: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mission ${_currentRoundIndex + 1} of ${_rounds.length}',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: const Color(0xFF1A5269),
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        currentRound!.item,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentRound.hint,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.45,
                  children: _actionOptions.map((bin) {
                    final selected = _selectedBin == bin;
                    return InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: _isLocked ? null : () => _handleChoice(bin),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFF1A5269).withValues(alpha: 0.12)
                              : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: selected
                                ? const Color(0xFF1A5269)
                                : Theme.of(context).dividerColor.withValues(alpha: 0.5),
                            width: selected ? 1.4 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_actionIcons[bin], color: const Color(0xFF1A5269), size: 28),
                            const SizedBox(height: 10),
                            Text(
                              bin,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                if (_feedback != null)
                  PremiumSurface(
                    borderRadius: 20,
                    child: Text(
                      _feedback!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.45,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                const SizedBox(height: 14),
                LinearProgressIndicator(
                  value: (_currentRoundIndex + 1) / _rounds.length,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(999),
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _GameChallenge {
  const _GameChallenge({
    required this.item,
    required this.hint,
    required this.correctBin,
    required this.points,
    required this.explanation,
  });

  final String item;
  final String hint;
  final String correctBin;
  final int points;
  final String explanation;
}

const List<String> _actionOptions = ['Recycle', 'Reuse', 'Repair', 'Hazardous'];

const Map<String, IconData> _actionIcons = {
  'Recycle': Icons.recycling_outlined,
  'Reuse': Icons.repeat_outlined,
  'Repair': Icons.build_outlined,
  'Hazardous': Icons.warning_amber_outlined,
};

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
