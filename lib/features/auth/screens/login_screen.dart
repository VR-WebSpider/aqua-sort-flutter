import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aqua_sort/core/theme/app_colors.dart';
import 'package:aqua_sort/features/auth/widgets/aqua_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aqua_sort/features/auth/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override ConsumerState<LoginScreen> createState() => _LoginState();
}

class _LoginState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _id   = TextEditingController();
  final _pass = TextEditingController();
  bool _showPass = false;

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
                      child: Image.asset('assets/studio_logo_white.png', height: 80),
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

              const SizedBox(height: 24),
              
              AquaField(
                label: 'User ID / Email',
                hint: 'Enter username/email /phone',
                controller: _id,
                keyboardType: TextInputType.text,
                lockIcon: true,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),

              AquaField(label: 'Password', hint: 'Enter password',
                  controller: _pass, obscure: !_showPass, lockIcon: true,
                  suffix: IconButton(
                    icon: Icon(_showPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 17, color: AppColors.tealAccent),
                    onPressed: () => setState(() => _showPass = !_showPass),
                  ),
                  validator: (v) => v == null || v.length < 6 ? 'Min 6 chars' : null),

              const SizedBox(height: 8),
              GlowButton(
                label: 'Sign In & Play', 
                icon: Icons.arrow_forward_rounded, 
                loading: ref.watch(authProvider).isLoading,
                onTap: () async {
                if (_form.currentState!.validate()) {
                  try {
                    await ref.read(authProvider.notifier).login(_id.text, _pass.text);
                    if (mounted) context.go('/lobby');
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Login failed: ${e.toString()}'), backgroundColor: Colors.redAccent),
                      );
                    }
                  }
                }
              }),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(child: Divider(color: Colors.white10)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('or', style: GoogleFonts.outfit(color: AppColors.textSecondary.withOpacity(0.5), fontSize: 13)),
                  ),
                  const Expanded(child: Divider(color: Colors.white10)),
                ],
              ),
              const SizedBox(height: 16),
              GlowButton(
                label: 'Continue with Google',
                icon: Icons.g_mobiledata,
                outlined: true,
                onTap: () async {
                  try {
                    await ref.read(authProvider.notifier).signInWithSocial(OAuthProvider.google);
                    if (mounted) context.go('/lobby');
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Google Sign-In failed: ${e.toString()}'), backgroundColor: Colors.redAccent),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 12),
              GlowButton(
                label: 'Continue with Facebook',
                icon: Icons.facebook,
                outlined: true,
                onTap: () async {
                  try {
                    await ref.read(authProvider.notifier).signInWithSocial(OAuthProvider.facebook);
                    if (mounted) context.go('/lobby');
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Facebook Sign-In failed: ${e.toString()}'), backgroundColor: Colors.redAccent),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 12),

              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => context.push('/forgot-password'),
                  child: Text('Forgot Password?', 
                    style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),

              const SizedBox(height: 24),

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
