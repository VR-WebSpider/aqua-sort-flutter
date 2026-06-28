import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aqua_sort/core/theme/app_colors.dart';
import 'package:aqua_sort/features/auth/providers/auth_provider.dart';
import 'package:aqua_sort/features/auth/widgets/aqua_widgets.dart';
import 'package:aqua_sort/features/lobby/providers/level_provider.dart';
import 'package:aqua_sort/features/history/providers/history_provider.dart';
import 'package:aqua_sort/features/profile/providers/settings_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:aqua_sort/features/profile/widgets/profile_editor_overlay.dart';

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
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                child: ClipOval(
                                  child: (user?.avatarUrl != null)
                                     ? Image.network(user!.avatarUrl!, fit: BoxFit.cover)
                                     : const Icon(Icons.person_outline, size: 50, color: AppColors.textSecondary),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                user != null
                                    ? (user.displayName.isNotEmpty ? user.displayName : '${user.firstName} ${user.lastName}')
                                    : 'Guest Sorter',
                                style: GoogleFonts.outfit(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              if (user != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2.0, bottom: 4.0),
                                  child: Text(
                                    '@${user.username}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.tealAccent,
                                    ),
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
                        const SizedBox(height: 32),
                        _profileItem(Icons.person_outline, 'My Profile', onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => const ProfileEditorOverlay(),
                          );
                        }),
                        _profileItem(Icons.history_outlined, 'Game History', onTap: () => _showHistory(context)),
                        _profileItem(Icons.emoji_events_outlined, 'Achievements', onTap: () => _showAchievements(context)),
                        _profileItem(Icons.auto_awesome_outlined, 'Purity Exchange', onTap: () => context.push('/customization')),
                        _profileItem(Icons.settings_outlined, 'Settings', onTap: () => _showSettings(context)),
                        _profileItem(Icons.policy_outlined, 'Privacy Policy', onTap: () => _showPrivacy(context)),
                        _profileItem(Icons.delete_forever_outlined, 'Reset Progress & Data', isDestructive: true, onTap: () => _showResetConfirm(context, ref)),
                        const SizedBox(height: 24),
                        GlowButton(
                          label: auth.status == AuthStatus.guest ? 'Log In / Sign Up' : 'Log Out',
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showHistory(BuildContext context) {
    _showModal(context, 'GAME HISTORY', Consumer(
      builder: (context, ref, child) {
        final history = ref.watch(historyProvider);
        return Column(
          children: history.isEmpty 
            ? [const Padding(padding: EdgeInsets.all(40), child: Text('No games played yet.', style: TextStyle(color: Colors.white54)))]
            : history.map((r) => _historyRow(r)).toList(),
        );
      },
    ));
  }

  Widget _historyRow(GameRecord r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Level ${r.level}', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
              Text(DateFormat('MMM dd, HH:mm').format(r.date), style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
            ],
          ),
          Row(
            children: [
              _statMini(Icons.timer_outlined, '${r.seconds}s'),
              const SizedBox(width: 16),
              _statMini(Icons.touch_app_outlined, '${r.moves}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statMini(IconData icon, String val) {
    return Row(children: [
      Icon(icon, size: 14, color: AppColors.cyanGlow),
      const SizedBox(width: 4),
      Text(val, style: GoogleFonts.outfit(color: Colors.white, fontSize: 13)),
    ]);
  }

  void _showAchievements(BuildContext context) {
    _showModal(context, 'ACHIEVEMENTS', Consumer(
      builder: (context, ref, child) {
        final progress = ref.watch(levelProvider);
        final achievements = [
          {'title': 'First Steps', 'desc': 'Complete Level 1', 'icon': Icons.rocket_launch, 'unlocked': progress.unlockedLevels.length > 1},
          {'title': 'Coin Collector', 'desc': 'Earn 50 coins', 'icon': Icons.savings, 'unlocked': progress.coins >= 50},
          {'title': 'Experienced', 'desc': 'Complete Level 10', 'icon': Icons.workspace_premium, 'unlocked': progress.unlockedLevels.length >= 11},
          {'title': 'New Look', 'desc': 'Equip a new skin', 'icon': Icons.palette, 'unlocked': progress.activeSkinId != 'default'},
        ];

        return Column(
            children: achievements.map((a) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: (a['unlocked'] as bool) ? AppColors.tealAccent.withOpacity(0.4) : Colors.white10),
              ),
              child: Row(
                children: [
                   Icon(a['icon'] as IconData, color: (a['unlocked'] as bool) ? AppColors.tealAccent : Colors.white24, size: 30),
                   const SizedBox(width: 16),
                   Expanded(
                     child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(a['title'].toString(), style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text(a['desc'].toString(), style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
                     ]),
                   ),
                   if (a['unlocked'] as bool) const Icon(Icons.check_circle, color: AppColors.tealAccent, size: 18),
                ],
              ),
            )).toList(),
        );
      },
    ));
  }

  void _showSettings(BuildContext context) {
    _showModal(context, 'SETTINGS', Consumer(
      builder: (context, ref, child) {
        final settings = ref.watch(settingsProvider);
        return Column(
          children: [
            _settingToggle('Background Music', settings.musicEnabled, () => ref.read(settingsProvider.notifier).toggleMusic()),
            _settingToggle('Sound Effects', settings.sfxEnabled, () => ref.read(settingsProvider.notifier).toggleSfx()),
            _settingToggle('Haptic Feedback', settings.hapticsEnabled, () => ref.read(settingsProvider.notifier).toggleHaptics()),
          ],
        );
      },
    ));
  }

  Widget _settingToggle(String title, bool val, VoidCallback onToggle) {
     return Padding(
       padding: const EdgeInsets.symmetric(vertical: 8),
       child: SwitchListTile(
         title: Text(title, style: GoogleFonts.outfit(color: Colors.white)),
         value: val,
         onChanged: (_) => onToggle(),
         activeThumbColor: AppColors.cyanGlow,
         contentPadding: EdgeInsets.zero,
       ),
     );
  }

  void _showPrivacy(BuildContext context) {
    _showModal(context, 'PRIVACY POLICY', SingleChildScrollView(
      child: Text(
        "AQUA SORT PRIVACY POLICY\n\n1. Data Collection: We only store your game progress, level unlocks, and coin count locally on your device via SharedPreferences. If you create an account, we store your username and hashed password on our secure servers.\n\n2. Usage: This data is used solely to provide game progression and leaderboard features.\n\n3. Third Parties: We do not share your personal data with any third-party services.\n\n4. Permissions: The app requires internet access for account registration and leaderboards.\n\nFor more info, contact webspiderstudios@gmail.com",
        style: GoogleFonts.outfit(color: Colors.white70, height: 1.6),
      ),
    ));
  }

  void _showResetConfirm(BuildContext context, WidgetRef ref) {
     showDialog(
       context: context,
       builder: (ctx) => AlertDialog(
         backgroundColor: AppColors.deepNavy,
         title: Text('Reset All Progress?', style: GoogleFonts.righteous(color: Colors.white)),
         content: const Text('This will permanently delete your scores, coins, and history. Are you sure?', style: TextStyle(color: Colors.white70)),
         actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
            TextButton(
              onPressed: () {
                ref.read(levelProvider.notifier).resetProgress();
                ref.read(historyProvider.notifier).clearHistory();
                ref.read(authProvider.notifier).logout();
                context.go('/login');
              }, 
              child: const Text('YES, RESET', style: TextStyle(color: Colors.redAccent))
            ),
         ],
       ),
     );
  }

  void _showModal(BuildContext context, String title, Widget content) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: title,
      barrierColor: Colors.black.withOpacity(0.8),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, _, _) {
        return Center(
          child: Container(
            margin: const EdgeInsets.all(22),
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 450, maxHeight: 600),
            decoration: BoxDecoration(
              color: AppColors.deepNavy,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white10),
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Text(title, style: GoogleFonts.righteous(fontSize: 20, color: Colors.white, letterSpacing: 1.5)),
                       IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(context)),
                     ],
                   ),
                   const Divider(color: Colors.white10, height: 32),
                   Flexible(child: content),
                ],
              ),
            ),
          ),
        );
      },
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
