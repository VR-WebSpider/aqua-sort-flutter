import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:aqua_sort/core/services/ad_service.dart';
import 'package:aqua_sort/features/profile/providers/premium_provider.dart';

/// --------------------------------------------------------------------------
/// AdBannerWidget
/// --------------------------------------------------------------------------
/// A self-contained banner ad (320x50) widget.
///   - Hidden completely for premium users.
///   - Shows nothing until the ad has loaded (no blank space flash).
///   - Disposes the ad automatically when removed from the tree.
///   - Styled with a subtle dark separator to blend with the game theme.
///
class AdBannerWidget extends ConsumerStatefulWidget {
  const AdBannerWidget({super.key});

  @override
  ConsumerState<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends ConsumerState<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _adLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    final ad = AdService.instance.createBannerAd();
    // Override the listener to track load state in this widget
    _bannerAd = BannerAd(
      adUnitId: ad.adUnitId,
      size: ad.size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _adLoaded = true);
        },
        onAdFailedToLoad: (bannerAd, _) {
          bannerAd.dispose();
          if (mounted) setState(() => _adLoaded = false);
        },
      ),
    );
    _bannerAd!.load();
    // Dispose the initially created ad (it was just used to confirm config)
    ad.dispose();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(premiumProvider);
    if (isPremium || !_adLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.06), width: 1),
        ),
      ),
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
