import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aqua_sort/core/theme/app_colors.dart';
import 'package:aqua_sort/features/auth/widgets/aqua_widgets.dart';

enum PauseGateResult { usedGold, usedBrass, watchedAd, goPremium, cancelled }

class PauseDialog extends StatelessWidget {
  final int pausesUsed;
  final bool isPremium;

  const PauseDialog({
    super.key,
    required this.pausesUsed,
    required this.isPremium,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.deepNavy.withOpacity(0.95),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.tealAccent.withOpacity(0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.cyanGlow.withOpacity(0.15),
                blurRadius: 30,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.pause_circle_outline, color: AppColors.tealAccent, size: 64),
              const SizedBox(height: 16),
              Text(
                'GAME PAUSED',
                style: GoogleFonts.righteous(
                  fontSize: 24,
                  color: Colors.white,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isPremium ? 'Premium: Unlimited Pauses' : 'Free Pauses Used: $pausesUsed/2',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 28),
              GlowButton(
                label: 'RESUME',
                icon: Icons.play_arrow_rounded,
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PauseGateDialog extends StatelessWidget {
  final int spiderGoldCoins;
  final int spiderBrassCoins;

  const PauseGateDialog({
    super.key,
    required this.spiderGoldCoins,
    required this.spiderBrassCoins,
  });

  @override
  Widget build(BuildContext context) {
    final canAffordGold = spiderGoldCoins >= 2;
    final canAffordBrass = spiderBrassCoins >= 20;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.deepNavy.withOpacity(0.95),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.purpleAccent.withOpacity(0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.purpleAccent.withOpacity(0.15),
                blurRadius: 30,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_clock_outlined, color: Colors.purpleAccent, size: 56),
              const SizedBox(height: 16),
              Text(
                'PAUSE LIMIT REACHED',
                style: GoogleFonts.righteous(
                  fontSize: 20,
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'You have used your 2 free pauses. Pay 2 Gold Coins, 20 Brass Coins, watch a rewarded ad, or upgrade to Premium to pause again.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Option 1: Use 2 Gold Coins
              _OptionRow(
                icon: Icons.grid_view_rounded,
                iconColor: Colors.amber,
                title: 'Spend 2 Gold Coins 🕸🥇',
                subtitle: canAffordGold ? 'Balance: $spiderGoldCoins' : 'Not enough Gold (Need 2)',
                enabled: canAffordGold,
                onTap: () => Navigator.pop(context, PauseGateResult.usedGold),
              ),
              const SizedBox(height: 8),

              // Option 1B: Use 20 Brass Coins
              _OptionRow(
                icon: Icons.grid_view_rounded,
                iconColor: Colors.orange,
                title: 'Spend 20 Brass Coins 🕸🟨',
                subtitle: canAffordBrass ? 'Balance: $spiderBrassCoins' : 'Not enough Brass (Need 20)',
                enabled: canAffordBrass,
                onTap: () => Navigator.pop(context, PauseGateResult.usedBrass),
              ),
              const SizedBox(height: 8),

              // Option 2: Watch Ad
              _OptionRow(
                icon: Icons.smart_display_rounded,
                iconColor: AppColors.tealAccent,
                title: 'Watch Ad to Pause 📺',
                subtitle: 'Get a pause + earn 10 Gold Coins',
                enabled: true,
                onTap: () => Navigator.pop(context, PauseGateResult.watchedAd),
              ),
              const SizedBox(height: 8),

              // Option 3: Go Premium
              _OptionRow(
                icon: Icons.workspace_premium_rounded,
                iconColor: const Color(0xFFE040FB),
                title: 'Go Premium',
                subtitle: 'Unlimited pauses and undos forever',
                enabled: true,
                isPremiumOption: true,
                onTap: () => Navigator.pop(context, PauseGateResult.goPremium),
              ),
              const SizedBox(height: 20),

              // Cancel
              GestureDetector(
                onTap: () => Navigator.pop(context, PauseGateResult.cancelled),
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

class _OptionRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool enabled;
  final bool isPremiumOption;
  final VoidCallback onTap;

  const _OptionRow({
    required this.icon,
    required this.iconColor,
    required this.title,
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
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor.withOpacity(0.15),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    Text(subtitle,
                        style: GoogleFonts.outfit(
                            color: AppColors.textMuted, fontSize: 10)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
