import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aqua_sort/core/theme/app_colors.dart';
import 'package:aqua_sort/features/auth/widgets/aqua_widgets.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:aqua_sort/features/auth/providers/auth_provider.dart';

class ProfileOtpOverlay extends ConsumerStatefulWidget {
  final String email;
  final String phone;
  final VoidCallback onVerified;

  const ProfileOtpOverlay({
    super.key,
    required this.email,
    required this.phone,
    required this.onVerified,
  });

  @override
  ConsumerState<ProfileOtpOverlay> createState() => _ProfileOtpOverlayState();
}

class _ProfileOtpOverlayState extends ConsumerState<ProfileOtpOverlay> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Trigger the actual security challenge on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).initiatePurityChallenge();
    });
  }

  void _verify() async {
    if (_controller.text.length != 6) return;
    
    setState(() => _isLoading = true);
    try {
      final success = await ref.read(authProvider.notifier).verifyPurityChallenge(_controller.text);
      
      if (mounted) {
        if (success) {
          Navigator.pop(context);
          widget.onVerified();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid security code. Please try again.'), backgroundColor: Colors.redAccent),
          );
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(22),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.deepNavy,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.cyanGlow.withOpacity(0.5)),
          boxShadow: [BoxShadow(color: AppColors.cyanGlow.withOpacity(0.2), blurRadius: 40)],
        ),
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('UNIFIED VERIFICATION', style: GoogleFonts.righteous(fontSize: 18, color: Colors.white, letterSpacing: 2)),
              const SizedBox(height: 12),
              Text(
                'A security code has been sent to:\n${widget.email}\n${widget.phone}',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 32),
              PinCodeTextField(
                appContext: context,
                length: 6,
                controller: _controller,
                keyboardType: TextInputType.number,
                textStyle: const TextStyle(color: Colors.white),
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(8),
                  fieldHeight: 45, fieldWidth: 40,
                  activeColor: AppColors.cyanGlow,
                  selectedColor: Colors.white,
                  inactiveColor: Colors.white12,
                ),
                onChanged: (_) {},
                onCompleted: (_) => _verify(),
              ),
              const SizedBox(height: 32),
              if (_isLoading)
                const CircularProgressIndicator(color: AppColors.cyanGlow)
              else
                GlowButton(label: 'VERIFY ACCOUNT', onTap: _verify),
            ],
          ),
        ),
      ).animate().scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack).fadeIn(),
    );
  }
}
