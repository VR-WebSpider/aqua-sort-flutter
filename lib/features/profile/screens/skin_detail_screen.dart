import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aqua_sort/core/theme/app_colors.dart';
import 'package:aqua_sort/features/lobby/providers/level_provider.dart';
import 'package:aqua_sort/features/profile/models/skin_catalogue.dart';
import 'package:aqua_sort/features/profile/providers/skin_provider.dart';
import 'package:go_router/go_router.dart';

class SkinDetailScreen extends ConsumerStatefulWidget {
  final TubeSkin skin;
  const SkinDetailScreen({super.key, required this.skin});

  @override
  ConsumerState<SkinDetailScreen> createState() => _SkinDetailScreenState();
}

class _SkinDetailScreenState extends ConsumerState<SkinDetailScreen>
    with SingleTickerProviderStateMixin {
  late TubeSkin _current;
  bool _isLoading = false;

  late final AnimationController _nameCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );
  late final Animation<double> _nameAnim =
      CurvedAnimation(parent: _nameCtrl, curve: Curves.easeOut);

  @override
  void initState() {
    super.initState();
    _current = widget.skin;
    _nameCtrl.forward();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _switchSkin(TubeSkin skin) {
    if (skin.id == _current.id) return;
    setState(() => _current = skin);
    _nameCtrl.forward(from: 0);
  }

  Future<void> _onAction(
      BuildContext context, LevelProgress progress) async {
    final isOwned = progress.ownedSkinIds.contains(_current.id);
    final isActive = progress.activeSkinId == _current.id;

    if (isActive) return;

    if (isOwned) {
      // Equip
      setState(() => _isLoading = true);
      await ref.read(skinNotifierProvider.notifier).equip(_current.id);
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${_current.name} equipped!',
              style: GoogleFonts.outfit()),
          backgroundColor: AppColors.tealAccent.withOpacity(0.85),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
      return;
    }

    // Purchase flow
    if (progress.spiderGoldCoins < _current.price) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Not enough Spider Gold Coins!',
            style: GoogleFonts.outfit()),
        backgroundColor: AppColors.error.withOpacity(0.85),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }

    // Confirm dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _PurchaseConfirmDialog(skin: _current),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);
    final success = await ref
        .read(skinNotifierProvider.notifier)
        .purchase(_current.id, _current.price);
    setState(() => _isLoading = false);

    if (!mounted) return;
    if (success) {
      // Auto-equip after purchase
      await ref.read(skinNotifierProvider.notifier).equip(_current.id);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${_current.name} purchased & equipped! 🎉',
            style: GoogleFonts.outfit()),
        backgroundColor: const Color(0xFFFFD700).withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Purchase failed. Try again.',
            style: GoogleFonts.outfit()),
        backgroundColor: AppColors.error.withOpacity(0.85),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(levelProvider);
    final allSkins = SkinCatalogue.all;
    final ownedIds = progress.ownedSkinIds;
    final isOwned = ownedIds.contains(_current.id);
    final isActive = progress.activeSkinId == _current.id;

    return Scaffold(
      backgroundColor: const Color(0xFF030D1A),
      body: Stack(
        children: [
          // Starfield background
          const _StarfieldBg(),

          SafeArea(
            child: Column(
              children: [
                // ── Top Nav ───────────────────────────────────────────────
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      // Home button
                      _NavBtn(
                        icon: Icons.home_outlined,
                        onTap: () => context.go('/lobby'),
                      ),
                      const SizedBox(width: 10),
                      // Back button
                      _NavBtn(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => context.pop(),
                      ),
                      const Spacer(),
                      // Title area
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'AQUA\nSORT',
                            textAlign: TextAlign.right,
                            style: GoogleFonts.righteous(
                              fontSize: 18,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                          Text(
                            'WebSpider Studios | ALPHA 2.0',
                            style: GoogleFonts.outfit(
                              fontSize: 9,
                              color: AppColors.tealAccent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Large Tube Preview ─────────────────────────────────────
                Expanded(
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: ScaleTransition(
                            scale: Tween(begin: 0.85, end: 1.0).animate(anim),
                            child: child),
                      ),
                      child: LargeTubePreview(
                        key: ValueKey(_current.id),
                        skin: _current,
                      ),
                    ),
                  ),
                ),

                // ── Skin name ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: FadeTransition(
                    opacity: _nameAnim,
                    child: Column(
                      children: [
                        Text(
                          _current.name.toUpperCase(),
                          style: GoogleFonts.righteous(
                            fontSize: 22,
                            color: Colors.white,
                            letterSpacing: 3,
                          ),
                        ),
                        Container(
                          width: 40,
                          height: 2,
                          margin: const EdgeInsets.only(top: 6),
                          decoration: BoxDecoration(
                            color: _current.glowColor,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Gold coin balance ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.hexagon_rounded,
                          color: Color(0xFFFFD700), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${progress.spiderGoldCoins} Spider Gold Coins',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: const Color(0xFFFFD700).withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Action Button ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                  child: _ActionButton(
                    skin: _current,
                    isOwned: isOwned,
                    isActive: isActive,
                    isLoading: _isLoading,
                    onTap: () => _onAction(context, progress),
                  ),
                ),

                // ── Skin Carousel ──────────────────────────────────────────
                SizedBox(
                  height: 90,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    scrollDirection: Axis.horizontal,
                    itemCount: allSkins.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) {
                      final s = allSkins[i];
                      final owned = ownedIds.contains(s.id);
                      final active = s.id == _current.id;
                      return _CarouselTile(
                        skin: s,
                        owned: owned,
                        selected: active,
                        onTap: () => _switchSkin(s),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Navigation Button ──────────────────────────────────────────────────────────
class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white12),
        ),
        child: Icon(icon, color: Colors.white70, size: 18),
      ),
    );
  }
}

// ── Action Button ──────────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final TubeSkin skin;
  final bool isOwned;
  final bool isActive;
  final bool isLoading;
  final VoidCallback onTap;

  const _ActionButton({
    required this.skin,
    required this.isOwned,
    required this.isActive,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isActive) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.tealAccent.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.tealAccent.withOpacity(0.4)),
        ),
        child: Text(
          '✓  EQUIPPED',
          textAlign: TextAlign.center,
          style: GoogleFonts.righteous(
            fontSize: 15,
            color: AppColors.tealAccent,
            letterSpacing: 2,
          ),
        ),
      );
    }

    if (isOwned) {
      return GestureDetector(
        onTap: isLoading ? null : onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [skin.glowColor.withOpacity(0.8), skin.borderColor],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: isLoading
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  ),
                )
              : Text(
                  'EQUIP',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.righteous(
                    fontSize: 15,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
        ),
      );
    }

    // Not owned
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: isLoading
            ? const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.hexagon_rounded,
                      color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'BUY FOR ${skin.price} GOLD',
                    style: GoogleFonts.righteous(
                      fontSize: 14,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Carousel Tile ──────────────────────────────────────────────────────────────
class _CarouselTile extends StatelessWidget {
  final TubeSkin skin;
  final bool owned;
  final bool selected;
  final VoidCallback onTap;

  const _CarouselTile({
    required this.skin,
    required this.owned,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 64,
        height: 80,
        decoration: BoxDecoration(
          color: selected
              ? skin.glowColor.withOpacity(0.15)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? skin.glowColor : Colors.white12,
            width: selected ? 2 : 1,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            MiniTubePreview(skin: skin, height: 48, width: 22),
            if (!owned)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Icon(Icons.lock_outline_rounded,
                      color: Colors.white38, size: 18),
                ),
              ),
            if (owned && selected)
              Positioned(
                bottom: 4,
                child: Text(
                  'OWNED',
                  style: GoogleFonts.outfit(
                    fontSize: 7,
                    fontWeight: FontWeight.w700,
                    color: AppColors.tealAccent,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Purchase Confirm Dialog ────────────────────────────────────────────────────
class _PurchaseConfirmDialog extends StatelessWidget {
  final TubeSkin skin;
  const _PurchaseConfirmDialog({required this.skin});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0D1F2D),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LargeTubePreview(skin: skin),
            const SizedBox(height: 16),
            Text(
              skin.name,
              style: GoogleFonts.righteous(
                  fontSize: 20, color: Colors.white, letterSpacing: 2),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.hexagon_rounded,
                    color: Color(0xFFFFD700), size: 16),
                const SizedBox(width: 4),
                Text(
                  '${skin.price} Spider Gold Coins',
                  style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: const Color(0xFFFFD700),
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Text(
                        'CANCEL',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                            color: Colors.white54,
                            fontWeight: FontWeight.w600,
                            fontSize: 13),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'BUY',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.righteous(
                            color: Colors.white,
                            fontSize: 14,
                            letterSpacing: 1.5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Starfield Background ───────────────────────────────────────────────────────
class _StarfieldBg extends StatelessWidget {
  const _StarfieldBg();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _StarfieldPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _StarfieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const starCount = 80;
    final paint = Paint()..color = Colors.white;
    for (int i = 0; i < starCount; i++) {
      final x = (i * 137.508 % size.width);
      final y = (i * 97.311 % size.height);
      final r = (i % 3 == 0) ? 1.5 : 0.8;
      paint.color = Colors.white.withOpacity(0.1 + (i % 5) * 0.05);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(_StarfieldPainter old) => false;
}
