import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aqua_sort/features/lobby/providers/level_provider.dart';
import 'package:aqua_sort/features/profile/models/skin_catalogue.dart';

/// Resolves the active skin id → TubeSkin object.
final activeSkinProvider = Provider<TubeSkin>((ref) {
  final id = ref.watch(levelProvider.select((p) => p.activeSkinId));
  return SkinCatalogue.byId(id);
});

/// Lists all skins the player owns as TubeSkin objects.
final ownedSkinsProvider = Provider<List<TubeSkin>>((ref) {
  final ownedIds = ref.watch(levelProvider.select((p) => p.ownedSkinIds));
  return SkinCatalogue.all.where((s) => ownedIds.contains(s.id)).toList();
});

/// Notifier for skin equip/purchase actions.
class SkinNotifier extends StateNotifier<void> {
  final Ref _ref;
  SkinNotifier(this._ref) : super(null);

  Future<void> equip(String skinId) async {
    await _ref.read(levelProvider.notifier).equipSkin(skinId);
  }

  /// Purchase a skin using Spider Gold Coins.
  /// Returns true on success.
  Future<bool> purchase(String skinId, int price) async {
    final progress = _ref.read(levelProvider);
    if (progress.ownedSkinIds.contains(skinId)) return false;
    if (progress.spiderGoldCoins < price) return false;

    // Deduct Gold Coins
    await _ref.read(levelProvider.notifier).awardWebSpiderCurrency(
      'gold',
      -price,
      'skin_purchase_$skinId',
    );

    // Add skin to owned
    final success = await _ref.read(levelProvider.notifier).purchaseSkin(skinId, 0);
    return success;
  }
}

final skinNotifierProvider = StateNotifierProvider<SkinNotifier, void>(
  (ref) => SkinNotifier(ref),
);

// Helper widget — animated mini tube preview for shop grid
class MiniTubePreview extends StatefulWidget {
  final TubeSkin skin;
  final double height;
  final double width;

  const MiniTubePreview({
    super.key,
    required this.skin,
    this.height = 90,
    this.width = 36,
  });

  @override
  State<MiniTubePreview> createState() => _MiniTubePreviewState();
}

class _MiniTubePreviewState extends State<MiniTubePreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))
        ..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: _MiniTubePainter(
          skin: widget.skin,
          wave: _ctrl.value,
        ),
        size: Size(widget.width, widget.height),
      ),
    );
  }
}

class _MiniTubePainter extends CustomPainter {
  final TubeSkin skin;
  final double wave;

  _MiniTubePainter({required this.skin, required this.wave});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = w / 2;
    final lipH = h * 0.08;

    final tubePath = SkinCatalogue.getTubePath(skin.id, w, h, lipH, r);

    canvas.save();
    canvas.clipPath(tubePath);

    // Dark background
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h),
        Paint()..color = const Color(0xFF0D1F2D));

    // Draw 3 liquid layers from bottom
    final colors = skin.liquidColors;
    const segments = 3;
    final segH = (h - lipH) / segments;

    for (int i = 0; i < segments; i++) {
      final color = colors[i % colors.length];
      final top = h - (i + 1) * segH;
      // Animate wave on topmost layer
      final waveOffset = (i == segments - 1) ? 3.0 * (0.5 - (wave % 0.5)) : 0.0;

      final path = Path()
        ..moveTo(0, top + waveOffset)
        ..cubicTo(w * 0.3, top - 3 + waveOffset, w * 0.7, top + 3 + waveOffset, w, top + waveOffset)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close();

      canvas.drawPath(path, Paint()..color = color.withOpacity(0.9));
    }

    // Shine
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.15, lipH + 2)
        ..quadraticBezierTo(w * 0.08, h * 0.55, w * 0.18, h * 0.75)
        ..lineTo(w * 0.28, h * 0.75)
        ..quadraticBezierTo(w * 0.25, h * 0.52, w * 0.28, lipH + 2)
        ..close(),
      Paint()..color = Colors.white.withOpacity(0.1),
    );

    canvas.restore();

    // Border + glow
    canvas.drawPath(
      tubePath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = skin.borderColor.withOpacity(0.8),
    );

    // Lip
    final bounds = SkinCatalogue.getTubeTopBounds(skin.id, w);
    canvas.drawLine(
      Offset(bounds[0], lipH),
      Offset(bounds[1], lipH),
      Paint()..color = Colors.white.withOpacity(0.35)..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_MiniTubePainter old) => old.wave != wave || old.skin.id != skin.id;
}

// Large tube preview for detail screen
class LargeTubePreview extends StatefulWidget {
  final TubeSkin skin;
  const LargeTubePreview({super.key, required this.skin});

  @override
  State<LargeTubePreview> createState() => _LargeTubePreviewState();
}

class _LargeTubePreviewState extends State<LargeTubePreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(seconds: 4))
        ..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: _LargeTubePainter(skin: widget.skin, wave: _ctrl.value),
        size: const Size(110, 260),
      ),
    );
  }
}

class _LargeTubePainter extends CustomPainter {
  final TubeSkin skin;
  final double wave;

  _LargeTubePainter({required this.skin, required this.wave});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = w / 2;
    final lipH = h * 0.07;

    final tubePath = SkinCatalogue.getTubePath(skin.id, w, h, lipH, r);

    // Outer glow
    canvas.drawPath(
      tubePath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..color = skin.glowColor.withOpacity(0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 14),
    );

    canvas.save();
    canvas.clipPath(tubePath);

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h),
        Paint()..color = const Color(0xFF0D1F2D));

    final colors = skin.liquidColors;
    const segments = 4;
    final segH = (h - lipH) / segments;

    for (int i = 0; i < segments; i++) {
      final color = colors[i % colors.length];
      final top = h - (i + 1) * segH;
      final waveOffset = (i == segments - 1)
          ? 6.0 * (0.5 - (wave % 0.5))
          : 0.0;

      final path = Path()
        ..moveTo(0, top + waveOffset)
        ..cubicTo(
          w * 0.3, top - 5 + waveOffset,
          w * 0.7, top + 5 + waveOffset,
          w, top + waveOffset,
        )
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close();

      canvas.drawPath(path, Paint()..color = color.withOpacity(0.88));
    }

    // Shine
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.12, lipH + 4)
        ..quadraticBezierTo(w * 0.06, h * 0.55, w * 0.16, h * 0.75)
        ..lineTo(w * 0.28, h * 0.75)
        ..quadraticBezierTo(w * 0.22, h * 0.52, w * 0.26, lipH + 4)
        ..close(),
      Paint()..color = Colors.white.withOpacity(0.14),
    );

    canvas.restore();

    // Border
    canvas.drawPath(
      tubePath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = skin.borderColor,
    );

    // Lip
    final bounds = SkinCatalogue.getTubeTopBounds(skin.id, w);
    canvas.drawLine(
      Offset(bounds[0], lipH),
      Offset(bounds[1], lipH),
      Paint()..color = Colors.white.withOpacity(0.45)..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_LargeTubePainter old) => old.wave != wave || old.skin.id != skin.id;
}
