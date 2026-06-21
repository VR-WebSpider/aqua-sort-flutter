import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aqua_sort/core/theme/app_colors.dart';
import 'package:aqua_sort/core/services/economy_config.dart';

/// Result of the undo-gate interaction.
enum UndoGateResult { usedGold, usedCopper, watchedAd, goPremium, cancelled }

class UndoGateSheet extends StatelessWidget {
  final int playerCoins;
  final int spiderGoldCoins;
  final int spiderCopperCoins;
  final bool isPremium;

  const UndoGateSheet({
    super.key,
    required this.playerCoins,
    required this.spiderGoldCoins,
    required this.spiderCopperCoins,
    required this.isPremium,
  });

  @override
  Widget build(BuildContext context) {
    final canAffordGold = spiderGoldCoins >= 5;
    final canAffordCopper = spiderCopperCoins >= 50;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      decoration: const BoxDecoration(
        color: AppColors.deepNavy,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(color: Colors.black54, blurRadius: 30, spreadRadius: 5),
        ],
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(height: 12),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_rounded,
                      color: AppColors.cyanGlow, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Extra Undo Required',
                    style: GoogleFonts.righteous(
                      color: Colors.white,
                      fontSize: 20,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              Text(
                'You\'ve used your ${EconomyConfig.freeUndoLimit} free undos this round.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 16),

              // Option 1: Spend 5 Gold Coins
              _OptionTile(
                icon: Icons.grid_view_rounded,
                iconColor: Colors.amber,
                label: 'Use 5 Gold Coins 🕸🥇',
                subtitle: canAffordGold ? 'Undo one move instantly (Gold Balance: $spiderGoldCoins)' : 'Not enough Gold Coins (Need 5)',
                enabled: canAffordGold,
                onTap: () => Navigator.of(context).pop(UndoGateResult.usedGold),
              ),

              const SizedBox(height: 8),

              // Option 1B: Spend 50 Copper Coins
              _OptionTile(
                icon: Icons.grid_view_rounded,
                iconColor: Colors.deepOrangeAccent,
                label: 'Use 50 Copper Coins 🕸🟫',
                subtitle: canAffordCopper ? 'Undo one move instantly (Copper Balance: $spiderCopperCoins)' : 'Not enough Copper Coins (Need 50)',
                enabled: canAffordCopper,
                onTap: () => Navigator.of(context).pop(UndoGateResult.usedCopper),
              ),

              const SizedBox(height: 8),

              // Option 2: Watch Ad
              _OptionTile(
                icon: Icons.smart_display_rounded,
                iconColor: AppColors.tealAccent,
                label: 'Watch Ad (+10 Gold)',
                subtitle: 'Earn Gold Coins to unlock undo',
                enabled: true,
                onTap: () => Navigator.of(context).pop(UndoGateResult.watchedAd),
              ),

              const SizedBox(height: 8),

              // Option 3: Go Premium
              _OptionTile(
                icon: Icons.workspace_premium_rounded,
                iconColor: const Color(0xFFE040FB),
                label: 'Go Premium',
                subtitle: 'Unlimited undos forever',
                enabled: true,
                isPremiumOption: true,
                onTap: () => Navigator.of(context).pop(UndoGateResult.goPremium),
              ),

              const SizedBox(height: 12),

              // Balance display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🕸🥇', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(
                      '$spiderGoldCoins',
                      style: GoogleFonts.outfit(
                        color: Colors.amber,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(width: 1, height: 12, color: Colors.white24),
                    const SizedBox(width: 12),
                    const Text('🕸🟫', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(
                      '$spiderCopperCoins',
                      style: GoogleFonts.outfit(
                        color: Colors.deepOrangeAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(width: 1, height: 12, color: Colors.white24),
                    const SizedBox(width: 12),
                    const Text('🪙', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(
                      '$playerCoins',
                      style: GoogleFonts.outfit(
                        color: Colors.cyanAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Cancel
              GestureDetector(
                onTap: () => Navigator.of(context).pop(UndoGateResult.cancelled),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.outfit(
                    color: AppColors.textMuted,
                    fontSize: 13,
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

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final bool enabled;
  final bool isPremiumOption;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
    this.isPremiumOption = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.4,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isPremiumOption
                ? const Color(0xFFE040FB).withOpacity(0.08)
                : Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPremiumOption
                  ? const Color(0xFFE040FB).withOpacity(0.3)
                  : Colors.white.withOpacity(0.08),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor.withOpacity(0.15),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    Text(subtitle,
                        style: GoogleFonts.outfit(
                            color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: Colors.white24, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
