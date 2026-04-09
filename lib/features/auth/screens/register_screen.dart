import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:aqua_sort/core/theme/app_colors.dart';
import 'package:aqua_sort/features/auth/widgets/aqua_widgets.dart';
import 'package:country_code_picker/country_code_picker.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override State<RegisterScreen> createState() => _RegisterState();
}

class _RegisterState extends State<RegisterScreen> {
  final _form      = GlobalKey<FormState>();
  final _firstName   = TextEditingController();
  final _lastName    = TextEditingController();
  final _displayName = TextEditingController();
  final _pass        = TextEditingController();
  final _email       = TextEditingController();
  final _phone       = TextEditingController();
  String _countryCode = '+1';
  bool _showPass = false;
  bool _isPublic = false;
  File? _avatar;

  @override
  void dispose() { 
    _firstName.dispose(); 
    _lastName.dispose();
    _displayName.dispose();
    _pass.dispose(); 
    _email.dispose(); 
    _phone.dispose(); 
    super.dispose(); 
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _avatar = File(picked.path));
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
              const SizedBox(height: 22),

              // â”€â”€ Avatar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.tealAccent, width: 2),
                      color: AppColors.inputBg,
                    ),
                    child: _avatar != null
                        ? ClipOval(child: Image.file(_avatar!, fit: BoxFit.cover))
                        : const Icon(Icons.person_outline, size: 36, color: AppColors.textMuted),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AquaField(
                        label: 'Display Name', 
                        hint: 'Public name', 
                        controller: _displayName,
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      GestureDetector(
                        onTap: _pickImage,
                        child: Text('Change Avatar', 
                          style: GoogleFonts.outfit(color: AppColors.cyanGlow, fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 6),
              Text('Custom Collection', style: GoogleFonts.outfit(fontSize: 10, color: AppColors.tealMid)),
              const SizedBox(height: 16),

              // â”€â”€ Fields â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              AquaField(label: 'First Name', hint: 'First Name', controller: _firstName,
                  lockIcon: true,
                  validator: (v) => v == null || v.length < 2 ? 'Min 2 chars' : null),

              AquaField(label: 'Last Name', hint: 'Last Name', controller: _lastName,
                  lockIcon: true,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null),

              AquaField(label: 'Password', hint: 'Password',
                  controller: _pass, obscure: !_showPass, lockIcon: true,
                  suffix: IconButton(
                    icon: Icon(_showPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 17, color: AppColors.tealAccent),
                    onPressed: () => setState(() => _showPass = !_showPass),
                  ),
                  validator: (v) => v == null || v.length < 6 ? 'Min 6 chars' : null),

              AquaField(label: 'Email', hint: 'Email',
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
                        alignLeft: false,
                        textStyle: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                        dialogTextStyle: GoogleFonts.outfit(color: Colors.black, fontSize: 13),
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

              // â”€â”€ Private/Public toggle â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              Row(children: [
                const Icon(Icons.lock_outline, size: 15, color: AppColors.tealMid),
                const SizedBox(width: 6),
                Text('Private/Public', style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary)),
                const Spacer(),
                Switch(
                  value: _isPublic,
                  onChanged: (v) => setState(() => _isPublic = v),
                  activeColor: AppColors.cyanGlow,
                  activeTrackColor: AppColors.tealMid,
                  inactiveTrackColor: AppColors.inputBorder,
                ),
              ]),
              const SizedBox(height: 18),

              GlowButton(label: 'Create Account', onTap: () {
                if (_form.currentState!.validate()) {
                  context.go('/otp', extra: {
                    'firstName': _firstName.text,
                    'lastName': _lastName.text,
                    'displayName': _displayName.text,
                  });
                }
              }),
            ])),
          ),
        ),
      ),
    );
  }
}
