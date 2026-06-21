import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aqua_sort/core/theme/app_colors.dart';
import 'package:aqua_sort/features/auth/widgets/aqua_widgets.dart';
import 'package:aqua_sort/features/auth/providers/auth_provider.dart';
import 'package:aqua_sort/features/auth/screens/dual_verification_screen.dart';
import 'package:aqua_sort/features/auth/widgets/purity_challenge_modal.dart';

class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  ConsumerState<ProfileSettingsScreen> createState() => _ProfileSettingsState();
}

class _ProfileSettingsState extends ConsumerState<ProfileSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      body: aquaBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      'Account Purity',
                      style: GoogleFonts.righteous(
                        fontSize: 24,
                        color: Colors.white,
                        shadows: [const Shadow(color: AppColors.cyanGlow, blurRadius: 10)],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // ── Identity Profile Card ──────────────────────────────────
                _buildSectionHeader('Identity Matrix'),
                const SizedBox(height: 12),
                _buildInfoTile(
                  label: 'Full Name',
                  value: '${user.firstName} ${user.lastName}',
                  icon: Icons.person_outline,
                  onEdit: () => _initiateSecureChange('name'),
                ),
                _buildInfoTile(
                  label: 'Email Address',
                  value: user.email ?? 'Not linked',
                  icon: Icons.alternate_email,
                  onEdit: () => _initiateSecureChange('email'),
                ),
                _buildInfoTile(
                  label: 'Phone Identity',
                  value: user.phone ?? 'Not linked',
                  icon: Icons.phone_android_outlined,
                  onEdit: () => _initiateSecureChange('phone'),
                ),

                const SizedBox(height: 40),
                _buildSectionHeader('Security Status'),
                const SizedBox(height: 12),
                _buildStatusTile(
                  label: 'Account Status',
                  status: 'VERIFIED',
                  color: Colors.greenAccent,
                ),
                _buildStatusTile(
                  label: 'Purity Level',
                  status: 'HIGH SECURE',
                  color: AppColors.cyanGlow,
                ),

                const SizedBox(height: 50),
                Center(
                  child: Text(
                    'Zero Casualization Protocol Active',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: AppColors.textMuted,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: AppColors.tealAccent,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildInfoTile({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onEdit,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.inputBg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.tealMid, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted)),
                Text(value, style: GoogleFonts.outfit(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onEdit,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.cyanGlow, width: 1),
              ),
              child: Text(
                'EDIT',
                style: GoogleFonts.outfit(fontSize: 10, color: AppColors.cyanGlow, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTile({required String label, required String status, required Color color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textSecondary)),
        Text(
          status,
          style: GoogleFonts.righteous(fontSize: 14, color: color, letterSpacing: 1),
        ),
      ],
    );
  }

  void _initiateSecureChange(String type) {
    if (type == 'email') {
      _showEmailUpdateDialog();
    } else if (type == 'phone') {
      _showSimpleUpdateDialog('Phone Identity', 'Enter new phone number', (val) async {
        await ref.read(authProvider.notifier).updatePhone(val);
      });
    } else {
      _showSimpleUpdateDialog('Full Identity', 'Enter new display name', (val) async {
        final names = val.split(' ');
        await ref.read(authProvider.notifier).updateProfile(
          firstName: names.first,
          lastName: names.length > 1 ? names.last : '',
        );
      });
    }
  }

  void _showEmailUpdateDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkBlue,
        title: Text('New Identity Target', style: GoogleFonts.righteous(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'Enter new email address', hintStyle: TextStyle(color: Colors.white38)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () async {
              final newEmail = controller.text;
              Navigator.pop(context);
              
              // 1. Kick off Dual Verification logic
              await ref.read(authProvider.notifier).initiateEmailSwap(newEmail);
              
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DualVerificationScreen(newEmail: newEmail)),
                );
              }
            },
            child: const Text('INITIATE SWAP', style: TextStyle(color: AppColors.cyanGlow)),
          ),
        ],
      ),
    );
  }

  void _showSimpleUpdateDialog(String title, String hint, Function(String) onSave) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkBlue,
        title: Text(title, style: GoogleFonts.righteous(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: Colors.white38)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () async {
              final val = controller.text;
              Navigator.pop(context);
              
              // Gated by Purity Challenge
              final verified = await showDialog<bool>(
                context: context,
                builder: (context) => const PurityChallengeDialog(),
              );

              if (verified == true) {
                await onSave(val);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Identity Updated'), backgroundColor: Colors.greenAccent),
                  );
                }
              }
            },
            child: const Text('VERIFY & SAVE', style: TextStyle(color: AppColors.cyanGlow)),
          ),
        ],
      ),
    );
  }
}
