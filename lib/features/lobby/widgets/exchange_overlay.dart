import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aqua_sort/core/theme/app_colors.dart';
import 'package:aqua_sort/features/lobby/providers/level_provider.dart';
import 'package:aqua_sort/features/auth/providers/auth_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:aqua_sort/features/lobby/widgets/daily_reward_dialog.dart';

// ── Skin catalogue ─────────────────────────────────────────────────────────────

class _SkinDef {
  final String id;
  final String name;
  final String tier; // 'standard' | 'premium' | 'legendary'
  final int price;
  final Color primaryColor;
  final Color glowColor;
  final String emoji;

  const _SkinDef({
    required this.id,
    required this.name,
    required this.tier,
    required this.price,
    required this.primaryColor,
    required this.glowColor,
    required this.emoji,
  });
}

const _skins = [
  _SkinDef(
    id: 'toxic_slime', name: 'Toxic Slime', tier: 'standard', price: 500,
    primaryColor: Color(0xFF76FF03), glowColor: Color(0xFF64DD17), emoji: '☠️',
  ),
  _SkinDef(
    id: 'solar_flare', name: 'Solar Flare', tier: 'standard', price: 500,
    primaryColor: Color(0xFFFFAB40), glowColor: Color(0xFFFF6D00), emoji: '🌞',
  ),
  _SkinDef(
    id: 'arctic_frost', name: 'Arctic Frost', tier: 'standard', price: 500,
    primaryColor: Color(0xFF80DEEA), glowColor: Color(0xFF00B8D4), emoji: '❄️',
  ),
  _SkinDef(
    id: 'cyber_neon', name: 'Cyber Neon', tier: 'premium', price: 1500,
    primaryColor: Color(0xFF00E5FF), glowColor: Color(0xFF00B8D4), emoji: '🤖',
  ),
  _SkinDef(
    id: 'void_matter', name: 'Void Matter', tier: 'premium', price: 1500,
    primaryColor: Color(0xFFCE93D8), glowColor: Color(0xFF7B1FA2), emoji: '🌌',
  ),
  _SkinDef(
    id: 'sig_reveal', name: 'Sig Reveal', tier: 'legendary', price: 5000,
    primaryColor: Color(0xFFFFD700), glowColor: Color(0xFFFF8F00), emoji: '👑',
  ),
];

// ── Main overlay ───────────────────────────────────────────────────────────────

class ExchangeOverlay extends ConsumerStatefulWidget {
  const ExchangeOverlay({super.key});

  @override
  ConsumerState<ExchangeOverlay> createState() => _ExchangeOverlayState();
}

class _ExchangeOverlayState extends ConsumerState<ExchangeOverlay> {
  String _selectedTier = 'all';
  String? _purchasing;      // skinId currently being purchased
  String? _errorMsg;

