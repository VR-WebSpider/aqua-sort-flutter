import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aqua_sort/core/theme/app_colors.dart';
import 'package:aqua_sort/features/auth/widgets/aqua_widgets.dart';
import 'package:aqua_sort/features/auth/providers/auth_provider.dart';
import 'package:aqua_sort/features/profile/widgets/profile_otp_overlay.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:aqua_sort/core/router/app_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ProfileEditorOverlay extends ConsumerStatefulWidget {
  const ProfileEditorOverlay({super.key});

  @override
  ConsumerState<ProfileEditorOverlay> createState() => _ProfileEditorOverlayState();
}

class _ProfileEditorOverlayState extends ConsumerState<ProfileEditorOverlay> {
  late TextEditingController _firstController;
  late TextEditingController _lastController;
  late TextEditingController _usernameController;
  late TextEditingController _displayController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  String _countryCode = '+91';
  
  bool _isEditing = false;
  int _avatarIdx = 0;
  final List<String> _avatars = [
    'https://img.freepik.com/free-vector/spider-mascot-logo-illustration_23-2148924087.jpg', // Spider
    'https://img.freepik.com/free-vector/hacker-operating-laptop-cartoon-icon-illustration-technology-business-icon-concept-isolated-flat-cartoon_138676-2387.jpg', // Hacker
    'https://img.freepik.com/free-vector/cyborg-woman-head_1308-46639.jpg', // Cyborg
    'https://img.freepik.com/free-vector/astronaut-meditating-cartoon-illustration_138676-3243.jpg', // Astronaut
    'https://img.freepik.com/free-vector/cute-robot-waving-hand-cartoon-character_138676-3144.jpg', // Robot
    'https://img.freepik.com/free-vector/ninja-mascot-logo-illustration_23-2148924089.jpg', // Ninja
  ];

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _firstController = TextEditingController(text: user?.firstName ?? '');
    _lastController = TextEditingController(text: user?.lastName ?? '');
    _usernameController = TextEditingController(text: user?.username ?? '');
    _displayController = TextEditingController(text: user?.displayName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    
    if (user?.avatarUrl != null) {
      _avatarIdx = _avatars.indexOf(user!.avatarUrl!).clamp(0, _avatars.length - 1);
    }
  }

