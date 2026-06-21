import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
  final _formKey = GlobalKey<FormState>();
  bool _sent = false;

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: aquaBackground(
        child: SafeArea(
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
                       label: 'Send Reset Link', 
                       loading: ref.watch(authProvider).isLoading,
                       onTap: () async {
                         if (_formKey.currentState!.validate()) {
                           try {
                             await ref.read(authProvider.notifier).forgotPassword(_idController.text);
                             setState(() => _sent = true);
                           } catch (e) {
                             if (mounted) {
                               ScaffoldMessenger.of(context).showSnackBar(
                                 SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
                               );
                             }
                           }
                         }
                       },
                     ),
                   ] else ...[
                     Container(
                       padding: const EdgeInsets.all(24),
                       decoration: BoxDecoration(
                         color: AppColors.tealAccent.withOpacity(0.1),
                         borderRadius: BorderRadius.circular(16),
                         border: Border.all(color: AppColors.tealAccent.withOpacity(0.3)),
                       ),
                       child: Column(
                         children: [
                           const Icon(Icons.mark_email_read_outlined, color: AppColors.tealAccent, size: 48),
                           const SizedBox(height: 16),
                           Text('Verification Sent', style: GoogleFonts.outfit(
                             fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                           const SizedBox(height: 8),
                           Text(
                             'A Purity Reset link has been sent to the email associated with your account.',
                             textAlign: TextAlign.center,
                             style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 14),
                           ),
                         ],
                       ),
                     ),
                     const SizedBox(height: 32),
                     GlowButton(
                       label: 'Back to Login', 
                       onTap: () => context.go('/login'),
                     ),
                   ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
