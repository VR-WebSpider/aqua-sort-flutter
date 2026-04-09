import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aqua_sort/core/theme/app_colors.dart';
import 'package:aqua_sort/features/auth/providers/auth_provider.dart';
import 'package:aqua_sort/features/auth/widgets/aqua_widgets.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;

    return Scaffold(
      body: aquaBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(22.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AquaHeader(onBack: () => context.pop()),
                const SizedBox(height: 32),
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.cyanGlow, width: 2),
                          color: AppColors.inputBg,
                        ),
                        child: const Icon(Icons.person_outline, size: 50, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user?.username ?? 'Sorter',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        user?.email ?? 'No email linked',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                _profileItem(Icons.history_outlined, 'Game History'),
                _profileItem(Icons.emoji_events_outlined, 'Achievements'),
                _profileItem(Icons.settings_outlined, 'Settings'),
                _profileItem(Icons.policy_outlined, 'Privacy Policy', onTap: () {
                    // Open typical placeholder or studio policy
                }),
                _profileItem(Icons.delete_forever_outlined, 'Delete Account & Data', isDestructive: true, onTap: () {
                    // Sign out for now
                    ref.read(authProvider.notifier).logout();
                    context.go('/login');
                }),
                const Spacer(),
                GlowButton(
                  label: 'Log Out',
                  outlined: true,
                  onTap: () {
                    ref.read(authProvider.notifier).logout();
                    context.go('/login');
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _profileItem(IconData icon, String title, {bool isDestructive = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.inputBg.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDestructive ? Colors.redAccent.withOpacity(0.3) : AppColors.inputBorder),
          ),
          child: Row(
            children: [
              Icon(icon, color: isDestructive ? Colors.redAccent : AppColors.cyanGlow, size: 20),
              const SizedBox(width: 16),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: isDestructive ? Colors.redAccent : Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios, color: AppColors.textMuted, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
