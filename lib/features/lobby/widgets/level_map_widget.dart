import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aqua_sort/core/theme/app_colors.dart';
import 'package:aqua_sort/features/lobby/providers/level_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LevelMapNodes extends ConsumerStatefulWidget {
  const LevelMapNodes({super.key});

  @override
  ConsumerState<LevelMapNodes> createState() => _LevelMapNodesState();
}

class _LevelMapNodesState extends ConsumerState<LevelMapNodes> {
  final ScrollController _scrollController = ScrollController();
  final double _itemSpacing = 160.0;
  final int _maxLevels = 101;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentLevel();
    });
  }

  void _scrollToCurrentLevel() {
    final progress = ref.read(levelProvider);
    final size = MediaQuery.of(context).size;
    final int maxLevel = _maxLevels;
    final double totalHeight = maxLevel * _itemSpacing + 400;
    
    // We want to center the current level. 
    // Levels are generated from 1 (bottom) to N (top).
    final double yPos = totalHeight - (progress.currentLevel * _itemSpacing) - 100;
    final double targetScroll = yPos - (size.height / 2);
    
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        targetScroll.clamp(0, _scrollController.position.maxScrollExtent),
        duration: 1200.ms,
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(levelProvider);
    final size = MediaQuery.of(context).size;
    
    // Fixed 100 levels total
    final int maxLevel = _maxLevels;
    final double totalHeight = maxLevel * _itemSpacing + 400;
    final double yPosCurrent = totalHeight - (progress.currentLevel * _itemSpacing) - 100;

    final List<Map<String, dynamic>> levelData = List.generate(maxLevel, (index) {
      final int levelNum = index + 1;
      final double xOffset = (size.width / 2) + (math.sin(levelNum * 1.5) * 70);
      final double yPos = totalHeight - (levelNum * _itemSpacing) - 100;
      return {
        'num': levelNum,
        'pos': Offset(xOffset, yPos),
      };
    });

    final List<Offset> positions = levelData.map((e) => e['pos'] as Offset).toList();

    return SingleChildScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      child: Container(
        height: totalHeight,
        width: size.width,
        child: Stack(
          children: [
            // ── The Connecting Path ──────────────────────────────────────────
            Positioned.fill(
              child: CustomPaint(
                painter: _MapPathPainter(positions, progress.currentLevel),
              ),
            ),
            
            // ── Floating Level Orbs ──────────────────────────────────────────
            ...levelData.map((data) {
              final int levelNum = data['num'];
              final Offset pos = data['pos'];
              final isUnlocked = progress.unlockedLevels.contains(levelNum);
              final isCurrent = progress.currentLevel == levelNum;
              final isSpecial = (levelNum % 5 == 0);
              final isComingSoon = (levelNum == 101);
              final auraColor = isComingSoon ? const Color(0xFFFFD700) : const Color(0xFFBC13FE);

              // Only render if reasonably close to viewport (simple optimization)
              return Positioned(
                left: pos.dx - 32,
                top: pos.dy - 32,
                child: (isSpecial || isComingSoon) 
                  ? _RotatingAura(
                      color: auraColor,
                      child: _LevelOrb(
                        number: levelNum,
                        unlocked: isUnlocked,
                        current: isCurrent,
                      ),
                    )
                  : _LevelOrb(
                      number: levelNum,
                      unlocked: isUnlocked,
                      current: isCurrent,
                    ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                     .moveY(begin: -8, end: 8, duration: (2000 + math.Random(levelNum).nextInt(1000)).ms, curve: Curves.easeInOutSine),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

class _MapPathPainter extends CustomPainter {
  final List<Offset> positions;
  final int currentLevel;
  _MapPathPainter(this.positions, this.currentLevel);

  @override
  void paint(Canvas canvas, Size size) {
    if (positions.length < 2) return;
    
    final deadPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = Colors.white.withOpacity(0.15);

    final liquidPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..color = AppColors.cyanGlow.withOpacity(0.35);

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..color = AppColors.cyanGlow.withOpacity(0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final fullPath = Path();
    fullPath.moveTo(positions.first.dx, positions.first.dy);
    for (int i = 0; i < positions.length - 1; i++) {
        _addCurveTo(fullPath, positions[i], positions[i+1]);
    }
    
    // Draw the full "dead" path first
    canvas.drawPath(fullPath, deadPaint);

    // Draw the liquid glow only up to the current level
    final liquidPath = Path();
    liquidPath.moveTo(positions.first.dx, positions.first.dy);
    final int liquidSegments = (currentLevel - 1).clamp(0, positions.length - 1);
    
    for (int i = 0; i < liquidSegments; i++) {
        _addCurveTo(liquidPath, positions[i], positions[i+1]);
    }

    canvas.drawPath(liquidPath, glowPaint);
    canvas.drawPath(liquidPath, liquidPaint);
  }

  void _addCurveTo(Path path, Offset p1, Offset p2) {
    final control = Offset(
      (p1.dx + p2.dx) / 2 + (p2.dx - p1.dx).abs() * 0.3,
      (p1.dy + p2.dy) / 2
    );
    path.quadraticBezierTo(control.dx, control.dy, p2.dx, p2.dy);
  }

  @override bool shouldRepaint(_MapPathPainter old) => old.currentLevel != currentLevel || old.positions.length != positions.length;
}

class _LevelOrb extends StatelessWidget {
  final int number;
  final bool unlocked;
  final bool current;

  const _LevelOrb({required this.number, required this.unlocked, required this.current});

  @override
  Widget build(BuildContext context) {
    final isSpecial = (number % 5 == 0);
    final isComingSoon = (number == 101);
    
    final color = isComingSoon 
        ? const Color(0xFFFFD700) 
        : unlocked 
            ? (isSpecial ? const Color(0xFFBC13FE) : (current ? const Color(0xFF00FFD1) : AppColors.cyanGlow)) 
            : (isSpecial ? const Color(0xFFBC13FE).withOpacity(0.2) : const Color(0xFF1B2C3B));

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withOpacity(0.9),
                color.withOpacity(0.3),
                Colors.transparent,
              ],
              center: Alignment.topLeft,
              radius: 0.8,
            ),
            boxShadow: [
              if (unlocked) BoxShadow(
                color: color.withOpacity(current ? 0.8 : 0.4), 
                blurRadius: current ? (isSpecial ? 45 : 35) : 15, 
                spreadRadius: current ? (isSpecial ? 12 : 8) : 0
              ),
              if (current) BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 60,
                spreadRadius: 20,
              ),
              const BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(4, 8)),
            ],
            border: Border.all(
              color: unlocked ? (isSpecial ? const Color(0xFFBC13FE).withOpacity(0.8) : Colors.white.withOpacity(0.6)) : Colors.white.withOpacity(0.1), 
              width: current ? 3.0 : 1.5
            ),
          ),
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: unlocked ? 4 : 8, sigmaY: unlocked ? 4 : 8),
              child: Container(
                color: unlocked ? Colors.transparent : Colors.black45,
                alignment: Alignment.center,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      isComingSoon ? 'SOON' : number.toString(),
                      style: GoogleFonts.righteous(
                        fontSize: isComingSoon ? 14 : (isSpecial ? 28 : 24), 
                        color: isComingSoon ? Colors.white : (unlocked ? (isSpecial ? const Color(0xFFFDCFFF) : Colors.white) : Colors.white60),
                        shadows: [if (unlocked || isSpecial) Shadow(color: color, blurRadius: 8)],
                      ),
                    ),
                    if (isSpecial && !isComingSoon)
                      Positioned(
                        top: 8, right: 8,
                        child: Icon(Icons.star, size: 10, color: (unlocked ? const Color(0xFFBC13FE) : const Color(0xFFBC13FE).withOpacity(0.5))),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        if (!unlocked && !isComingSoon)
          Positioned(
            bottom: -5, right: -5,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle, 
                color: Colors.black,
                border: Border.all(color: Colors.white24, width: 1.5),
                boxShadow: [
                  BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, spreadRadius: 2),
                ],
              ),
              child: const Icon(Icons.lock, size: 12, color: Colors.white),
            ),
          ),
      ],
    );
  }
}

class _RotatingAura extends StatelessWidget {
  final Color color;
  final Widget child;
  const _RotatingAura({required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120, height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The Polar Rotating Beam
          Container(
            width: 110, height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  Colors.transparent,
                  color.withOpacity(0.4),
                  Colors.transparent,
                ],
                stops: const [0.35, 0.5, 0.65],
              ),
            ),
          ).animate(onPlay: (c) => c.repeat())
           .rotate(duration: 8.seconds),
           
          // The Static Soft Glow
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
              ],
            ),
          ),
          
          child,
        ],
      ),
    );
  }
}
