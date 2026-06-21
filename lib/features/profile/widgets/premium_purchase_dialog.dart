import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aqua_sort/core/theme/app_colors.dart';
import 'package:aqua_sort/features/profile/providers/premium_provider.dart';
import 'package:aqua_sort/features/auth/widgets/aqua_widgets.dart';
import 'package:aqua_sort/core/services/audio_service.dart';

class PremiumPurchaseDialog extends ConsumerWidget {
  const PremiumPurchaseDialog({super.key});

  static Future<bool> show(BuildContext context) async {
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'PremiumPurchase',
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return const Center(
          child: PremiumPurchaseDialog(),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 320,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.deepNavy,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.tealAccent.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: AppColors.tealAccent.withOpacity(0.15),
            blurRadius: 30,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon / Logo
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.tealAccent.withOpacity(0.1),
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: AppColors.tealAccent,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'GO PREMIUM',
              style: GoogleFonts.righteous(
                fontSize: 24,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Unlock the Ultimate Aqua Sorting Experience',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 24),
            
            // Feature List
            _buildFeatureRow('Unlimited Undos Forever'),
            _buildFeatureRow('Instant Revivals (No Ads)'),
            _buildFeatureRow('Ad-Free Gameplay'),
            _buildFeatureRow('Exclusive Cyber Themes'),
            
            const SizedBox(height: 28),
            
            // Upgrade button
            GlowButton(
              label: 'Upgrade for \$2.99',
              icon: Icons.flash_on_rounded,
              onTap: () async {
                await ref.read(premiumProvider.notifier).setPremium(true);
                await AudioService.instance.playLidClosing();
                if (context.mounted) {
                  Navigator.of(context).pop(true);
                }
              },
            ),
            const SizedBox(height: 12),
            
            // Cancel link
            GestureDetector(
              onTap: () => Navigator.of(context).pop(false),
              child: Text(
                'Maybe Later',
                style: GoogleFonts.outfit(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            color: AppColors.cyanGlow,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
