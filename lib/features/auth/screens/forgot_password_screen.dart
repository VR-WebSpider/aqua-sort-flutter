import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:aqua_sort/core/theme/app_colors.dart';
import 'package:aqua_sort/features/auth/widgets/aqua_widgets.dart';
import 'package:aqua_sort/features/auth/providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends ConsumerState<ForgotPasswordScreen> {
  final _idController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _sent = false;
  String _otp = '';

  // Timer logic
  Timer? _timer;
  int _secondsRemaining = 60;
  bool _canResend = false;

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
  void dispose() {
    _idController.dispose();
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: aquaBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     AquaHeader(onBack: () => context.go('/login')),
                     const SizedBox(height: 32),
                     
                     Text('Purity Reset', style: GoogleFonts.righteous(
                       fontSize: 32, color: Colors.white,
                       shadows: [const Shadow(color: AppColors.cyanGlow, blurRadius: 20)],
                     )),
                     const SizedBox(height: 8),
                     Text('Restore access to your official Aqua Sort account.', 
                       style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 14)),
                     
                     const SizedBox(height: 48),
                     
                     if (!_sent) ...[
                       AquaField(
                         label: 'Recovery ID', 
                         hint: 'Email or Phone Number', 
                         controller: _idController,
                         keyboardType: TextInputType.emailAddress,
                         validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                       ),
                       const SizedBox(height: 32),
                       GlowButton(
                         label: 'Send OTP Code', 
                         loading: ref.watch(authProvider).isLoading,
                         onTap: () async {
                           if (_formKey.currentState!.validate()) {
                             final messenger = ScaffoldMessenger.of(context);
                             try {
                               await ref.read(authProvider.notifier).forgotPassword(_idController.text);
                               setState(() {
                                 _sent = true;
                                 _startTimer();
                               });
                             } catch (e) {
                               messenger.showSnackBar(
                                 SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
                               );
                             }
                           }
                         },
                       ),
                     ] else ...[
                       Container(
                         padding: const EdgeInsets.all(20),
                         decoration: BoxDecoration(
                           color: AppColors.tealAccent.withOpacity(0.08),
                           borderRadius: BorderRadius.circular(16),
                           border: Border.all(color: AppColors.tealAccent.withOpacity(0.2)),
                         ),
                         child: Column(
                           children: [
                             const Icon(Icons.mark_email_read_outlined, color: AppColors.tealAccent, size: 40),
                             const SizedBox(height: 12),
                             Text('Verification Sent', style: GoogleFonts.outfit(
                               fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                             const SizedBox(height: 8),
                             Text(
                               'A 6-digit Purity Reset code has been sent to the email associated with your account.',
                               textAlign: TextAlign.center,
                               style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13),
                             ),
                           ],
                         ),
                       ),
                       const SizedBox(height: 32),
                       PinCodeTextField(
                         appContext: context,
                         length: 6,
                         controller: _otpController,
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
                       const SizedBox(height: 32),
                       Row(
                         children: [
                           Expanded(
                             child: GlowButton(
                               label: _canResend ? 'Resend' : 'Resend (${_secondsRemaining}s)', 
                               outlined: true,
                               loading: !_canResend && _secondsRemaining == 0,
                               onTap: _canResend ? () async {
                                 _startTimer();
                                 final messenger = ScaffoldMessenger.of(context);
                                 try {
                                   await ref.read(authProvider.notifier).forgotPassword(_idController.text);
                                   messenger.showSnackBar(
                                     const SnackBar(content: Text('Verification code resent!'), backgroundColor: AppColors.midTeal),
                                   );
                                 } catch (e) {
                                   messenger.showSnackBar(
                                     SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
                                   );
                                 }
                               } : () {},
                             ),
                           ),
                           const SizedBox(width: 12),
                           Expanded(
                             child: GlowButton(
                               label: 'Verify & Reset',
                               loading: ref.watch(authProvider).isLoading,
                               onTap: () async {
                                 if (_otp.length == 6) {
                                   final router = GoRouter.of(context);
                                   final messenger = ScaffoldMessenger.of(context);
                                   try {
                                     await ref.read(authProvider.notifier).verifyRecoveryOtp(_idController.text, _otp);
                                     router.go('/reset-password');
                                   } catch (e) {
                                     messenger.showSnackBar(
                                       SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
                                     );
                                   }
                                 }
                               },
                             ),
                           ),
                         ],
                       ),
                     ],
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
