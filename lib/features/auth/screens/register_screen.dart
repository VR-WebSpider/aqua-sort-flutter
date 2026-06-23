import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aqua_sort/core/theme/app_colors.dart';
import 'package:aqua_sort/features/auth/widgets/aqua_widgets.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aqua_sort/features/auth/providers/auth_provider.dart';
import 'package:aqua_sort/features/auth/screens/legal_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show OAuthProvider;

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override ConsumerState<RegisterScreen> createState() => _RegisterState();
}

class _RegisterState extends ConsumerState<RegisterScreen> {
  final _form      = GlobalKey<FormState>();
  final _pass        = TextEditingController();
  final _confirmPass = TextEditingController();
  final _email       = TextEditingController();
  final _phone       = TextEditingController();
  String _countryCode = '+1';
  bool _showPass = false;
  bool _showConfirmPass = false;
  bool _agreed   = false;

  final String _privacyText = """
PRIVACY POLICY
Last Updated: April 14, 2026

WebSpider Studios is committed to protecting your privacy.

1. Information We Collect:
- Core Identity: Email Address and Phone Number (optional).
- Game Status: Coin balance, owned skins, and leaderboard scores.
- Security Logs: Verification attempts and challenges.

2. Security:
Any changes to your core identity are gated by our 'Zero Casualization' security protocol.

3. Data Storage:
Store using Supabase with enterprise-grade encryption and RLS.

Contact: webspiderstudios@gmail.com
""";

  final String _eulaText = """
USER AGREEMENT (EULA)
Last Updated: April 14, 2026

1. License Grant:
Personal, non-exclusive license to play Aqua Sort for entertainment.

2. Account Security:
You are responsible for your credentials and agree to the 'Zero Casualization' security requirements.

3. Virtual Goods:
Coins and Skins have no real-world monetary value.

4. Fair Play:
Cheating or exploiting results in account termination.

Contact: webspiderstudios@gmail.com
""";

  @override
  void dispose() { 
    _pass.dispose(); 
    _confirmPass.dispose();
    _email.dispose(); 
    _phone.dispose(); 
    super.dispose(); 
  }

  void _showLegal(String title, String content) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LegalScreen(title: title, content: content),
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
              AquaHeader(onBack: () => context.go('/login')),
              const SizedBox(height: 22),

              Text('Create Account', style: GoogleFonts.righteous(fontSize: 28, color: Colors.white,
                  shadows: [const Shadow(color: AppColors.cyanGlow, blurRadius: 22)])),
              const SizedBox(height: 4),
              Text('Join the Aqua Sort community', style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 32),

              // ── Fields ──────────────────────────────────────────────────
              AquaField(label: 'Email', hint: 'you@example.com',
                  controller: _email, keyboardType: TextInputType.emailAddress, lockIcon: true,
                  validator: (v) => v != null && v.contains('@') ? null : 'Invalid email'),

              // Phone with Optional badge
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('Phone Number', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: AppColors.tealMid.withOpacity(0.3),
                    ),
                    child: Text('Optional', style: GoogleFonts.outfit(fontSize: 10, color: AppColors.tealAccent)),
                  ),
                  const Spacer(),
                  const Icon(Icons.lock_outline, size: 13, color: AppColors.tealMid),
                ]),
                const SizedBox(height: 5),
                Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.inputBg, borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.inputBorder),
                  ),
                  child: Row(children: [
                    Container(
                      height: 46,
                      decoration: const BoxDecoration(
                        border: Border(right: BorderSide(color: AppColors.inputBorder))),
                      alignment: Alignment.center,
                      child: CountryCodePicker(
                        onChanged: (c) => setState(() => _countryCode = c.dialCode ?? '+1'),
                        initialSelection: WidgetsBinding.instance.platformDispatcher.locale.countryCode ?? 'US',
                        favorite: const ['+1', 'US'],
                        showCountryOnly: false,
                        showOnlyCountryWhenClosed: false,
                        hideSearch: false,
                        alignLeft: false,
                        textStyle: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                        dialogTextStyle: GoogleFonts.outfit(color: Colors.black, fontSize: 13),
                        searchDecoration: InputDecoration(
                          hintText: 'Search country...',
                          hintStyle: GoogleFonts.outfit(fontSize: 14, color: Colors.black54),
                          prefixIcon: const Icon(Icons.search, color: Colors.black45),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Phone Number',
                          hintStyle: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 14),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
              ]),

              AquaField(label: 'Password', hint: 'Min 6 characters',
                  controller: _pass, obscure: !_showPass, lockIcon: true,
                  suffix: IconButton(
                    icon: Icon(_showPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 17, color: AppColors.tealAccent),
                    onPressed: () => setState(() => _showPass = !_showPass),
                  ),
                  validator: (v) => v == null || v.length < 6 ? 'Min 6 chars' : null),

              AquaField(label: 'Confirm Password', hint: 'Re-enter your password',
                  controller: _confirmPass, obscure: !_showConfirmPass, lockIcon: true,
                  suffix: IconButton(
                    icon: Icon(_showConfirmPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 17, color: AppColors.tealAccent),
                    onPressed: () => setState(() => _showConfirmPass = !_showConfirmPass),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v != _pass.text) return 'Passwords do not match';
                    return null;
                  }),

              const SizedBox(height: 12),

              // ── Legal Checkbox ─────────────────────────────────────────
              Row(children: [
                SizedBox(
                  height: 24, width: 24,
                  child: Checkbox(
                    value: _agreed,
                    onChanged: (v) => setState(() => _agreed = v ?? false),
                    activeColor: AppColors.cyanGlow,
                    checkColor: AppColors.deepNavy,
                    side: const BorderSide(color: AppColors.tealMid),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary),
                      children: [
                        const TextSpan(text: 'I agree to the '),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: GestureDetector(
                            onTap: () => _showLegal('User Agreement', _eulaText),
                            child: Text('User Agreement', style: GoogleFonts.outfit(color: AppColors.cyanGlow, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const TextSpan(text: ' and '),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: GestureDetector(
                            onTap: () => _showLegal('Privacy Policy', _privacyText),
                            child: Text('Privacy Policy', style: GoogleFonts.outfit(color: AppColors.cyanGlow, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 28),

              GlowButton(
                label: 'Create Account', 
                loading: ref.watch(authProvider).isLoading,
                onTap: () async {
                  if (!_agreed) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please agree to the terms first'), backgroundColor: Colors.orangeAccent),
                    );
                    return;
                  }
                  if (_form.currentState!.validate()) {
                    try {
                      final fullPhone = _phone.text.isEmpty ? null : '$_countryCode${_phone.text}';
                      await ref.read(authProvider.notifier).signUp(
                        _email.text, 
                        _pass.text,
                        phone: fullPhone,
                      );
                      if (mounted) {
                        context.go('/otp', extra: {
                          'email': _email.text,
                          'phone': fullPhone,
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
            ])),
          ),
        ),
      ),
    );
  }
}
