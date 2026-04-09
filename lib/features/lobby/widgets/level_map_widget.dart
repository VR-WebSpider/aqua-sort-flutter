import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aqua_sort/core/theme/app_colors.dart';
import 'package:aqua_sort/features/lobby/providers/level_provider.dart';

class LevelMapTube extends ConsumerWidget {
  const LevelMapTube({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(levelProvider);
    final size = MediaQuery.of(context).size;
    final double tubeWidth = 140;
    
    // Calculate liquid height based on current level progress
    // Let's say we show 5 levels at a time.
    final double maxLevels = 5;
    final double levelHeight = 110;
    final double liquidH = (progress.currentLevel % 5) * levelHeight + 100;

    return Center(
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // ── The Tube ────────────────────────────────────────────────────────
          CustomPaint(
            size: Size(tubeWidth, size.height * 0.7),
            painter: _VerticalTubePainter(liquidHeight: liquidH),
          ),
          
          // ── The Nodes ───────────────────────────────────────────────────────
          Positioned(
            bottom: 60,
            child: SizedBox(
              width: tubeWidth,
              height: size.height * 0.6,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: List.generate(5, (i) {
                  final levelNum = ((progress.currentLevel - 1) ~/ 5) * 5 + (5 - i);
                  final isUnlocked = progress.unlockedLevels.contains(levelNum);
                  final isCurrent = progress.currentLevel == levelNum;
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: _LevelNode(
                      number: levelNum,
                      unlocked: isUnlocked,
                      current: isCurrent,
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelNode extends StatelessWidget {
  final int number;
  final bool unlocked;
  final bool current;

  const _LevelNode({required this.number, required this.unlocked, required this.current});

  @override
  Widget build(BuildContext context) {
    final color = unlocked 
        ? (current ? Colors.greenAccent : AppColors.cyanGlow) 
        : Colors.grey.withOpacity(0.4);

    return Container(
      width: 60, height: 60,
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        shape: BoxShape.circle, // Simplified Hexagon for now
        boxShadow: current ? [BoxShadow(color: color.withOpacity(0.6), blurRadius: 15, spreadRadius: 2)] : [],
        border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
      ),
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            number.toString(),
            style: GoogleFonts.righteous(
              fontSize: 22, 
              color: unlocked ? Colors.white : Colors.white60,
            ),
          ),
          if (!unlocked)
            const Positioned(
              bottom: -4,
              child: Icon(Icons.lock, size: 14, color: Colors.white70),
            ),
        ],
      ),
    );
  }
}

class _VerticalTubePainter extends CustomPainter {
  final double liquidHeight;
  _VerticalTubePainter({required this.liquidHeight});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final r = w / 2;

    final tubePath = Path()
      ..moveTo(0, 0)
      ..lineTo(0, h - r)
      ..arcToPoint(Offset(w, h - r), radius: Radius.circular(r), clockwise: false)
      ..lineTo(w, 0)
      ..lineTo(0, 0);

    // Background of tube
    canvas.drawPath(tubePath, Paint()..color = Colors.white.withOpacity(0.08));

    // Liquid
    final liquidPath = Path()
      ..moveTo(0, h)
      ..lineTo(0, h - liquidHeight)
      ..lineTo(w, h - liquidHeight)
      ..lineTo(w, h)
      ..close();
    
    // Clip by tube
    canvas.save();
    canvas.clipPath(tubePath);
    
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [AppColors.cyanGlow.withOpacity(0.7), AppColors.cyanGlow.withOpacity(0.4)],
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, h - liquidHeight, w, liquidHeight));
    
    canvas.drawPath(liquidPath, paint);

    // Bubbles
    final rand = math.Random(42);
    for (int i = 0; i < 8; i++) {
        canvas.drawCircle(
          Offset(rand.nextDouble() * w, h - rand.nextDouble() * liquidHeight), 
          rand.nextDouble() * 3 + 1, 
          Paint()..color = Colors.white.withOpacity(0.3)
        );
    }
    
    canvas.restore();

    // Border
    canvas.drawPath(tubePath, Paint()
      ..style = PaintingStyle.stroke ..strokeWidth = 2.5
      ..color = Colors.white.withOpacity(0.2));
  }

  @override bool shouldRepaint(_VerticalTubePainter old) => old.liquidHeight != liquidHeight;
}
