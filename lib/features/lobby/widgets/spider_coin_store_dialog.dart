import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aqua_sort/core/theme/app_colors.dart';
import 'package:aqua_sort/features/lobby/providers/level_provider.dart';
import 'package:aqua_sort/core/services/ad_service.dart';
import 'package:aqua_sort/features/profile/widgets/premium_purchase_dialog.dart';

class SpiderCoinStoreDialog extends ConsumerStatefulWidget {
  const SpiderCoinStoreDialog({super.key});

  static Future<void> show(BuildContext context) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'SpiderCoinStore',
      barrierColor: Colors.black.withOpacity(0.75),
      pageBuilder: (context, _, __) => const SpiderCoinStoreDialog(),
    );
  }

  @override
  ConsumerState<SpiderCoinStoreDialog> createState() => _SpiderCoinStoreDialogState();
}

class _SpiderCoinStoreDialogState extends ConsumerState<SpiderCoinStoreDialog> {
  bool _loading = false;
  String? _errorMsg;
  String? _successMsg;

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(levelProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              color: Colors.transparent,
            ),
          ),
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.88,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.deepNavy.withOpacity(0.95),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.purpleAccent.withOpacity(0.5), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purpleAccent.withOpacity(0.15),
                    blurRadius: 40,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🕸', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 10),
                      Text(
                        'SPIDER COINS',
                        style: GoogleFonts.righteous(
                          fontSize: 24,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Universal currency for all WebSpider Studios games.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Balances Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _balanceCard('Regular 🪙', progress.coins, Colors.amber),
                      _balanceCard('Spider 🕸', progress.spiderCoins, Colors.purpleAccent),
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (_errorMsg != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(_errorMsg!,
                          style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 12),
                          textAlign: TextAlign.center),
                    ),

                  if (_successMsg != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(_successMsg!,
                          style: GoogleFonts.outfit(color: AppColors.tealAccent, fontSize: 12),
                          textAlign: TextAlign.center),
                    ),

                  // Option 1: Watch Ad
                  _storeOption(
                    title: 'Watch Rewarded Video',
                    subtitle: 'Get +10 Spider Coins for free',
                    trailing: _actionBtn(
                      label: 'WATCH AD',
                      onPressed: _loading ? null : _watchAd,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Option 2: Exchange
                  _storeOption(
                    title: 'Exchange Coins',
                    subtitle: 'Convert 50 🪙 into 10 🕸',
                    trailing: _actionBtn(
                      label: 'EXCHANGE',
                      onPressed: (_loading || progress.coins < 50) ? null : _exchangeCoins,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Option 3: Go Premium
                  _storeOption(
                    title: 'Go Premium',
                    subtitle: 'Unlimited free undos and pauses',
                    trailing: _actionBtn(
                      label: 'UPGRADE',
                      isPremium: true,
                      onPressed: _loading ? null : _goPremium,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Close button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(
                      'Close Console',
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
        ],
      ),
    );
  }

  Widget _balanceCard(String label, int val, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text(
            val.toString(),
            style: GoogleFonts.righteous(fontSize: 18, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _storeOption({
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    )),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    )),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }

  Widget _actionBtn({
    required String label,
    required VoidCallback? onPressed,
    bool isPremium = false,
  }) {
    final Color color = isPremium ? Colors.purpleAccent : AppColors.tealAccent;
    return SizedBox(
      height: 36,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.black,
          disabledBackgroundColor: Colors.white10,
          disabledForegroundColor: Colors.white24,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: GoogleFonts.righteous(fontSize: 12),
        ),
      ),
    );
  }

  Future<void> _watchAd() async {
    setState(() {
      _loading = true;
      _errorMsg = null;
      _successMsg = null;
    });

    final reward = await AdService.instance.showRewardedAd(context);
    if (reward != null) {
      await ref.read(levelProvider.notifier).awardSpiderCoins(10, 'ad_reward_spider_coins');
      setState(() {
        _successMsg = 'Successfully awarded +10 Spider Coins! 🕸';
      });
    } else {
      setState(() {
        _errorMsg = 'Failed to watch ad. Please try again.';
      });
    }

    setState(() => _loading = false);
  }

  Future<void> _exchangeCoins() async {
    setState(() {
      _loading = true;
      _errorMsg = null;
      _successMsg = null;
    });

    final success = await ref.read(levelProvider.notifier).exchangeCoinsForSpiderCoins(50);
    if (success) {
      setState(() {
        _successMsg = 'Exchanged 50 🪙 for 10 Spider Coins! 🕸';
      });
    } else {
      setState(() {
        _errorMsg = 'Exchange failed. Please try again.';
      });
    }

    setState(() => _loading = false);
  }

  Future<void> _goPremium() async {
    final purchased = await PremiumPurchaseDialog.show(context);
    if (purchased) {
      setState(() {
        _successMsg = 'Welcome to Premium! Unlimited access unlocked.';
      });
    }
  }
}
