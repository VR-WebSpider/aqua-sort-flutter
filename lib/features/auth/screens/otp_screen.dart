import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:aqua_sort/core/theme/app_colors.dart';
import 'package:aqua_sort/features/auth/widgets/aqua_widgets.dart';

class OtpScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const OtpScreen({super.key, required this.userData});
  @override State<OtpScreen> createState() => _OtpState();
}

class _OtpState extends State<OtpScreen> {
  final _ctrl = TextEditingController();
  String _otp = '';

  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  void _numPad(String digit) {
    if (_otp.length < 6) setState(() => _otp += digit);
    _ctrl.text = _otp;
  }

  void _delete() {
    if (_otp.isNotEmpty) setState(() => _otp = _otp.substring(0, _otp.length - 1));
    _ctrl.text = _otp;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: aquaBackground(
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(22),
              child: AquaHeader(onBack: () => context.go('/register')),
            ),
            const Spacer(),

            Text('Verification Code',
                style: GoogleFonts.righteous(fontSize: 28, color: Colors.white,
                    shadows: [const Shadow(color: AppColors.cyanGlow, blurRadius: 20)])),
            const SizedBox(height: 8),
            Text('(Will be sent to Mobile and Email)',
                style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 36),

            // â”€â”€ OTP Boxes â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: PinCodeTextField(
                appContext: context,
                length: 6,
                controller: _ctrl,
                onChanged: (v) => setState(() => _otp = v),
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(12),
                  fieldHeight: 58, fieldWidth: 46,
                  activeColor: AppColors.cyanGlow,
                  selectedColor: AppColors.tealAccent,
                  inactiveColor: AppColors.inputBorder,
                  activeFillColor: AppColors.inputBg,
                  selectedFillColor: AppColors.inputBg,
                  inactiveFillColor: AppColors.inputBg,
                ),
                enableActiveFill: true,
                keyboardType: TextInputType.none,
                textStyle: GoogleFonts.outfit(color: AppColors.cyanGlow, fontSize: 22, fontWeight: FontWeight.w800),
                boxShadows: [BoxShadow(color: AppColors.cyanGlow.withOpacity(0.25), blurRadius: 12, spreadRadius: 1)],
              ),
            ),
            const SizedBox(height: 30),

            // â”€â”€ Number pad â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: Column(children: [
                for (var row in [['1','2','3'],['4','5','6'],['7','8','9'],['','0','BACK']])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: row.map((d) => _numKey(d)).toList(),
                    ),
                  ),
              ]),
            ),
            const SizedBox(height: 20),

            // â”€â”€ Actions â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(children: [
                Expanded(child: GlowButton(label: 'Resend Code', outlined: true,
                    onTap: () {})),
                const SizedBox(width: 12),
                Expanded(child: GlowButton(label: 'Verify',
                    onTap: () {
                      if (_otp.length == 6) context.go('/verification', extra: widget.userData);
                    })),
              ]),
            ),
            const SizedBox(height: 30),
          ]),
        ),
      ),
    );
  }

  Widget _numKey(String d) {
    if (d.isEmpty) return const SizedBox(width: 72, height: 52);
    return GestureDetector(
      onTap: () => d == 'BACK' ? _delete() : _numPad(d),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: 72, height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: AppColors.inputBg,
          border: Border.all(color: AppColors.inputBorder),
        ),
        alignment: Alignment.center,
        child: d == 'BACK' 
          ? const Icon(Icons.backspace_outlined, color: Colors.white, size: 20)
          : Text(d, style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w600, color: Colors.white)),
      ),
    );
  }
}
