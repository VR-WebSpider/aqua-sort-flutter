import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:aqua_sort/core/theme/app_colors.dart';
import 'package:aqua_sort/features/auth/widgets/aqua_widgets.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aqua_sort/features/auth/providers/auth_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> userData;
  const OtpScreen({super.key, required this.userData});
  @override ConsumerState<OtpScreen> createState() => _OtpState();
}

class _OtpState extends ConsumerState<OtpScreen> {
  final _ctrl = TextEditingController();
  String _otp = '';
  
  // Timer logic
  Timer? _timer;
  int _secondsRemaining = 60;
  bool _canResend = false;

  @override 
  void initState() { 
    super.initState(); 
    _startTimer();
  }

  @override 
  void dispose() { 
    _timer?.cancel();
    _ctrl.dispose(); 
    super.dispose(); 
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 60;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        setState(() {
          _canResend = true;
          _timer?.cancel();
        });
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: aquaBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  AquaHeader(onBack: () => context.go('/register')),
                  const SizedBox(height: 48),

                  Text('Verification Code',
                      style: GoogleFonts.righteous(fontSize: 28, color: Colors.white,
                          shadows: [const Shadow(color: AppColors.cyanGlow, blurRadius: 20)])),
                  const SizedBox(height: 8),
                  Text('Sent to ${widget.userData['email']}',
                      style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 48),

                  // ── OTP Boxes (Image 1 Ref: Glow style) ──────────────────────────
                  PinCodeTextField(
                    appContext: context,
                    length: 6,
                    controller: _ctrl,
                    onChanged: (v) => setState(() => _otp = v),
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(10),
                      fieldHeight: 56, fieldWidth: 44,
                      borderWidth: 2,
                      activeColor: AppColors.cyanGlow,
                      selectedColor: AppColors.tealAccent,
                      inactiveColor: Colors.white10,
                      activeFillColor: Colors.black26,
                      selectedFillColor: Colors.black26,
                      inactiveFillColor: Colors.black26,
                    ),
                    enableActiveFill: true,
                    keyboardType: TextInputType.number,
                    textStyle: GoogleFonts.outfit(color: AppColors.cyanGlow, fontSize: 22, fontWeight: FontWeight.w800),
                    boxShadows: [
                      BoxShadow(color: AppColors.cyanGlow.withOpacity(0.3), blurRadius: 15, spreadRadius: 1)
                    ],
                  ),
                  const SizedBox(height: 48),

                  // ── Actions ──────────────────────────────────────────────────
                  Row(children: [
                    Expanded(child: GlowButton(
                        label: _canResend ? 'Resend Code' : 'Resend (${_secondsRemaining}s)', 
                        outlined: true,
                        loading: !_canResend && _secondsRemaining == 0,
                        onTap: _canResend ? () {
                          _startTimer();
                          ref.read(authProvider.notifier).signUp(
                            widget.userData['email'],
                            'no_password_needed_for_resend', 
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Code resent successfully!'), backgroundColor: AppColors.midTeal),
                          );
                        } : () {})),
                    const SizedBox(width: 12),
                    Expanded(child: GlowButton(
                      label: 'Verify',
                      loading: ref.watch(authProvider).isLoading,
                      onTap: () async {
                        if (_otp.length == 6) {
                          final router = GoRouter.of(context);
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await ref.read(authProvider.notifier).verifyOtp(
                              widget.userData['email'],
                              _otp,
                              firstName: widget.userData['firstName'],
                              lastName: widget.userData['lastName'],
                              phone: widget.userData['phone'],
                            );
                            router.go('/verification', extra: widget.userData);
                          } catch (e) {
                            messenger.showSnackBar(
                              SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
                            );
                          }
                        }
                      },
                    )),
                  ]),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
