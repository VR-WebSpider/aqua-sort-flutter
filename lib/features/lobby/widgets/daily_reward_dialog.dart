import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:aqua_sort/core/theme/app_colors.dart';
import 'package:aqua_sort/features/lobby/providers/level_provider.dart';
import 'package:aqua_sort/features/auth/widgets/aqua_widgets.dart';
import 'package:aqua_sort/core/widgets/coin_fly_animation.dart';

class DailyRewardDialog extends ConsumerStatefulWidget {
  const DailyRewardDialog({super.key});

  static void show(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'DailyReward',
      barrierColor: Colors.black.withOpacity(0.85),
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (context, anim1, anim2) => const DailyRewardDialog(),
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: Curves.easeOutBack.transform(anim1.value),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }

  @override
  ConsumerState<DailyRewardDialog> createState() => _DailyRewardDialogState();
}

class _DailyRewardDialogState extends ConsumerState<DailyRewardDialog> {
  Timer? _ticker;
  int _secondsRemaining = 0;
  bool _isClaiming = false;

  final List<Map<String, dynamic>> _streakRewards = [
    {'day': 1, 'type': 'copper', 'amount': 50, 'asset': 'assets/webspider_coins/CopperCoin.png'},
    {'day': 2, 'type': 'copper', 'amount': 100, 'asset': 'assets/webspider_coins/CopperCoin.png'},
    {'day': 3, 'type': 'brass', 'amount': 20, 'asset': 'assets/webspider_coins/BrassCoin.png'},
    {'day': 4, 'type': 'brass', 'amount': 50, 'asset': 'assets/webspider_coins/BrassCoin.png'},
    {'day': 5, 'type': 'silver', 'amount': 10, 'asset': 'assets/webspider_coins/SilverCoin.png'},
    {'day': 6, 'type': 'silver', 'amount': 20, 'asset': 'assets/webspider_coins/SilverCoin.png'},
    {'day': 7, 'type': 'gold', 'amount': 5, 'asset': 'assets/webspider_coins/GoldCoin.png'},
  ];