  @override
  void dispose() {
    _firstController.dispose();
    _lastController.dispose();
    _usernameController.dispose();
    _displayController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    final firstName = _firstController.text.trim();
    final lastName = _lastController.text.trim();
    final displayName = _displayController.text.trim();
    final username = _usernameController.text.trim().toLowerCase();
    final newEmail = _emailController.text.trim().toLowerCase();
    
    // Clean and normalize phone number
    final localPhone = _phoneController.text.trim();
    final newPhone = localPhone.isNotEmpty 
        ? '$_countryCode $localPhone'.replaceAll(RegExp(r'[\s\-\(\)]'), '')
        : '';
        
    final isUsernameChanged = username != (user.username).toLowerCase();
    final isEmailChanged = newEmail != (user.email ?? '').toLowerCase();
    final isPhoneChanged = newPhone != (user.phone ?? '').replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final isDisplayNameChanged = displayName != user.displayName;

    final isUsernameLocked = user.usernameChangesCount >= 1;
    final lastUpdated = user.displayNameUpdatedAt;
    final nextAvailableDate = lastUpdated?.add(const Duration(days: 180));
    final isDisplayNameLocked = nextAvailableDate != null && DateTime.now().isBefore(nextAvailableDate);

    if (isUsernameChanged && isUsernameLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username is locked and cannot be changed.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    if (isDisplayNameChanged && isDisplayNameLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Display name is locked and cannot be changed.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    // Validate inputs
    if (displayName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Display name is required.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    if (username.isEmpty || !RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(username)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username must be 3-20 characters, containing only lowercase letters, numbers, or underscores.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    if (newEmail.isEmpty || !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(newEmail)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email address.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    // Start loading/saving
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final firestore = FirebaseFirestore.instance;

      // Uniqueness Checks
      if (isUsernameChanged) {
        final query = await firestore.collection('users').where('username', isEqualTo: username.toLowerCase().trim()).get();
        if (query.docs.isNotEmpty && query.docs.first.id != user.id) {
          throw 'Username is already taken.';
        }
      }

      if (isEmailChanged) {
        final query = await firestore.collection('users').where('email', isEqualTo: newEmail.trim()).get();
        if (query.docs.isNotEmpty && query.docs.first.id != user.id) {
          throw 'Email is already registered.';
        }
      }

      if (isPhoneChanged && newPhone.isNotEmpty) {
        final query = await firestore.collection('users').where('phone', isEqualTo: newPhone.trim()).get();
        if (query.docs.isNotEmpty && query.docs.first.id != user.id) {
          throw 'Phone number is already registered.';
        }
      }

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (isUsernameChanged || isEmailChanged || isPhoneChanged) {
        // Gated by OTP Verification sent to registered email
        if (mounted) {
          showDialog(
            context: context,
            builder: (_) => ProfileOtpOverlay(
              email: user.email ?? newEmail, // Trigger to current registered email
              phone: user.phone ?? newPhone,
              onVerified: () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(child: CircularProgressIndicator()),
                );
                try {
                  // Perform DB Updates
                  await ref.read(authProvider.notifier).updateProfile(
                    firstName: firstName,
                    lastName: lastName,
                    displayName: displayName,
                    avatarUrl: _avatars[_avatarIdx],
                    username: username,
                    phone: newPhone,
                    email: newEmail,
                    usernameChangesCount: isUsernameChanged ? user.usernameChangesCount + 1 : null,
                    displayNameUpdatedAt: isDisplayNameChanged ? DateTime.now() : null,
                  );
                  // Update GoTrue Email / Phone
                  if (isEmailChanged) {
                    await ref.read(authProvider.notifier).updateEmail(newEmail);
                  }
                  if (isPhoneChanged) {
                    await ref.read(authProvider.notifier).updatePhone(newPhone);
                  }
                  if (mounted) {
                    Navigator.pop(context); // Close loading indicator
                    setState(() => _isEditing = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(context); // Close loading indicator
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.redAccent),
                    );
                  }
                }
              },
            ),
          );
        }
      } else {
        // Direct save (only display name / basic info changed)
        await ref.read(authProvider.notifier).updateProfile(
          firstName: firstName,
          lastName: lastName,
          displayName: displayName,
          avatarUrl: _avatars[_avatarIdx],
          displayNameUpdatedAt: isDisplayNameChanged ? DateTime.now() : null,
        );
        if (mounted) {
          setState(() => _isEditing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _triggerVerifyFull({VoidCallback? onVerifiedOverride}) {
    showDialog(
      context: context,
      builder: (_) => ProfileOtpOverlay(
        email: _emailController.text,
        phone: '$_countryCode ${_phoneController.text}',
        onVerified: onVerifiedOverride ?? () {
          ref.read(authProvider.notifier).updateEmail(_emailController.text);
          ref.read(authProvider.notifier).updatePhone('$_countryCode ${_phoneController.text}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Security info updated across all channels!'), backgroundColor: Colors.green),
          );
        },
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        final oldPassController = TextEditingController();
        final passController = TextEditingController();
        final confirmController = TextEditingController();
        bool isValid = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            void updateState() {
              setDialogState(() {
                isValid = oldPassController.text.isNotEmpty &&
                          passController.text.length >= 6 && 
                          passController.text == confirmController.text &&
                          passController.text != oldPassController.text;
              });
            }

            return AlertDialog(
              backgroundColor: AppColors.deepNavy,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Colors.white10)),
              title: Text('CHANGE PASSWORD', style: GoogleFonts.righteous(color: Colors.white, letterSpacing: 1.5)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AquaField(label: 'Old Password', hint: 'Enter current password', controller: oldPassController, obscure: true, onChanged: (_) => updateState()),
                    const Divider(color: Colors.white10, height: 32),
                    AquaField(label: 'New Password', hint: 'Min 6 characters', controller: passController, obscure: true, onChanged: (_) => updateState()),
                    AquaField(label: 'Confirm Password', hint: 'Must match', controller: confirmController, obscure: true, onChanged: (_) => updateState()),
                    if (passController.text.isNotEmpty && confirmController.text.isNotEmpty && passController.text != confirmController.text)
                      const Text('Passwords do not match', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
                Opacity(
                  opacity: isValid ? 1.0 : 0.4,
                  child: TextButton(
                    onPressed: isValid ? () async {
                      final oldPass = oldPassController.text;
                      final newPass = passController.text;
                      
                      // 1. Verify old password first
                      final isOldCorrect = await ref.read(authProvider.notifier).verifyOldPassword(oldPass);
                      
                      if (!isOldCorrect) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Incorrect old password.'), backgroundColor: Colors.redAccent),
                          );
                        }
                        return;
                      }

                      // 2. If correct, proceed with OTP
                      if (context.mounted) Navigator.pop(ctx);
                      _triggerVerifyFull(
                        onVerifiedOverride: () async {
                          try {
                            // Perform the update first
                            await ref.read(authProvider.notifier).updatePassword(newPass);
                            
                            // Use routerProvider to avoid context/mounting issues
                            final router = ref.read(routerProvider);
                            
                            if (context.mounted) {
                              // Close the Profile Editor overlay
                              Navigator.of(context).pop();
                            }
                            
                            // Force navigate to success screen
                            router.go('/success', extra: {
                              'title': 'Success!',
                              'message': 'Your password has been changed successfully.',
                            });
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString().contains('same_password') 
                                  ? 'New password must be different from the old one.' 
                                  : 'Failed to update password: $e'), backgroundColor: Colors.redAccent),
                              );
                            }
                          }
                        }
                      );
                    } : null,
                    child: const Text('VERIFY & UPDATE', style: TextStyle(color: AppColors.cyanGlow)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirm() {
    showDialog(
      context: context,
      builder: (ctx) {
        final confirmController = TextEditingController();
        return AlertDialog(
          backgroundColor: AppColors.deepNavy,
          title: Text('DELETE ACCOUNT?', style: GoogleFonts.righteous(color: Colors.redAccent)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('This action is permanent and cannot be undone.', 
                style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 20),
              const Text('Type "DELETE" to confirm:', style: TextStyle(color: Colors.white54, fontSize: 12)),
              TextField(
                controller: confirmController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.redAccent))),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
            TextButton(
              onPressed: () {
                if (confirmController.text == 'DELETE') {
                  ref.read(authProvider.notifier).deleteAccount();
                  Navigator.pop(ctx); 
                  Navigator.pop(context);
                }
              }, 
              child: const Text('CONFIRM DELETION', style: TextStyle(color: Colors.redAccent))
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isUsernameLocked = user != null && user.usernameChangesCount >= 1;
    final lastUpdated = user?.displayNameUpdatedAt;
    final nextAvailableDate = lastUpdated?.add(const Duration(days: 180));
    final isDisplayNameLocked = nextAvailableDate != null && DateTime.now().isBefore(nextAvailableDate);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.deepNavy,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 40),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('MY PROFILE', style: GoogleFonts.righteous(fontSize: 24, color: Colors.white, letterSpacing: 2)),
                IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(color: Colors.white10, height: 40),
            
            // ── Avatar Section ──────────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.cyanGlow, width: 2),
                      boxShadow: [BoxShadow(color: AppColors.cyanGlow.withOpacity(0.2), blurRadius: 20)],
                    ),
                    child: ClipOval(child: Image.network(_avatars[_avatarIdx], fit: BoxFit.cover)),
                  ),
                  if (_isEditing) ...[
                    const SizedBox(height: 16),
                    Text(
                      'CHOOSE PROFILE PHOTO',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.tealAccent,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(_avatars.length, (idx) {
                        final isSelected = _avatarIdx == idx;
                        return GestureDetector(
                          onTap: () => setState(() => _avatarIdx = idx),
                          child: Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? AppColors.cyanGlow : Colors.white10,
                                width: isSelected ? 2.5 : 1.5,
                              ),
                              boxShadow: isSelected
                                  ? [BoxShadow(color: AppColors.cyanGlow.withOpacity(0.3), blurRadius: 8)]
                                  : null,
                            ),
                            child: ClipOval(child: Image.network(_avatars[idx], fit: BoxFit.cover)),
                          ),
                        );
                      }),
                    ),
                  ],
                  const SizedBox(height: 16),
                  GlowButton(
                    label: _isEditing ? 'SAVE CHANGES' : 'EDIT MY PROFILE',
                    outlined: !_isEditing,
                    onTap: () {
                      if (_isEditing) {
                        _saveProfile();
                      } else {
                        setState(() => _isEditing = true);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            _sectionTitle('PERSONAL INFORMATION'),
            Row(
              children: [
                Expanded(child: AquaField(label: 'First Name', hint: 'First Name', controller: _firstController, enabled: _isEditing)),
                const SizedBox(width: 12),
                Expanded(child: AquaField(label: 'Last Name', hint: 'Last Name', controller: _lastController, enabled: _isEditing)),
              ],
            ),
            const SizedBox(height: 12),
            AquaField(
              label: '🔒 Username (used for secure login)',
              hint: 'username',
              controller: _usernameController,
              enabled: _isEditing && !isUsernameLocked,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
              child: Text(
                isUsernameLocked
                    ? '🔒 Username has been updated once and is locked.'
                    : 'ℹ️ Secure username can only be changed once.',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isUsernameLocked ? Colors.redAccent : AppColors.tealAccent,
                ),
              ),
            ),
            const SizedBox(height: 12),
            AquaField(
              label: '👋 Display Name (shown publicly)',
              hint: 'Display Name',
              controller: _displayController,
              enabled: _isEditing && !isDisplayNameLocked,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
              child: Text(
                isDisplayNameLocked
                    ? '⏳ Locked until ${DateFormat('MMMM dd, yyyy').format(nextAvailableDate)} (changed once in 6 months).'
                    : 'ℹ️ Public display name can be changed once in 6 months.',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDisplayNameLocked ? Colors.redAccent : AppColors.tealAccent,
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            _sectionTitle('CONTACT DETAILS'),
            AquaField(label: 'Email Address', hint: 'email@example.com', controller: _emailController, enabled: _isEditing, suffix: const Icon(Icons.email_outlined, size: 16, color: Colors.white24)),
            
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  height: 46,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: _isEditing ? AppColors.inputBg : AppColors.inputBg.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _isEditing ? AppColors.inputBorder : AppColors.inputBorder.withOpacity(0.2)),
                  ),
                  child: CountryCodePicker(
                    enabled: _isEditing,
                    onChanged: (c) => setState(() => _countryCode = c.dialCode!),
                    initialSelection: 'IN',
                    favorite: const ['+91', 'IN'],
                    textStyle: GoogleFonts.outfit(color: _isEditing ? Colors.white : Colors.white24, fontSize: 13),
                    showCountryOnly: false,
                    showOnlyCountryWhenClosed: false,
                    alignLeft: false,
                    padding: EdgeInsets.zero,
                    // Enable Search
                    showDropDownButton: true,
                    searchDecoration: InputDecoration(
                      hintText: 'Search country...',
                      hintStyle: const TextStyle(color: Colors.white24),
                      fillColor: AppColors.deepNavy,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)),
                    ),
                    searchStyle: const TextStyle(color: Colors.white),
                    dialogBackgroundColor: AppColors.deepNavy,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: AquaField(label: 'Phone Number', hint: 'Mobile', controller: _phoneController, enabled: _isEditing)),
              ],
            ),

