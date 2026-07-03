import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aqua_sort/core/theme/app_colors.dart';
import 'package:aqua_sort/features/auth/widgets/aqua_widgets.dart';
import 'package:aqua_sort/features/auth/providers/auth_provider.dart';
import 'package:aqua_sort/features/lobby/providers/level_provider.dart';
import 'package:aqua_sort/features/game/engine/game_engine.dart';
import 'package:aqua_sort/features/lobby/widgets/reservoir_widget.dart';
import 'package:aqua_sort/features/lobby/widgets/currency_pill.dart';
import 'package:aqua_sort/features/lobby/widgets/exchange_overlay.dart';
import 'package:aqua_sort/features/lobby/widgets/tutorial_overlay.dart';
import 'package:aqua_sort/features/game/providers/game_provider.dart';
import 'package:aqua_sort/features/lobby/widgets/level_map_widget.dart';
import 'package:aqua_sort/features/lobby/widgets/spider_coin_pill.dart';
import 'package:aqua_sort/features/lobby/widgets/spider_coin_store_dialog.dart';
import 'package:aqua_sort/features/lobby/widgets/webspider_vault_dialog.dart';
import 'package:aqua_sort/features/lobby/widgets/daily_reward_dialog.dart';
import 'package:aqua_sort/core/widgets/ad_banner_widget.dart';

class CampaignScreen extends ConsumerStatefulWidget {
  const CampaignScreen({super.key});

  @override
  ConsumerState<CampaignScreen> createState() => _CampaignScreenState();
}

class _CampaignScreenState extends ConsumerState<CampaignScreen> {
  bool _showTutorialManual = false;
  bool _tutorialChecked = false;
  bool _dailyRewardChecked = false;

  @override
  void initState() {
    super.initState();
    // Don't read tutorial state here — levelProvider._load() is async.
    // We defer the check to the first build where the loaded state is available.
  }

