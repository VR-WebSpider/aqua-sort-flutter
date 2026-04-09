import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aqua_sort/core/theme/app_colors.dart';
import 'package:aqua_sort/features/auth/widgets/aqua_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aqua_sort/features/auth/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override ConsumerState<LoginScreen> createState() => _LoginState();
}

class _LoginState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _id   = TextEditingController();
  final _pass = TextEditingController();
  bool _showPass = false;
  String _method = 'username'; // username | email | phone

  @override void dispose() { _id.dispose(); _pass.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: aquaBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Form(key: _form, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AquaHeader(onBack: () => context.go('/')),
              const SizedBox(height: 12),
              Center(
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset('assets/webspider_logo.jpg', height: 80),
                    ),
                    const SizedBox(height: 4),
                    Text('WebSpider Studios', 
                      style: GoogleFonts.righteous(fontSize: 10, color: AppColors.tealAccent.withOpacity(0.4), letterSpacing: 2)),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Text('Secure Login', style: GoogleFonts.righteous(fontSize: 30, color: Colors.white,
                  shadows: [const Shadow(color: AppColors.cyanGlow, blurRadius: 22)])),
              const SizedBox(height: 4),
              Text('Welcome back, Sorter', style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 24),

              // Method selector
              Row(children: ['User ID','email','phone'].map((m) {
                final active = _method == m;
                return GestureDetector(
                  onTap: () => setState(() => _method = m),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: active ? AppColors.tealAccent.withOpacity(0.2) : AppColors.inputBg,
                      border: Border.all(color: active ? AppColors.tealAccent : AppColors.inputBorder),
                    ),
                    child: Text(m,
                        style: GoogleFonts.outfit(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: active ? AppColors.cyanGlow : AppColors.textMuted)),
                  ),
                );
              }).toList()),
              const SizedBox(height: 18),

              AquaField(label: _method == 'phone' ? 'Phone Number' : _method == 'email' ? 'Email' : 'User ID',
                  hint: _method == 'User ID' ? 'Username/email/phone' : 'Enter your $_method', controller: _id,
                  keyboardType: _method == 'email' ? TextInputType.emailAddress
                      : _method == 'phone' ? TextInputType.phone : TextInputType.text,
                  lockIcon: true,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null),

              AquaField(label: 'Password', hint: 'Enter password',
                  controller: _pass, obscure: !_showPass, lockIcon: true,
                  suffix: IconButton(
                    icon: Icon(_showPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 17, color: AppColors.tealAccent),
                    onPressed: () => setState(() => _showPass = !_showPass),
                  ),
                  validator: (v) => v == null || v.length < 6 ? 'Min 6 chars' : null),

              const SizedBox(height: 8),
              GlowButton(label: 'Sign In & Play', icon: Icons.arrow_forward_rounded, onTap: () {
                if (_form.currentState!.validate()) {
                  ref.read(authProvider.notifier).login(
                    _id.text,
                    lastName: 'Sorter',
                    displayName: _id.text,
                  );
                  context.go('/lobby');
                }
              }),
              const SizedBox(height: 18),

              Center(child: GestureDetector(
                onTap: () => context.go('/register'),
                child: RichText(text: TextSpan(children: [
                  TextSpan(text: "Don't have an account? ",
                      style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13)),
                  TextSpan(text: 'Create Account',
                      style: GoogleFonts.outfit(color: AppColors.cyanGlow,
                          fontSize: 13, fontWeight: FontWeight.w700)),
                ])),
              )),
            ])),
          ),
        ),
      ),
    );
  }
}