  @override
  void initState() {
    super.initState();
    _startCooldownCalculation();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _startCooldownCalculation() {
    _calculateRemainingTime();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _calculateRemainingTime();
    });
  }

  void _calculateRemainingTime() {
    final progress = ref.read(levelProvider);
    if (progress.lastDailyClaimAt == null) {
      if (mounted && _secondsRemaining != 0) {
        setState(() => _secondsRemaining = 0);
      }
      return;
    }

    final now = DateTime.now();
    final cooldownEnd = progress.lastDailyClaimAt!.add(const Duration(hours: 24));
    final diff = cooldownEnd.difference(now).inSeconds;

    if (mounted) {
      setState(() {
        _secondsRemaining = diff > 0 ? diff : 0;
      });
    }
  }

  String _formatDuration(int totalSeconds) {
    if (totalSeconds <= 0) return "00:00:00";
    final h = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return "$h:$m:$s";
  }

  Future<void> _claimDaily() async {
    if (_secondsRemaining > 0 || _isClaiming) return;
    setState(() => _isClaiming = true);

    try {
      final res = await ref.read(levelProvider.notifier).claimDailyReward();
      setState(() => _isClaiming = false);

      if (res['success'] == true) {
        if (!mounted) return;
        _showRewardSuccessDialog(
          context: context,
          title: 'STREAK CLAIMED!',
          rewardType: res['reward_type'] ?? 'copper',
          rewardAmount: res['reward_amount'] ?? 50,
          streakDay: res['streak_count'] ?? 1,
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Claim failed.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      setState(() => _isClaiming = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _claimMilestone(String milestoneId, int targetClaims, List<Map<String, dynamic>> rewards) async {
    if (_isClaiming) return;
    setState(() => _isClaiming = true);

    try {
      final res = await ref.read(levelProvider.notifier).claimMilestoneReward(milestoneId);
      setState(() => _isClaiming = false);

      if (res['success'] == true) {
        if (!mounted) return;
        _showMilestoneSuccessDialog(
          context: context,
          title: 'MILESTONE UNLOCKED!',
          targetClaims: targetClaims,
          rewards: rewards,
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Claim failed.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      setState(() => _isClaiming = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _showRewardSuccessDialog({
    required BuildContext context,
    required String title,
    required String rewardType,
    required int rewardAmount,
    required int streakDay,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.9),
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, anim1, anim2) {
        final coinName = rewardType.toUpperCase();
        final asset = 'assets/webspider_coins/${rewardType[0].toUpperCase()}${rewardType.substring(1)}Coin.png';

        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.deepNavy,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppColors.tealAccent, width: 2),
              boxShadow: [
                BoxShadow(color: AppColors.tealAccent.withOpacity(0.2), blurRadius: 40, spreadRadius: 5),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.righteous(
                      fontSize: 26,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Day $streakDay Streak Completed',
                    style: GoogleFonts.outfit(color: AppColors.tealAccent, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  Image.asset(
                    asset,
                    width: 100,
                    height: 100,
                  ).animate(onPlay: (c) => c.repeat())
                    .shimmer(duration: 1.5.seconds, color: Colors.white24)
                    .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), curve: Curves.easeInOut),
                  const SizedBox(height: 16),
                  Text(
                    '+$rewardAmount $coinName COINS',
                    style: GoogleFonts.righteous(
                      fontSize: 22,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Credited to your WebSpider Vault.',
                    style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 32),
                  GlowButton(
                    label: 'COSMIC EXCELLENT',
                    onTap: () {
                      Navigator.pop(context); // Close success dialog
                      _calculateRemainingTime();
                      CoinFlyAnimation.play(
                        context,
                        from: MediaQuery.of(context).size.center(Offset.zero),
                        isWebSpiderCoin: true,
                        coinAssetPath: asset,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showMilestoneSuccessDialog({
    required BuildContext context,
    required String title,
    required int targetClaims,
    required List<Map<String, dynamic>> rewards,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.9),
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.deepNavy,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.amberAccent, width: 2),
              boxShadow: [
                BoxShadow(color: Colors.amberAccent.withOpacity(0.2), blurRadius: 40, spreadRadius: 5),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.righteous(
                      fontSize: 26,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Unlocked for reaching $targetClaims total claims!',
                    style: GoogleFonts.outfit(color: Colors.amberAccent, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: rewards.map((r) {
                      final type = r['type'] as String;
                      final amt = r['amount'] as int;
                      final asset = 'assets/webspider_coins/${type[0].toUpperCase()}${type.substring(1)}Coin.png';
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Column(
                          children: [
                            Image.asset(asset, width: 64, height: 64)
                                .animate()
                                .shake(duration: 800.ms)
                                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
                            const SizedBox(height: 8),
                            Text(
                              '+$amt ${type.toUpperCase()}',
                              style: GoogleFonts.righteous(color: Colors.white, fontSize: 16),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Cosmic chest rewards placed in your vault.',
                    style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 32),
                  GlowButton(
                    label: 'INTO THE VAULT',
                    onTap: () {
                      Navigator.pop(context); // Close success dialog
                      int delay = 0;
                      for (final rw in rewards) {
                        final type = rw['type'] as String;
                        final assetPath = 'assets/webspider_coins/${type[0].toUpperCase()}${type.substring(1)}Coin.png';
                        Future.delayed(Duration(milliseconds: delay), () {
                          if (context.mounted) {
                            CoinFlyAnimation.play(
                              context,
                              from: MediaQuery.of(context).size.center(Offset.zero),
                              isWebSpiderCoin: true,
                              coinAssetPath: assetPath,
                            );
                          }
                        });
                        delay += 250;
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(levelProvider);
    final currentStreak = progress.dailyStreakCount;
    final totalClaims = progress.totalDailyClaims;
    final claimedMilestones = progress.claimedMilestones;

    // Check if next claim is ready (i.e. cooldown expired)
    final claimAvailable = _secondsRemaining <= 0;

    // Next streak day that will be claimed
    int nextStreakDay = 1;
    if (progress.lastDailyClaimAt != null) {
      final now = DateTime.now();
      final diff = now.difference(progress.lastDailyClaimAt!);
      if (diff < const Duration(hours: 48)) {
        if (currentStreak >= 7) {
          nextStreakDay = 1;
        } else {
          // If claim is available, it will be currentStreak + 1
          // If already claimed today (cooldown active), we show currentStreak as checked
          nextStreakDay = claimAvailable ? currentStreak + 1 : currentStreak;
        }
      }
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Glassmorphic Body ──────────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: Colors.black54, blurRadius: 30, spreadRadius: 10),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 12),
                      // ── Studio Header ──────────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset('assets/studio_logo_white.png', width: 24, height: 24),
                          const SizedBox(width: 8),
                          Text(
                            'WEBSPIDER STUDIOS',
                            style: GoogleFonts.righteous(
                              fontSize: 12,
                              color: AppColors.tealAccent,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'DAILY RESONANCE BOOST',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.righteous(
                          fontSize: 24,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Maintain your daily sorting streak to claim rarer cosmic coins.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── 7-Day Grid ─────────────────────────────────────────────
                      _buildDaysGrid(nextStreakDay, claimAvailable),
                      const SizedBox(height: 32),

                      // ── Milestone Section ──────────────────────────────────────
                      _buildMilestonesSection(totalClaims, claimedMilestones),
                      const SizedBox(height: 32),

                      // ── Claim Action ───────────────────────────────────────────
                      if (claimAvailable)
                        _isClaiming
                            ? const CircularProgressIndicator(color: AppColors.tealAccent)
                            : GlowButton(
                                label: 'CLAIM DAY $nextStreakDay REWARD',
                                onTap: _claimDaily,
                              ).animate(onPlay: (c) => c.repeat())
                                .shimmer(duration: 2.seconds, color: Colors.white30)
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'NEXT RESONANCE READY IN',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDuration(_secondsRemaining),
                                style: GoogleFonts.righteous(
                                  fontSize: 20,
                                  color: Colors.amberAccent,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Close Button ───────────────────────────────────────────────────
          Positioned(
            top: -12,
            right: -12,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.black87,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 1.5),
                  boxShadow: [
                    BoxShadow(color: Colors.black54, blurRadius: 10),
                  ],
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaysGrid(int nextStreakDay, bool claimAvailable) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Grid spacing parameters
        final double width = constraints.maxWidth;
        final double itemWidth = (width - (3 * 10)) / 4; // 4 columns layout

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _streakRewards.map((reward) {
            final day = reward['day'] as int;
            final asset = reward['asset'] as String;
            final type = reward['type'] as String;
            final amount = reward['amount'] as int;

            // Determine day status
            bool isClaimed = false;
            bool isClaimable = false;
            bool isLocked = false;

            if (day < nextStreakDay) {
              isClaimed = true;
            } else if (day == nextStreakDay) {
              if (claimAvailable) {
                isClaimable = true;
              } else {
                isClaimed = true; // Claimed today
              }
            } else {
              isLocked = true;
            }

            return Container(
              width: itemWidth,
              height: itemWidth * 1.25,
              decoration: BoxDecoration(
                color: isClaimable 
                    ? AppColors.tealAccent.withOpacity(0.12)
                    : (isClaimed ? Colors.white.withOpacity(0.04) : Colors.black38),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isClaimable 
                      ? AppColors.tealAccent
                      : (isClaimed ? Colors.white24 : Colors.white10),
                  width: isClaimable ? 2 : 1,
                ),
                boxShadow: isClaimable 
                    ? [BoxShadow(color: AppColors.tealAccent.withOpacity(0.15), blurRadius: 10)]
                    : null,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'DAY $day',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isClaimable 
                              ? AppColors.tealAccent 
                              : (isClaimed ? AppColors.textMuted : Colors.white30),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Opacity(
                        opacity: isLocked ? 0.35 : 1.0,
                        child: Image.asset(asset, width: 36, height: 36),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '+$amount',
                        style: GoogleFonts.righteous(
                          fontSize: 12,
                          color: isLocked ? Colors.white30 : Colors.white,
                        ),
                      ),
                      Text(
                        type.toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 7,
                          color: isLocked ? Colors.white24 : Colors.white60,
                        ),
                      ),
                    ],
                  ),
                  
                  // Checkmark Overlay for claimed days
                  if (isClaimed)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 28),
                      ),
                    ),

                  // Pulse animation for claimable day
                  if (isClaimable)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.tealAccent, width: 2),
                        ),
                      ).animate(onPlay: (c) => c.repeat())
                       .shimmer(duration: 1.5.seconds, color: Colors.white24)
                    ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildMilestonesSection(int totalClaims, Set<String> claimedMilestones) {
    // Milestones configuration
    final List<Map<String, dynamic>> milestones = [
      {
        'id': 'milestone_10',
        'target': 10,
        'rewards': [
          {'type': 'jade', 'amount': 10},
          {'type': 'silver', 'amount': 5},
        ]
      },
      {
        'id': 'milestone_25',
        'target': 25,
        'rewards': [
          {'type': 'diamond', 'amount': 5},
          {'type': 'silver', 'amount': 20},
        ]
      },
      {
        'id': 'milestone_50',
        'target': 50,
        'rewards': [
          {'type': 'obsidian', 'amount': 2},
          {'type': 'gold', 'amount': 10},
        ]
      },
    ];

    // Find progress percentage (caps at 50 max)
    final double progressPercent = (totalClaims / 50).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'LIFETIME RESONANCE MILESTONES',
              style: GoogleFonts.righteous(
                fontSize: 12,
                color: Colors.white70,
                letterSpacing: 1,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.tealAccent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.tealAccent.withOpacity(0.3)),
              ),
              child: Text(
                '$totalClaims Claims',
                style: GoogleFonts.righteous(
                  fontSize: 10,
                  color: AppColors.tealAccent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Progress Bar with overlay icons
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Track
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            
            // Fill progress
            FractionallySizedBox(
              widthFactor: progressPercent,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.tealAccent, Colors.amberAccent],
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(color: Colors.tealAccent.withOpacity(0.3), blurRadius: 4, spreadRadius: 1),
                  ],
                ),
              ),
            ),

            // Milestone Chests Indicators
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: milestones.map((m) {
                      final target = m['target'] as int;
                      final id = m['id'] as String;
                      final rewards = m['rewards'] as List<Map<String, dynamic>>;
                      final double posRatio = target / 50.0;
                      final double leftPos = (posRatio * width) - 16; // chest size offset

                      final hasReached = totalClaims >= target;
                      final isClaimed = claimedMilestones.contains(id);
                      final isClaimable = hasReached && !isClaimed;

                      IconData chestIcon = Icons.inventory_2_outlined;
                      Color chestColor = Colors.white30;

                      if (isClaimed) {
                        chestIcon = Icons.drafts_outlined;
                        chestColor = Colors.greenAccent;
                      } else if (isClaimable) {
                        chestIcon = Icons.card_giftcard;
                        chestColor = Colors.amberAccent;
                      } else if (hasReached) {
                        chestIcon = Icons.inventory_2;
                        chestColor = Colors.amberAccent.withOpacity(0.5);
                      }

                      return Positioned(
                        left: leftPos,
                        top: -12, // center chest on bar
                        child: GestureDetector(
                          onTap: isClaimable ? () => _claimMilestone(id, target, rewards) : null,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: isClaimable ? Colors.amber.withOpacity(0.2) : Colors.black87,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isClaimable 
                                        ? Colors.amberAccent 
                                        : (isClaimed ? Colors.greenAccent.withOpacity(0.5) : Colors.white10),
                                    width: isClaimable ? 2 : 1,
                                  ),
                                  boxShadow: isClaimable
                                      ? [BoxShadow(color: Colors.amberAccent.withOpacity(0.3), blurRadius: 8, spreadRadius: 1)]
                                      : null,
                                ),
                                child: Icon(
                                  chestIcon,
                                  color: chestColor,
                                  size: 16,
                                ),
                              ).animate(target: isClaimable ? 1.0 : 0.0, onPlay: (c) => c.repeat())
                               .shake(duration: 1.2.seconds, hz: 4)
                               .scale(begin: const Offset(1, 1), end: const Offset(1.08, 1.08), curve: Curves.easeInOut),
                              const SizedBox(height: 4),
                              Text(
                                '$target',
                                style: GoogleFonts.righteous(
                                  fontSize: 8,
                                  color: hasReached ? Colors.white : Colors.white24,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