  /// Called from build() once the provider has finished loading from prefs.
  void _checkTutorial(bool isLoaded, bool tutorialSeen) {
    if (!isLoaded || _tutorialChecked) return;
    _tutorialChecked = true;
    if (!tutorialSeen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _showTutorialManual = true);
          ref.read(levelProvider.notifier).markTutorialSeen();
        }
      });
    }
  }

  void _checkDailyReward(bool isLoaded, DateTime? lastClaim) {
    if (!isLoaded || _dailyRewardChecked) return;
    _dailyRewardChecked = true;

    bool claimAvailable = false;
    if (lastClaim == null) {
      claimAvailable = true;
    } else {
      final diff = DateTime.now().difference(lastClaim);
      if (diff >= const Duration(hours: 24)) {
        claimAvailable = true;
      }
    }

    if (claimAvailable) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          DailyRewardDialog.show(context);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(levelProvider);

    // Safe to check now — levelProvider has emitted its loaded state.
    _checkTutorial(progress.isLoaded, progress.tutorialSeen);
    _checkDailyReward(progress.isLoaded, progress.lastDailyClaimAt);

    return Scaffold(
      body: Stack(
        children: [
          // ── The Living Reservoir ──────────────────────────────────────────
          const ReservoirBackground(),
          
          // ── Floating Level Nodes ──────────────────────────────────────────
          const LevelMapNodes(),
          
          // ── Header UI ──────────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _iconBtn(Icons.help_outline, () => setState(() => _showTutorialManual = true)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CurrencyPill(
                        coins: progress.coins,
                        onTapPlus: () {
                          showGeneralDialog(
                            context: context,
                            barrierDismissible: true,
                            barrierLabel: 'Exchange',
                            pageBuilder: (context, _, __) => const ExchangeOverlay(),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => WebSpiderVaultDialog.show(context),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Container(
                              height: 40,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.35),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.purpleAccent.withOpacity(0.45),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.purpleAccent.withOpacity(0.08),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.vpn_key_rounded, color: Colors.purpleAccent, size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    'VAULT',
                                    style: GoogleFonts.righteous(
                                      color: Colors.white,
                                      fontSize: 11,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 1,
                                    height: 16,
                                    color: Colors.purpleAccent.withOpacity(0.4),
                                  ),
                                  const SizedBox(width: 8),
                                  Image.asset(
                                    'assets/webspider_coins/GoldCoin.png',
                                    width: 16,
                                    height: 16,
                                    errorBuilder: (_, __, ___) => const Text('🕸🥇', style: TextStyle(fontSize: 11)),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${progress.spiderGoldCoins}',
                                    style: GoogleFonts.righteous(color: Colors.white, fontSize: 13),
                                  ),
                                  const SizedBox(width: 8),
                                  Image.asset(
                                    'assets/webspider_coins/CopperCoin.png',
                                    width: 16,
                                    height: 16,
                                    errorBuilder: (_, __, ___) => const Text('🕸🟫', style: TextStyle(fontSize: 11)),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${progress.spiderCopperCoins}',
                                    style: GoogleFonts.righteous(color: Colors.white, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // ── Bottom UI ──────────────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0, right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.only(top: 20, bottom: 40),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black.withOpacity(0.4), Colors.black.withOpacity(0.0)],
                      begin: Alignment.bottomCenter, end: Alignment.topCenter,
                    ),
                    border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GlowButton(
                        label: 'START LEVEL ${progress.currentLevel}',
                        onTap: () {
                          final diff = progress.currentLevel < 5 ? Difficulty.easy : 
                                       progress.currentLevel < 15 ? Difficulty.medium : Difficulty.hard;
                          ref.read(gameArgsProvider.notifier).state = GameArgs(
                            difficulty: diff,
                            playerCount: 1,
                          );
                          context.go('/game');
                        },
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _navBtn(Icons.radar_rounded, false, () => context.push('/multiplayer')),
                          _navBtn(Icons.palette_outlined, false, () => context.push('/customization')),
                          _navBtn(Icons.emoji_events_outlined, false, () => context.push('/leaderboard')),
                          _profileBtn(ref, () => context.push('/profile')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_showTutorialManual)
            Positioned.fill(
              child: TutorialOverlay(onClose: () => setState(() => _showTutorialManual = false)),
            ),

          // ── Banner Ad (passive, hidden for premium) ───────────────────────
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: AdBannerWidget(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.08),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white.withOpacity(0.8)),
        onPressed: onTap,
      ),
    );
  }



  Widget _navBtn(IconData icon, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: active ? AppColors.cyanGlow.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon, 
          color: active ? AppColors.cyanGlow : Colors.white.withOpacity(0.4),
          size: 30,
        ),
      ),
    );
  }

  Widget _profileBtn(WidgetRef ref, VoidCallback onTap) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
            boxShadow: [
               BoxShadow(color: Colors.black26, blurRadius: 4, spreadRadius: 1),
            ],
          ),
          child: ClipOval(
            child: user?.avatarUrl != null 
              ? Image.network(user!.avatarUrl!, fit: BoxFit.cover, 
                  errorBuilder: (_,__,___) => const Icon(Icons.account_circle, color: Colors.white38))
              : Icon(Icons.account_circle, color: Colors.white.withOpacity(0.5), size: 24),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONSODILATED CUSTOMIZATION SCREEN (RESCUE MODE)
// ─────────────────────────────────────────────────────────────────────────────

class CustomizationScreen extends ConsumerWidget {
  const CustomizationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(levelProvider);
    
    final skins = [
      {'id': 'default', 'name': 'Classic Glass', 'color': Colors.white.withOpacity(0.3)},
      {'id': 'cyber_neon', 'name': 'Cyber Neon', 'color': AppColors.cyanGlow},
      {'id': 'toxic_slime', 'name': 'Toxic Slime', 'color': Colors.greenAccent},
      {'id': 'solar_flare', 'name': 'Solar Flare', 'color': Colors.orangeAccent},
      {'id': 'void_matter', 'name': 'Void Matter', 'color': Colors.purpleAccent},
    ];

    final activeSkin = skins.firstWhere((s) => s['id'] == progress.activeSkinId, orElse: () => skins.first);
    final Color skinColor = (activeSkin['color'] as Color);

    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background Atmosphere ──────────────────────────────────────────
          const ReservoirBackground(),
          
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context),
                
                // ── Main Vessel Cavity ─────────────────────────────────────────
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _HolographicVessel(color: skinColor, activeId: progress.activeSkinId),
                        const SizedBox(height: 32),
                        Text(activeSkin['name'].toString().toUpperCase(), 
                          style: GoogleFonts.righteous(
                            fontSize: 24, color: Colors.white, letterSpacing: 6,
                            shadows: [Shadow(color: skinColor.withOpacity(0.5), blurRadius: 20)],
                          )),
                        const SizedBox(height: 12),
                        Container(height: 2, width: 60, 
                          decoration: BoxDecoration(color: skinColor, borderRadius: BorderRadius.circular(1))),
                      ],
                    ),
                  ),
                ),
                
                // ── Skin Selector Row ──────────────────────────────────────────
                _buildSkinSelector(context, ref, progress, skins),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go('/'),
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white12),
                color: Colors.black12,
              ),
              child: const Icon(Icons.home_outlined, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cyanGlow.withOpacity(0.3)),
                color: AppColors.cyanGlow.withOpacity(0.1),
              ),
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 20),
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.cyanGlow.withOpacity(0.5)),
              color: AppColors.deepNavy,
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset('assets/studio_logo_white.png', color: AppColors.cyanGlow),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AQUA SORT', style: GoogleFonts.righteous(fontSize: 32, color: Colors.white, letterSpacing: 4)),
                Text('WebSpider Studios | ALPHA 2.0', style: GoogleFonts.outfit(fontSize: 12, color: AppColors.tealAccent, letterSpacing: 2)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSkinLockedDialog(BuildContext context, String skinName) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'SkinLocked',
      barrierColor: Colors.black.withOpacity(0.85),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.deepNavy,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.amberAccent.withOpacity(0.5), width: 2),
              boxShadow: [
                BoxShadow(color: Colors.amberAccent.withOpacity(0.2), blurRadius: 40, spreadRadius: 5),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_person_outlined, size: 80, color: Colors.amberAccent).animate(onPlay: (c) => c.repeat())
                    .shimmer(duration: 2.seconds, color: Colors.white24)
                    .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), curve: Curves.easeInOut),
                  const SizedBox(height: 24),
                  Text(
                    'SIGNATURE LOCKED',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.righteous(
                      fontSize: 24,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "The '$skinName' series is reserved for elite alchemists. Build your wealth in the Campaign and claim your true style in the Global Exchange.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  GlowButton(
                    label: 'I WILL CLAIM IT',
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ).animate().scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack).fadeIn(),
        );
      },
    );
  }

  Widget _buildSkinSelector(BuildContext context, WidgetRef ref, LevelProgress progress, List<Map<String, dynamic>> skins) {
    return Container(
      height: 120,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: skins.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, i) {
          final s = skins[i];
          final isOwned = progress.ownedSkinIds.contains(s['id']);
          final isActive = progress.activeSkinId == s['id'];
          final color = (s['color'] as Color);
          
          return GestureDetector(
            onTap: () {
              if (isOwned) {
                ref.read(levelProvider.notifier).equipSkin(s['id'] as String);
              } else {
                _showSkinLockedDialog(context, s['name'].toString());
              }
            },
            child: Container(
              width: 85,
              decoration: BoxDecoration(
                color: isActive ? Colors.white.withOpacity(0.12) : Colors.black26,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isActive ? color : (isOwned ? Colors.white24 : Colors.white10),
                  width: isActive ? 2 : 1,
                ),
                boxShadow: isActive ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 12)] : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: isOwned ? color : Colors.grey.withOpacity(0.2),
                      shape: BoxShape.circle,
                      boxShadow: isOwned ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 10)] : null,
                    ),
                    child: isActive ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                  ),
                  const SizedBox(height: 12),
                  if (!isOwned) const Icon(Icons.lock_outline, size: 14, color: Colors.white38)
                  else Text('OWNED', style: GoogleFonts.outfit(fontSize: 10, color: Colors.white30, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HolographicVessel extends StatelessWidget {
  final Color color;
  final String activeId;
  const _HolographicVessel({required this.color, required this.activeId});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130, height: 240,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.4), width: 3),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.15), blurRadius: 40, spreadRadius: 5),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(27),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 70, height: 70,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: color.withOpacity(0.6), blurRadius: 30)],
                ),
              ).animate(onPlay: (c) => c.repeat())
               .shimmer(duration: 3.seconds, color: Colors.white30)
               .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.05, 1.05), curve: Curves.easeInOut),
            ],
          ),
        ),
      ),
    ).animate(key: ValueKey(activeId)).fadeIn().scale(begin: const Offset(0.9, 0.9));
  }
}
