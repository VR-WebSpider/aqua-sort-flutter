import 'dart:math' as math;
import 'package:flutter/material.dart';

class CoinFlyAnimation {
  static final GlobalKey normalCoinKey = GlobalKey();
  static final GlobalKey webspiderCoinKey = GlobalKey();

  static void play(
    BuildContext context, {
    required Offset from,
    required bool isWebSpiderCoin,
    String? coinAssetPath,
  }) {
    final overlay = Overlay.of(context);
    final targetKey = isWebSpiderCoin ? webspiderCoinKey : normalCoinKey;
    Offset targetOffset;

    try {
      final renderBox = targetKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        targetOffset = renderBox.localToGlobal(Offset.zero) +
            Offset(renderBox.size.width / 2, renderBox.size.height / 2);
      } else {
        final size = MediaQuery.of(context).size;
        targetOffset = isWebSpiderCoin ? Offset(110, 40) : Offset(size.width - 110, 40);
      }
    } catch (_) {
      final size = MediaQuery.of(context).size;
      targetOffset = isWebSpiderCoin ? Offset(110, 40) : Offset(size.width - 110, 40);
    }

    final coinPath = coinAssetPath ??
        (isWebSpiderCoin
            ? 'assets/webspider_coins/GoldCoin.png'
            : 'assets/webspider_coins/GoldCoin.png');

    final particles = List.generate(
      10,
      (i) => _CoinParticle(
        start: from,
        target: targetOffset,
        assetPath: coinPath,
        delayMs: i * 70, // Staggered spawn
        isEmoji: coinAssetPath == null && !isWebSpiderCoin,
      ),
    );

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: particles.map((p) => _CoinParticleWidget(
            particle: p,
            onFinished: () {
              if (particles.every((p) => p.isFinished)) {
                entry.remove();
              }
            },
          )).toList(),
        );
      },
    );

    overlay.insert(entry);
  }
}

class _CoinParticle {
  final Offset start;
  final Offset target;
  final String assetPath;
  final int delayMs;
  final bool isEmoji;
  bool isFinished = false;

  _CoinParticle({
    required this.start,
    required this.target,
    required this.assetPath,
    required this.delayMs,
    required this.isEmoji,
  });
}

class _CoinParticleWidget extends StatefulWidget {
  final _CoinParticle particle;
  final VoidCallback onFinished;

  const _CoinParticleWidget({
    required this.particle,
    required this.onFinished,
  });

  @override
  State<_CoinParticleWidget> createState() => _CoinParticleWidgetState();
}

class _CoinParticleWidgetState extends State<_CoinParticleWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Offset _randomScatter;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInCubic);

    final random = math.Random();
    final angle = random.nextDouble() * 2 * math.pi;
    final distance = 40.0 + random.nextDouble() * 60.0;
    _randomScatter = Offset(math.cos(angle) * distance, math.sin(angle) * distance);

    Future.delayed(Duration(milliseconds: widget.particle.delayMs), () {
      if (mounted) {
        _controller.forward().then((_) {
          widget.particle.isFinished = true;
          widget.onFinished();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        if (_controller.value == 0.0) return const SizedBox.shrink();

        final t = _animation.value;

        final startPoint = widget.particle.start;
        final controlPoint = widget.particle.start + _randomScatter;
        final endPoint = widget.particle.target;

        // Quadratic Bezier interpolation
        final currentPosition = Offset.lerp(
          Offset.lerp(startPoint, controlPoint, t)!,
          Offset.lerp(controlPoint, endPoint, t)!,
          t,
        )!;

        final scale = t < 0.25
            ? (t / 0.25)
            : (1.0 - (t - 0.25) / 0.75 * 0.4);

        final opacity = t > 0.8
            ? (1.0 - (t - 0.8) / 0.2)
            : 1.0;

        return Positioned(
          left: currentPosition.dx - 12,
          top: currentPosition.dy - 12,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: scale,
              child: SizedBox(
                width: 24,
                height: 24,
                child: widget.particle.isEmoji
                    ? const Text('🪙', style: TextStyle(fontSize: 16))
                    : Image.asset(
                        widget.particle.assetPath,
                        width: 24,
                        height: 24,
                        errorBuilder: (_, __, ___) => const Text('🪙'),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}
