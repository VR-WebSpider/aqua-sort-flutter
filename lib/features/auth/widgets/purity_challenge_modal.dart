import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aqua_sort/core/theme/app_colors.dart';
import 'package:aqua_sort/features/auth/widgets/aqua_widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/auth_provider.dart';

class PurityChallengeDialog extends ConsumerStatefulWidget {
  const PurityChallengeDialog({super.key});

  @override
  ConsumerState<PurityChallengeDialog> createState() => _PurityChallengeState();
}

class _PurityChallengeState extends ConsumerState<PurityChallengeDialog> {
  final _passController = TextEditingController();
  final _otpController = TextEditingController();
  int _step = 1; // 1: Password, 2: OTP
  bool _loading = false;

  @override
  void dispose() {
    _passController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.bgDark,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.cyanGlow.withOpacity(0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.cyanGlow.withOpacity(0.15),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.security, color: AppColors.cyanGlow, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Security Verification',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _step == 1
                  ? 'To update your sensitive account credentials, please re-enter your current password.'
                  : 'Enter the verification code sent to your registered email.',
              style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),

            if (_step == 1) ...[
              AquaField(
                label: 'Confirm Password',
                hint: 'Your account password',
                controller: _passController,
                obscure: true,
                lockIcon: true,
              ),
              const SizedBox(height: 24),
              GlowButton(
                label: 'Next',
                loading: _loading,
                onTap: () async {
                  if (_passController.text.isEmpty) return;
                  setState(() => _loading = true);
                  try {
                    // Re-auth check
                    final email = ref.read(authProvider).user?.email;
                    if (email == null) throw 'User email not found.';
                    
                    // Firebase Auth re-auth check
                    await FirebaseAuth.instance.signInWithEmailAndPassword(
                      email: email, 
                      password: _passController.text
                    );
                    
                    setState(() {
                      _step = 2;
                      _loading = false;
                    });
                  } catch (e) {
                    setState(() => _loading = false);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Invalid password: $e'), backgroundColor: Colors.redAccent),
                      );
                    }
                  }
                },
              ),
            ] else ...[
              AquaField(
                label: 'Purity Key',
                hint: '6-digit code',
                controller: _otpController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              GlowButton(
                label: 'Verify & Apply',
                loading: _loading,
                onTap: () async {
                  if (_otpController.text.length < 6) return;
                  setState(() => _loading = true);
                  try {
                    final valid = await ref.read(authProvider.notifier).verifyPurityChallenge(_otpController.text);
                    if (valid) {
                      if (mounted) Navigator.pop(context, true);
                    } else {
                      throw 'Invalid or expired Purity Key.';
                    }
                  } catch (e) {
                    setState(() => _loading = false);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
                      );
                    }
                  }
                },
              ),
            ],
            
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}