            if (_isEditing)
               Align(
                 alignment: Alignment.centerRight,
                 child: TextButton.icon(
                   icon: const Icon(Icons.shield_outlined, size: 16, color: AppColors.cyanGlow),
                   label: const Text('SECURE UPDATE (EMAIL + PHONE)', style: TextStyle(color: AppColors.cyanGlow, fontSize: 12)),
                   onPressed: _triggerVerifyFull,
                 ),
               ).animate().fadeIn().moveY(begin: 10, end: 0),
            
            if (_isEditing) ...[
               const SizedBox(height: 32),
               _sectionTitle('SECURITY'),
               GlowButton(
                 label: 'CHANGE PASSWORD',
                 outlined: true,
                 icon: Icons.lock_outline,
                 onTap: _showChangePasswordDialog,
               ),
             ],

            const SizedBox(height: 60),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DANGER ZONE', style: GoogleFonts.righteous(color: Colors.redAccent, fontSize: 16, letterSpacing: 1.5)),
                  const SizedBox(height: 8),
                  const Text('Permanently remove your account and all associated data from our servers.', 
                    style: TextStyle(color: Colors.white54, fontSize: 13)),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _showDeleteConfirm, 
                    child: Text('DELETE MY ACCOUNT', style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.bold))
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(title, style: GoogleFonts.outfit(color: AppColors.tealAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
    );
  }
}
