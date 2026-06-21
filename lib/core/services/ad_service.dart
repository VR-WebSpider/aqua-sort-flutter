import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aqua_sort/core/theme/app_colors.dart';
import 'economy_config.dart';

/// Simulated rewarded-ad service.
///
/// Shows a branded "watching ad" dialog with a countdown progress bar.
/// Returns [true] when the ad finishes, [false] if the user cancels.
///
/// Designed as a drop-in stub — swap the body of [showRewardedAd] for
/// `google_mobile_ads` when you're ready to go live.
class AdService {
  static final AdService instance = AdService._();
  AdService._();

  DateTime? _lastAdTime;

  /// Whether the cooldown has elapsed since the last ad.
  bool get canShowAd {
    if (_lastAdTime == null) return true;
    return DateTime.now().difference(_lastAdTime!).inSeconds >=
        EconomyConfig.adCooldownSeconds;
  }

  /// Show a simulated rewarded ad.
  /// Returns the coin reward on success, or `null` if cancelled/failed.
  Future<int?> showRewardedAd(BuildContext context) async {
    if (!canShowAd) return null;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _SimulatedAdDialog(),
    );

    if (result == true) {
      _lastAdTime = DateTime.now();
      return EconomyConfig.adRewardCoins;
    }
    return null;
  }
}

class _SimulatedAdDialog extends StatefulWidget {
  const _SimulatedAdDialog();

  @override
  State<_SimulatedAdDialog> createState() => _SimulatedAdDialogState();
}

class _SimulatedAdDialogState extends State<_SimulatedAdDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _completed = false;

  static const _adDuration = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _adDuration)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted) {
          setState(() => _completed = true);
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.deepNavy,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.tealAccent.withOpacity(0.4)),
          boxShadow: [
            BoxShadow(
              color: AppColors.cyanGlow.withOpacity(0.15),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.tealAccent.withOpacity(0.3),
                        AppColors.cyanGlow.withOpacity(0.1),
                      ],
                    ),
                  ),
                  child: const Icon(Icons.play_circle_fill_rounded,
                      color: AppColors.cyanGlow, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sponsored',
                          style: GoogleFonts.outfit(
                              color: AppColors.textMuted, fontSize: 10,
                              letterSpacing: 1.5, fontWeight: FontWeight.w600)),
                      Text('Watch for +${EconomyConfig.adRewardCoins} 🪙',
                          style: GoogleFonts.righteous(
                              color: Colors.white, fontSize: 16)),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Simulated ad area
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _completed ? Icons.check_circle_rounded : Icons.smart_display_rounded,
                      color: _completed ? AppColors.success : AppColors.tealAccent,
                      size: 36,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _completed ? 'Ad Complete!' : 'Playing Ad...',
                      style: GoogleFonts.outfit(
                        color: _completed ? AppColors.success : Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Progress bar
            AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _ctrl.value,
                  minHeight: 6,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation(
                    _completed ? AppColors.success : AppColors.tealAccent,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Action button
            if (_completed)
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.tealAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22)),
                  ),
                  child: Text('Claim ${EconomyConfig.adRewardCoins} 🪙',
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                ),
              )
            else
              GestureDetector(
                onTap: () => Navigator.of(context).pop(false),
                child: Text('Cancel',
                    style: GoogleFonts.outfit(
                        color: AppColors.textMuted, fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }
}
