import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SpiderCoinPill extends StatelessWidget {
  final int coins;
  final VoidCallback onTapPlus;

  const SpiderCoinPill({
    super.key,
    required this.coins,
    required this.onTapPlus,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.purpleAccent.withOpacity(0.35), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.purpleAccent.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 12),
              // Spider Web emoji for Spider Coins
              const Text('🕸', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              
              // Animated Coin Counter
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: coins, end: coins),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Text(
                    value.toString(),
                    style: GoogleFonts.righteous(
                      color: Colors.white,
                      fontSize: 18,
                      letterSpacing: 1.0,
                    ),
                  );
                },
              ),
              
              const SizedBox(width: 12),
              
              // Action Button (+)
              GestureDetector(
                onTap: onTapPlus,
                child: Container(
                  width: 32, height: 32,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.purpleAccent,
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
