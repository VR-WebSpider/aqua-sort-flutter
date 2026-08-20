import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:aqua_sort/core/theme/app_colors.dart';
import 'package:aqua_sort/features/auth/widgets/aqua_widgets.dart';
import 'package:aqua_sort/features/lobby/providers/announcement_provider.dart';

class AnnouncementDialog extends StatelessWidget {
  final Announcement announcement;

  const AnnouncementDialog({super.key, required this.announcement});

  static void show(BuildContext context, Announcement announcement) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Announcement',
      barrierColor: Colors.black.withOpacity(0.8),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, anim1, anim2) => AnnouncementDialog(announcement: announcement),
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: Curves.easeOutBack.transform(anim1.value),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Extract coupon code if mentioned in the content (e.g. [COUPON: WELCOME100] or just detect keywords)
    String? couponCode;
    final couponMatch = RegExp(r'\[COUPON:\s*([A-Z0-9_]+)\]', caseSensitive: false).firstMatch(announcement.content);
    if (couponMatch != null) {
      couponCode = couponMatch.group(1);
    }

    // Clean content by removing the coupon syntax if present
    final displayContent = announcement.content.replaceAll(RegExp(r'\[COUPON:\s*[A-Z0-9_]+\]', caseSensitive: false), '').trim();

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.88,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.cyanGlow.withOpacity(0.25), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.cyanGlow.withOpacity(0.12),
                blurRadius: 24,
                spreadRadius: 2,
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header Image (if provided)
                    if (announcement.imageUrl != null && announcement.imageUrl!.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          announcement.imageUrl!,
                          width: double.infinity,
                          height: 150,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(
                            height: 100,
                            color: Colors.white10,
                            alignment: Alignment.center,
                            child: const Icon(Icons.broken_image_outlined, color: Colors.white30, size: 36),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Title
                    Text(
                      announcement.title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.righteous(
                        fontSize: 22,
                        color: Colors.white,
                        letterSpacing: 1.0,
                        shadows: [
                          Shadow(
                            color: AppColors.cyanGlow.withOpacity(0.8),
                            blurRadius: 12,
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Body Content
                    Text(
                      displayContent,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.85),
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Special Coupon Code Display
                    if (couponCode != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.inputBg.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.tealAccent.withOpacity(0.4), style: BorderStyle.solid),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'PROMO COUPON CODE',
                                  style: GoogleFonts.outfit(
                                    color: AppColors.tealAccent.withOpacity(0.6),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  couponCode,
                                  style: GoogleFonts.righteous(
                                    color: Colors.white,
                                    fontSize: 18,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy_rounded, color: AppColors.cyanGlow),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: couponCode!));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Coupon code "$couponCode" copied to clipboard!'),
                                    backgroundColor: AppColors.darkBlue,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Secondary / Dismiss Button
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Dismiss',
                            style: GoogleFonts.outfit(
                              color: Colors.white54,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        // Primary Action Button (if defined)
                        if (announcement.actionLabel != null && announcement.actionPath != null) ...[
                          const SizedBox(width: 16),
                          GlowButton(
                            label: announcement.actionLabel!,
                            height: 38,
                            onTap: () {
                              Navigator.pop(context); // Close dialog
                              context.push(announcement.actionPath!);
                            },
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
