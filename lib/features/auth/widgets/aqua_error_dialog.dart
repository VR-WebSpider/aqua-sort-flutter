import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aqua_sort/core/theme/app_colors.dart';
import 'package:aqua_sort/features/auth/widgets/aqua_widgets.dart';

class AquaErrorDialog extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;

  const AquaErrorDialog({
    super.key,
    required this.error,
    this.onRetry,
  });

  static Future<void> show(BuildContext context, Object error, {VoidCallback? onRetry}) {
    return showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => AquaErrorDialog(error: error, onRetry: onRetry),
    );
  }

  @override
  Widget build(BuildContext context) {
    final errorStr = error.toString();
    final isNetworkError = errorStr.contains('SocketException') || 
                           errorStr.contains('Failed host lookup') ||
                           errorStr.contains('ClientException') ||
                           errorStr.contains('NetworkImageLoadException');

    final String title = isNetworkError ? 'Connection Error' : 'Database Error';
    final String message = isNetworkError
        ? 'Could not connect to the database. Please check your internet connection and try again.'
        : 'An error occurred during guest registration. Please try again later.';
    final IconData icon = isNetworkError ? Icons.wifi_off_rounded : Icons.cloud_off_rounded;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 340,
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          decoration: BoxDecoration(
            color: AppColors.deepNavy.withOpacity(0.85),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppColors.error.withOpacity(0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.error.withOpacity(0.12),
                blurRadius: 32,
                spreadRadius: 2,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Error icon inside glowing ring
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.error.withOpacity(0.1),
                  border: Border.all(
                    color: AppColors.error.withOpacity(0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.error.withOpacity(0.2),
                      blurRadius: 16,
                    )
                  ],
                ),
                child: Icon(icon, color: AppColors.error, size: 30),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                title,
                style: GoogleFonts.righteous(
                  color: Colors.white,
                  fontSize: 22,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),

              // Friendly Message
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: AppColors.textSecondary,
                  fontSize: 13.5,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),

              // Collapsible Tech details
              Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                ),
                child: ExpansionTile(
                  title: Text(
                    'Technical Details',
                    style: GoogleFonts.outfit(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  dense: true,
                  children: [
                    Container(
                      constraints: const BoxConstraints(maxHeight: 80),
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          errorStr,
                          style: GoogleFonts.firaCode(
                            color: Colors.white38,
                            fontSize: 9.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Action button
              Row(
                children: [
                  Expanded(
                    child: GlowButton(
                      label: onRetry != null ? 'Try Again' : 'Okay',
                      onTap: () {
                        Navigator.of(context).pop();
                        if (onRetry != null) {
                          onRetry!();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
