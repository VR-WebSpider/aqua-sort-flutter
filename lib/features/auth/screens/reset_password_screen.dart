import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aqua_sort/core/theme/app_colors.dart';
import 'package:aqua_sort/features/auth/widgets/aqua_widgets.dart';
import 'package:aqua_sort/features/auth/providers/auth_provider.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordState();
}

class _ResetPasswordState extends ConsumerState<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;

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
                  const AquaHeader(),
                  const SizedBox(height: 32),
                  
                  Text('Secure New Pass', style: GoogleFonts.righteous(
                    fontSize: 32, color: Colors.white,
                    shadows: [const Shadow(color: AppColors.cyanGlow, blurRadius: 20)],
                  )),
                  const SizedBox(height: 8),
                  Text('Set a new high-security password for your Aqua Sort account.', 
                    style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 14)),
                  
                  const SizedBox(height: 48),
                  
                  AquaField(
                    label: 'New Password', 
                    hint: '••••••••', 
                    controller: _passwordController,
                    obscure: true,
                    validator: (v) => v != null && v.length >= 6 ? null : 'Min 6 characters',
                  ),
                  const SizedBox(height: 20),
                  AquaField(
                    label: 'Confirm Password', 
                    hint: '••••••••', 
                    controller: _confirmController,
                    obscure: true,
                    validator: (v) => v == _passwordController.text ? null : 'Passwords do not match',
                  ),
                  const SizedBox(height: 32),
                  GlowButton(
                    label: 'Update Password', 
                    loading: isLoading,
                    onTap: () async {
                      if (_formKey.currentState!.validate()) {
                        try {
                          await ref.read(authProvider.notifier).updatePassword(_passwordController.text);
                          if (mounted) {
                            context.go('/success', extra: {
                              'title': 'Password Updated',
                              'message': 'Your account security has been restored. You can now login with your new password.',
                            });
                          }
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
