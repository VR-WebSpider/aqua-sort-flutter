import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aqua_sort/core/theme/app_colors.dart';
import 'package:aqua_sort/features/auth/widgets/aqua_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aqua_sort/features/auth/providers/auth_provider.dart';
import 'package:country_code_picker/country_code_picker.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override ConsumerState<LoginScreen> createState() => _LoginState();
}

class _LoginState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _id   = TextEditingController();
  final _phoneId = TextEditingController();
  final _pass = TextEditingController();
  bool _showPass = false;
  bool _usePhone = false;
  String _countryCode = '+91';

  @override void dispose() {
    _id.dispose();
    _phoneId.dispose();
    _pass.dispose();
    super.dispose();
  }

  Widget _loginTab(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? AppColors.inputBg : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: active ? AppColors.cyanGlow.withOpacity(0.3) : Colors.white10),
            boxShadow: active
                ? [BoxShadow(color: AppColors.cyanGlow.withOpacity(0.1), blurRadius: 8)]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.outfit(
              color: active ? Colors.white : Colors.white38,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ),
    );
  }

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

              // Tab Selector
              Row(
                children: [
                  _loginTab('Email / Username', !_usePhone, () => setState(() => _usePhone = false)),
                  const SizedBox(width: 12),
                  _loginTab('Phone Number', _usePhone, () => setState(() => _usePhone = true)),
                ],
              ),
              const SizedBox(height: 20),
              
              if (!_usePhone)
                AquaField(
                  label: 'User ID / Email',
                  hint: 'Enter username or email',
                  controller: _id,
                  keyboardType: TextInputType.text,
                  lockIcon: true,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      height: 46,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.inputBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.inputBorder),
                      ),
                      child: CountryCodePicker(
                        onChanged: (c) => setState(() => _countryCode = c.dialCode!),
                        initialSelection: 'IN',
                        favorite: const ['+91', 'IN'],
                        textStyle: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                        showCountryOnly: false,
                        showOnlyCountryWhenClosed: false,
                        alignLeft: false,
                        padding: EdgeInsets.zero,
                        showDropDownButton: true,
                        dialogBackgroundColor: AppColors.deepNavy,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AquaField(
                        label: 'Phone Number',
                        hint: 'Enter mobile number',
                        controller: _phoneId,
                        keyboardType: TextInputType.phone,
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),

              AquaField(label: 'Password', hint: 'Enter password',
                  controller: _pass, obscure: !_showPass, lockIcon: true,
                  suffix: IconButton(
                    icon: Icon(_showPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 17, color: AppColors.tealAccent),
                    onPressed: () => setState(() => _showPass = !_showPass),
                  ),
                  validator: (v) => v == null || v.length < 6 ? 'Min 6 chars' : null),

              const SizedBox(height: 16),
              GlowButton(
                label: 'Sign In & Play', 
                icon: Icons.arrow_forward_rounded, 
                loading: ref.watch(authProvider).isLoading,
                onTap: () async {
                if (_form.currentState!.validate()) {
                  try {
                    final String identifier = _usePhone 
                        ? '$_countryCode ${_phoneId.text.trim()}'.replaceAll(RegExp(r'[\s\-\(\)]'), '')
                        : _id.text.trim();
                    await ref.read(authProvider.notifier).login(identifier, _pass.text);
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
                    await ref.read(authProvider.notifier).signInWithGoogle();
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
                    await ref.read(authProvider.notifier).signInWithFacebook();
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