  List<_SkinDef> get _filteredSkins => _selectedTier == 'all'
      ? _skins
      : _skins.where((s) => s.tier == _selectedTier).toList();

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(levelProvider);
    final auth = ref.watch(authProvider);
    final walletCoins = auth.user?.coins ?? progress.coins;
    final isGuest = auth.status == AuthStatus.guest;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Blurred background
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(color: Colors.black.withOpacity(0.6)),
            ),
          ),

          // The Exchange Console
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.92,
              height: MediaQuery.of(context).size.height * 0.82,
              decoration: BoxDecoration(
                color: AppColors.deepNavy.withOpacity(0.92),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: AppColors.tealAccent.withOpacity(0.5), width: 1.5),
                boxShadow: [
                  BoxShadow(color: AppColors.cyanGlow.withOpacity(0.18), blurRadius: 50),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Column(
                  children: [
                    _buildHeader(context, walletCoins, isGuest),
                    _buildTierFilter(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_errorMsg != null) _buildErrorBanner(),
                            if (!isGuest) ...[
                              _buildDailyRewardCard(),
                              const SizedBox(height: 28),
                            ],
                            _buildTierLegend(),
                            const SizedBox(height: 12),
                            _buildSkinsGrid(progress),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ).animate()
              .scale(begin: const Offset(0.88, 0.88), curve: Curves.easeOutBack, duration: 450.ms)
              .fadeIn(duration: 250.ms),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, int coins, bool isGuest) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'PURITY EXCHANGE',
                    style: GoogleFonts.righteous(
                      fontSize: 18, 
                      color: Colors.white, 
                      letterSpacing: 1.2
                    ),
                  ),
                ),
                Text(
                  'Spend coins. Unlock power.',
                  style: GoogleFonts.outfit(
                    fontSize: 11, 
                    color: AppColors.textMuted
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Wallet display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🪙', style: TextStyle(fontSize: 15)),
                const SizedBox(width: 4),
                Text(
                  '$coins',
                  style: GoogleFonts.righteous(
                    fontSize: 16,
                    color: const Color(0xFFFFD700),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white60, size: 20),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // ── Tier filter chips ─────────────────────────────────────────────────────

  Widget _buildTierFilter() {
    const tabs = [
      ('all', 'All'),
      ('standard', 'Standard'),
      ('premium', 'Premium'),
      ('legendary', 'Legendary'),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.map((t) {
            final selected = _selectedTier == t.$1;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _selectedTier = t.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.tealAccent : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? AppColors.tealAccent : Colors.white24,
                    ),
                  ),
                  child: Text(
                    t.$2,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: selected ? Colors.black : Colors.white60,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Error banner ──────────────────────────────────────────────────────────

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMsg!,
              style: GoogleFonts.outfit(fontSize: 13, color: Colors.redAccent),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _errorMsg = null),
            child: const Icon(Icons.close, color: Colors.red, size: 16),
          ),
        ],
      ),
    );
  }

  // ── Daily reward ──────────────────────────────────────────────────────────

  Widget _buildDailyRewardCard() {
    final progress = ref.watch(levelProvider);
    final lastClaim = progress.lastDailyClaimAt;
    final streak = progress.dailyStreakCount;

    bool claimAvailable = false;
    if (lastClaim == null) {
      claimAvailable = true;
    } else {
      final diff = DateTime.now().difference(lastClaim);
      if (diff >= const Duration(hours: 24)) {
        claimAvailable = true;
      }
    }

    final nextStreakDay = (lastClaim != null && DateTime.now().difference(lastClaim) < const Duration(hours: 48))
        ? (streak >= 7 ? 1 : streak + 1)
        : 1;

    final String subtitleText = claimAvailable 
        ? "Day $nextStreakDay reward is ready to claim!"
        : "Current Streak: $streak ${streak == 1 ? 'day' : 'days'}";

    final String buttonText = claimAvailable ? "CLAIM" : "VIEW";

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.tealAccent.withOpacity(0.18), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.tealAccent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Text('🎁', style: TextStyle(fontSize: 36)),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daily Resonance Boost',
                    style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(subtitleText,
                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.white60)),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.tealAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () {
              DailyRewardDialog.show(context);
            },
            child: Text(buttonText, style: GoogleFonts.righteous(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  // ── Tier legend ───────────────────────────────────────────────────────────

  Widget _buildTierLegend() {
    return Row(
      children: [
        _tierTag('STANDARD', Colors.blueGrey),
        const SizedBox(width: 8),
        _tierTag('PREMIUM', AppColors.tealAccent),
        const SizedBox(width: 8),
        _tierTag('LEGENDARY', const Color(0xFFFFD700)),
      ],
    );
  }

  Widget _tierTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
        color: color.withOpacity(0.06),
      ),
      child: Text(
        label,
        style: GoogleFonts.righteous(fontSize: 10, color: color, letterSpacing: 1.5),
      ),
    );
  }

  // ── Skins grid ────────────────────────────────────────────────────────────

  Widget _buildSkinsGrid(LevelProgress progress) {
    final skins = _filteredSkins;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.68,
      ),
      itemCount: skins.length,
      itemBuilder: (context, i) {
        final s = skins[i];
        final isOwned = progress.ownedSkinIds.contains(s.id);
        final isActive = progress.activeSkinId == s.id;
        final isBuying = _purchasing == s.id;

        return _SkinCard(
          skin: s,
          isOwned: isOwned,
          isActive: isActive,
          isBuying: isBuying,
          playerCoins: progress.coins,
          onBuy: () => _handlePurchase(s, progress.coins),
          onEquip: () => ref.read(levelProvider.notifier).equipSkin(s.id),
        ).animate().fadeIn(delay: (i * 60).ms).slideY(begin: 0.1, curve: Curves.easeOut, delay: (i * 60).ms);
      },
    );
  }

  Future<void> _handlePurchase(_SkinDef skin, int coins) async {
    if (coins < skin.price) {
      setState(() => _errorMsg = 'Not enough coins! You need ${skin.price - coins} more 🪙');
      return;
    }

    setState(() {
      _purchasing = skin.id;
      _errorMsg = null;
    });

    final success = await ref.read(levelProvider.notifier).purchaseSkin(skin.id, skin.price);

    setState(() => _purchasing = null);

    if (!success) {
      setState(() => _errorMsg = 'Transaction failed. Please try again.');
    }
  }
}

