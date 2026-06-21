import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aqua_sort/core/theme/app_colors.dart';
import 'package:aqua_sort/features/auth/widgets/aqua_widgets.dart';
import 'package:aqua_sort/features/auth/providers/auth_provider.dart';

class DualVerificationScreen extends ConsumerStatefulWidget {
  final String newEmail;
  const DualVerificationScreen({super.key, required this.newEmail});

  @override
  ConsumerState<DualVerificationScreen> createState() => _DualVerificationState();
}

class _DualVerificationState extends ConsumerState<DualVerificationScreen> {
  final _oldCode = TextEditingController();
  final _newCode = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _oldCode.dispose();
    _newCode.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_oldCode.text.length < 6 || _newCode.text.length < 6) return;
    
    setState(() => _isLoading = true);
    try {
      final success = await ref.read(authProvider.notifier).verifyEmailSwap(
        widget.newEmail,
        _oldCode.text,
        _newCode.text,
      );
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Identity Identity Successfully Swapped'), backgroundColor: Colors.greenAccent),
          );
          Navigator.pop(context); // Close verifier
          Navigator.pop(context); // Close input
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid Security Codes'), backgroundColor: Colors.redAccent),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: aquaBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Text(
                  'Zero Casualization',
                  style: GoogleFonts.righteous(
                    fontSize: 26,
                    color: Colors.white,
                    shadows: [const Shadow(color: AppColors.cyanGlow, blurRadius: 15)],
                  ),
                ),
                Text(
                  'Dual-Email Security Challenge',
                  style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 40),

                _buildChallengeBox(
                  title: 'CODE A: OLD ADDRESS',
                  subtitle: 'Sent to your current registered email',
                  controller: _oldCode,
                  icon: Icons.mark_email_read_outlined,
                ),

                const SizedBox(height: 20),
                const Icon(Icons.link, color: AppColors.tealMid, size: 30),
                const SizedBox(height: 20),

                _buildChallengeBox(
                  title: 'CODE B: NEW ADDRESS',
                  subtitle: 'Sent to ${widget.newEmail}',
                  controller: _newCode,
                  icon: Icons.forward_to_inbox_outlined,
                ),

                const SizedBox(height: 40),
                GlowButton(
                  label: 'AUTHORIZE SWAP',
                  loading: _isLoading,
                  onTap: _verify,
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel Identity Change', style: GoogleFonts.outfit(color: Colors.white54)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChallengeBox({
    required String title,
    required String subtitle,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.inputBg.withOpacity(0.6),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.cyanGlow, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: 20),
          TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            style: GoogleFonts.righteous(fontSize: 24, color: AppColors.cyanGlow, letterSpacing: 8),
            decoration: InputDecoration(
              counterText: '',
              hintText: '000000',
              hintStyle: GoogleFonts.righteous(color: Colors.white12),
              enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.tealMid)),
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.cyanGlow)),
            ),
          ),
        ],
      ),
    );
  }
}
