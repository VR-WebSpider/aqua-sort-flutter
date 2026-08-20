import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aqua_sort/core/theme/app_colors.dart';
import 'package:aqua_sort/features/auth/widgets/aqua_widgets.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aqua_sort/features/auth/providers/auth_provider.dart';
import 'package:aqua_sort/features/auth/screens/legal_screen.dart';

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
  bool _allowPhoneLogin = false;
  bool _allowUsernameLogin = false;
  bool _isSubmitting = false;

  final String _privacyText = """
PRIVACY POLICY
Last Updated: July 8, 2026

WebSpider Studios ("we", "our", "us") operates Aqua Sort. This policy explains what data we collect, why we collect it, and your rights.

1. INFORMATION WE COLLECT

a) Account Data (if you register):
   - Email address — used for authentication and account recovery.
   - Display name — shown publicly on leaderboards.
   - Phone number — optional, used only for two-factor security.
   - Profile avatar — optional image you upload.

b) Game Progress Data:
   - Coin balance, owned skins, unlocked levels, game history.
   - Stored on our Supabase backend (linked to your account) and locally on your device.

c) Advertising Data (AdMob by Google):
   - When you view advertisements, Google's AdMob SDK may collect your device's Advertising ID, IP address, and usage signals to serve relevant ads.
   - You may opt out of personalised ads through your device settings (Settings > Privacy > Ads).

d) In-App Purchase Data:
   - Transactions are processed by Google Play. We do not collect or store your payment card details. We receive only a confirmation of purchase to unlock content.

e) Multiplayer & Leaderboard Data:
   - Your display name and score are stored on our servers and may be visible to other players on public leaderboards.

f) Diagnostic Data:
   - App crash reports and error logs (anonymous, no personal data) to improve stability.

2. HOW WE USE YOUR DATA
   - To authenticate you and save your game progress across devices.
   - To display your rank on leaderboards (display name only).
   - To serve advertisements through Google AdMob.
   - To fulfil in-app purchases via Google Play Billing.
   - To improve app stability and fix bugs.

3. DATA SHARING & THIRD PARTIES
   - Supabase (supabase.com) — Our secure database backend. Data is encrypted at rest and in transit.
   - Google AdMob — Advertising platform. See Google's privacy policy at policies.google.com/privacy.
   - Google Play Games Services — Used for achievements and leaderboards.
   - We do NOT sell your personal data to any third parties.

4. DATA RETENTION
   - Your account data is retained as long as your account exists.
   - You may request deletion of your account and all associated data at any time.

5. YOUR RIGHTS (GDPR / CCPA)
   - Access: Request a copy of the data we hold about you.
   - Correction: Request correction of inaccurate data.
   - Deletion: Request deletion of your account and all personal data.
   - Opt-Out of Ads: Disable personalised advertising in your device settings.

6. CHILDREN'S PRIVACY
   - This app is rated for users aged 7 and above. We do not knowingly collect personal data from children under 13 without parental consent. If you believe a child has provided personal data, contact us immediately.

7. SECURITY
   - All data transmissions use TLS/SSL encryption.
   - Account changes are protected by our email-verified security protocol.
   - We use Supabase Row Level Security (RLS) to ensure users can only access their own data.

8. CONTACT
   - Email: webspiderstudios@gmail.com
   - You may also contact us to exercise any of your rights above.
""";

  final String _eulaText = """
END-USER LICENSE AGREEMENT (EULA)
Last Updated: July 8, 2026

This EULA is a legal agreement between you and WebSpider Studios for the use of Aqua Sort.

1. LICENSE GRANT
We grant you a personal, non-exclusive, non-transferable, revocable license to install and play Aqua Sort on Android devices you own or control, solely for personal, non-commercial entertainment.

2. ACCOUNT & SECURITY
   - You are responsible for maintaining the confidentiality of your account credentials.
   - You agree to our email-verified security protocol for all sensitive account changes.
   - Guest accounts are not backed up. Progress may be lost if the app is uninstalled.

3. IN-APP PURCHASES & VIRTUAL GOODS
   - Aqua Sort offers optional in-app purchases (coin packs, premium subscription) through Google Play Billing.
   - All purchases are final. Refunds are handled by Google Play's refund policy.
   - Virtual currency (Coins) and cosmetic items (Skins) have no real-world monetary value and cannot be exchanged for cash.
   - Premium subscriptions auto-renew unless cancelled at least 24 hours before the renewal date.

4. ADVERTISEMENTS
   - The free version of Aqua Sort displays ads provided by Google AdMob.
   - Purchasing Premium removes all advertisements.
   - You may control personalised ad preferences through your device's advertising settings.

5. MULTIPLAYER & ONLINE FEATURES
   - Online multiplayer and leaderboard features require an internet connection and a registered account.
   - Online features are provided "as-is" and may be subject to availability.

6. FEATURES IN DEVELOPMENT
   - Some features (including certain multiplayer enhancements) are actively being developed and may evolve or change in future updates.

7. FAIR PLAY & PROHIBITED CONDUCT
   - Cheating, hacking, exploiting bugs, or using automated tools is strictly prohibited.
   - Offensive display names or harassment of other players will result in account suspension or termination.

8. INTELLECTUAL PROPERTY
   - All game content, artwork, code, and audio are the intellectual property of WebSpider Studios. You may not copy, modify, or distribute any content without written permission.

9. TERMINATION
   - We reserve the right to suspend or terminate accounts that violate this agreement without prior notice.

10. DISCLAIMER OF WARRANTIES
    - The app is provided "as is" without any warranty of uninterrupted or error-free operation.

11. LIMITATION OF LIABILITY
    - To the maximum extent permitted by law, WebSpider Studios shall not be liable for any indirect, incidental, or consequential damages arising from your use of the app.

12. GOVERNING LAW
    - This agreement is governed by applicable law. Disputes shall be resolved through good-faith negotiation before any legal action.

CONTACT: webspiderstudios@gmail.com
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
                const SizedBox(height: 8),
                Row(
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: _allowPhoneLogin,
                        onChanged: (v) => setState(() => _allowPhoneLogin = v ?? false),
                        activeColor: AppColors.cyanGlow,
                        checkColor: AppColors.deepNavy,
                        side: const BorderSide(color: AppColors.tealMid),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('Allow login with Phone Number', style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary)),
                  ],
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
              
              const SizedBox(height: 8),
              Row(
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _allowUsernameLogin,
                      onChanged: (v) => setState(() => _allowUsernameLogin = v ?? false),
                      activeColor: AppColors.cyanGlow,
                      checkColor: AppColors.deepNavy,
                      side: const BorderSide(color: AppColors.tealMid),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('Allow login with Username', style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: 16),

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
                loading: ref.watch(authProvider).isLoading || _isSubmitting,
                onTap: () async {
                  if (_isSubmitting) return;
                  if (!_agreed) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please agree to the terms first'), backgroundColor: Colors.orangeAccent),
                    );
                    return;
                  }
                  if (_form.currentState!.validate()) {
                    try {
                      setState(() => _isSubmitting = true);
                      await ref.read(authProvider.notifier).signUpWithEmail(
                        email: _email.text.trim(), 
                        password: _pass.text,
                        firstName: 'Player',
                        lastName: '',
                        username: _email.text.split('@').first,
                      );
                      if (mounted) {
                        context.go('/lobby');
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isSubmitting = false);
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
            ])),
          ),
        ),
      ),
    );
  }
}