// ── Skin card ──────────────────────────────────────────────────────────────────

class _SkinCard extends StatelessWidget {
  final _SkinDef skin;
  final bool isOwned;
  final bool isActive;
  final bool isBuying;
  final int playerCoins;
  final VoidCallback onBuy;
  final VoidCallback onEquip;

  const _SkinCard({
    required this.skin,
    required this.isOwned,
    required this.isActive,
    required this.isBuying,
    required this.playerCoins,
    required this.onBuy,
    required this.onEquip,
  });

  Color get _tierAccent {
    switch (skin.tier) {
      case 'legendary':
        return const Color(0xFFFFD700);
      case 'premium':
        return AppColors.tealAccent;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final canAfford = playerCoins >= skin.price;

    return GestureDetector(
      onTap: isOwned
          ? (isActive ? null : onEquip)
          : (canAfford ? onBuy : null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: isActive
              ? _tierAccent.withOpacity(0.1)
              : isOwned
                  ? Colors.white.withOpacity(0.04)
                  : canAfford
                      ? Colors.white.withOpacity(0.03)
                      : Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? _tierAccent
                : isOwned
                    ? _tierAccent.withOpacity(0.35)
                    : Colors.white.withOpacity(0.1),
            width: isActive ? 1.5 : 1,
          ),
          boxShadow: isActive
              ? [BoxShadow(color: _tierAccent.withOpacity(0.25), blurRadius: 20)]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Tier badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: _tierAccent.withOpacity(0.12),
                      border: Border.all(color: _tierAccent.withOpacity(0.3)),
                    ),
                    child: Text(
                      skin.tier.toUpperCase(),
                      style: GoogleFonts.righteous(fontSize: 9, color: _tierAccent, letterSpacing: 1),
                    ),
                  ),
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: _tierAccent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('ON',
                          style: GoogleFonts.righteous(fontSize: 9, color: Colors.black)),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Skin visual preview
              Container(
                width: 48, height: 68,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: skin.primaryColor.withOpacity(0.5), width: 2),
                  color: skin.primaryColor.withOpacity(0.06),
                  boxShadow: [
                    BoxShadow(color: skin.glowColor.withOpacity(0.3), blurRadius: 16, spreadRadius: 2),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(3, (j) => Container(
                    width: 24, height: 12,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: skin.primaryColor.withOpacity(0.6 + (j * 0.1)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  )),
                ),
              ),

              const SizedBox(height: 10),

              Text(
                skin.name,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: isOwned ? Colors.white : Colors.white60,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // Action button
              if (isOwned)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? _tierAccent.withOpacity(0.15) : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isActive ? _tierAccent.withOpacity(0.4) : Colors.white12,
                    ),
                  ),
                  child: Text(
                    isActive ? '✓ EQUIPPED' : 'EQUIP',
                    style: GoogleFonts.righteous(
                      fontSize: 12,
                      color: isActive ? _tierAccent : Colors.white54,
                      letterSpacing: 1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canAfford
                          ? _tierAccent.withOpacity(0.85)
                          : Colors.white10,
                      foregroundColor: canAfford ? Colors.black : Colors.white30,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 0,
                    ),
                    onPressed: isBuying || !canAfford ? null : onBuy,
                    child: isBuying
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black54),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('🪙', style: TextStyle(fontSize: 12)),
                              const SizedBox(width: 4),
                              Text(
                                '${skin.price}',
                                style: GoogleFonts.righteous(
                                  fontSize: 13,
                                  color: canAfford ? Colors.black : Colors.white30,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
