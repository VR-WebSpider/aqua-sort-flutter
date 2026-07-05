import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aqua_sort/core/theme/app_colors.dart';

class CurrencyPill extends StatelessWidget {
  final int coins;
  final VoidCallback onTapPlus;

  const CurrencyPill({super.key, required this.coins, required this.onTapPlus});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTapPlus,
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: 110,
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.amber.withOpacity(0.35), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.05),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 8),
                    const Text('🪙', style: TextStyle(fontSize: 15)),
                    const SizedBox(width: 6),
                    
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
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                
                // Action Button (+)
                Container(
                  width: 32, height: 32,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFFB300), // Vibrant amber/yellow
                  ),
                  child: const Icon(Icons.add, color: Colors.black, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
