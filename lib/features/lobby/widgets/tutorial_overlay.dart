import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aqua_sort/core/theme/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TutorialOverlay extends StatefulWidget {
  final VoidCallback onClose;
  const TutorialOverlay({super.key, required this.onClose});

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _steps = [
    {
      'title': 'WELCOME TO AQUA SORT',
      'desc': 'Ready to master the elements? Let\'s walk through the basic techniques.',
      'image': '🌊',
    },
    {
      'title': 'SELECT A VESSEL',
      'desc': 'Tap any bottle to select it. The topmost liquid layer will lift, ready to be moved.',
      'image': '🧪',
    },
    {
      'title': 'POUR THE LIQUID',
      'desc': 'Tap another bottle to pour. The liquid will flow into the new vessel if there is space.',
      'image': '💧',
    },
    {
      'title': 'THE SORTING RULES',
      'desc': 'You can only pour liquid onto the SAME color, or into an EMPTY bottle.',
      'image': '⚖️',
    },
    {
      'title': 'YOUR ULTIMATE GOAL',
      'desc': 'Sort every color until each bottle contains only one pure element. Good luck!',
      'image': '🏆',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // ── Backdrop Blur ────────────────────────────────────────────────
          Positioned.fill(
            child: GestureDetector(
              onTap: widget.onClose,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(color: Colors.black.withOpacity(0.7)),
              ),
            ),
          ),

          // ── Content Card ──────────────────────────────────────────────────
          Center(
            child: Container(
              width: 340, height: 480,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
                boxShadow: [
                  BoxShadow(color: AppColors.cyanGlow.withOpacity(0.1), blurRadius: 40, spreadRadius: 5),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('TRAINING', style: GoogleFonts.outfit(color: AppColors.tealAccent, letterSpacing: 2, fontWeight: FontWeight.bold, fontSize: 12)),
                        GestureDetector(
                          onTap: widget.onClose,
                          child: Icon(Icons.close, color: Colors.white.withOpacity(0.5), size: 20),
                        ),
                      ],
                    ),
                  ),

                  // Carousel
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (v) => setState(() => _currentPage = v),
                      itemCount: _steps.length,
                      itemBuilder: (context, i) {
                        final step = _steps[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(step['image']!, style: const TextStyle(fontSize: 80))
                                  .animate(key: ValueKey(i)).scale(begin: const Offset(0.5, 0.5), duration: 400.ms, curve: Curves.easeOutBack),
                              const SizedBox(height: 32),
                              Text(step['title']!, 
                                textAlign: TextAlign.center,
                                style: GoogleFonts.righteous(fontSize: 24, color: Colors.white, letterSpacing: 1.5)),
                              const SizedBox(height: 16),
                              Text(step['desc']!, 
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(fontSize: 15, color: Colors.white.withOpacity(0.7), height: 1.5)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Indicators & Buttons
                  Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: List.generate(_steps.length, (index) => Container(
                            width: _currentPage == index ? 20 : 6,
                            height: 6,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: _currentPage == index ? AppColors.cyanGlow : Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          )),
                        ),
                        GestureDetector(
                          onTap: () {
                            if (_currentPage < _steps.length - 1) {
                              _pageController.nextPage(duration: 400.ms, curve: Curves.easeInOut);
                            } else {
                              widget.onClose();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.cyanGlow.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.cyanGlow.withOpacity(0.3)),
                            ),
                            child: Text(_currentPage == _steps.length - 1 ? 'START' : 'NEXT', 
                                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          ),
                        ),
                      ],
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
}
