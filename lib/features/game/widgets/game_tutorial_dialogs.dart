import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aqua_sort/core/theme/app_colors.dart';
import 'package:aqua_sort/features/auth/widgets/aqua_widgets.dart';

class UndoTutorialDialog extends StatelessWidget {
  const UndoTutorialDialog({super.key});

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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.purpleAccent.withOpacity(0.15),
                ),
                child: const Icon(Icons.undo_rounded, color: Colors.purpleAccent, size: 48),
              ),
              const SizedBox(height: 20),
              Text(
                'FREE UNDOS EXHAUSTED',
                style: GoogleFonts.righteous(
                  fontSize: 22,
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'You get 2 free undos per level. Subsequent undos require Spider Coins 🕸, watching an ad, or upgrading to Premium for unlimited undos!',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              GlowButton(
                label: 'GOT IT',
                glowColor: Colors.purpleAccent,
                gradientColors: const [Color(0xFF8E24AA), Color(0xFFD81B60)],
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SpecialLevelTutorialDialog extends StatelessWidget {
  const SpecialLevelTutorialDialog({super.key});

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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.cyanGlow.withOpacity(0.15),
                ),
                child: const Icon(Icons.science_outlined, color: AppColors.tealAccent, size: 48),
              ),
              const SizedBox(height: 20),
              Text(
                'SPECIAL MYSTERY LEVEL',
                style: GoogleFonts.righteous(
                  fontSize: 22,
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Welcome to a Special Level! Every 5th level features Mystery Tubes 🧪 where the color of some layers is hidden. Pour to reveal the hidden colors!',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              GlowButton(
                label: 'START LEVEL',
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
