import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aqua_sort/core/theme/app_colors.dart';
import 'package:aqua_sort/features/auth/widgets/aqua_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.darkBlue,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.tealAccent.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(color: AppColors.cyanGlow.withOpacity(0.1), blurRadius: 30, spreadRadius: 5)
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.security_outlined, color: AppColors.cyanGlow, size: 40),
            const SizedBox(height: 16),
            Text('Purity Challenge', style: GoogleFonts.righteous(
              fontSize: 22, color: Colors.white,
            )),
            const SizedBox(height: 8),
            Text(
              _step == 1 
                ? 'Identity verification required to modify your official profile.' 
                : 'Enter the Purity Key sent to your registered email.',
              textAlign: TextAlign.center,
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
                    
                    // Supabase native re-auth check
                    await Supabase.instance.client.auth.signInWithPassword(
                      email: email, 
                      password: _passController.text
                    );
                    
                    // Trigger OTP
                    await ref.read(authProvider.notifier).initiatePurityChallenge();
                    
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
