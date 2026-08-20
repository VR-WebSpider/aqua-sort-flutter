import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:aqua_sort/core/theme/app_colors.dart';
import 'package:aqua_sort/features/auth/widgets/aqua_widgets.dart';
import 'package:aqua_sort/features/lobby/providers/multiplayer_provider.dart';
import 'package:aqua_sort/features/auth/providers/auth_provider.dart';
import 'package:aqua_sort/features/game/providers/game_provider.dart';
import 'package:aqua_sort/features/game/engine/game_engine.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MultiplayerLobbyScreen extends ConsumerStatefulWidget {
  const MultiplayerLobbyScreen({super.key});

  @override
  ConsumerState<MultiplayerLobbyScreen> createState() => _MultiplayerLobbyScreenState();
}

class _MultiplayerLobbyScreenState extends ConsumerState<MultiplayerLobbyScreen> {
  bool _isNavigating = false;

  Difficulty _parseDifficulty(String diff) {
    switch (diff.toLowerCase()) {
      case 'easy':
        return Difficulty.easy;
      case 'medium':
        return Difficulty.medium;
      case 'hard':
        return Difficulty.hard;
      case 'expert':
        return Difficulty.expert;
      default:
        return Difficulty.medium;
    }
  }

  Color _getDifficultyColor(String diff) {
    switch (diff.toLowerCase()) {
      case 'easy':
        return Colors.greenAccent;
      case 'medium':
        return AppColors.cyanGlow;
      case 'hard':
        return Colors.orangeAccent;
      default:
        return AppColors.tealAccent;
    }
  }

  Future<String?> _showDifficultyPicker(BuildContext context, String title) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.deepNavy.withOpacity(0.95),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.cyanGlow.withOpacity(0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cyanGlow.withOpacity(0.15),
                  blurRadius: 24,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.righteous(
                    fontSize: 22,
                    color: Colors.white,
                    letterSpacing: 1.2,
                    shadows: [
                      const Shadow(color: AppColors.cyanGlow, blurRadius: 10),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Select the difficulty of the sort duel',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                _buildDifficultyOption(context, 'EASY', '4 Colors • 50 Moves • 180s', Colors.greenAccent, 'easy'),
                const SizedBox(height: 12),
                _buildDifficultyOption(context, 'MEDIUM', '6 Colors • 70 Moves • 240s', AppColors.cyanGlow, 'medium'),
                const SizedBox(height: 12),
                _buildDifficultyOption(context, 'HARD', '7 Colors • 90 Moves • 300s', Colors.orangeAccent, 'hard'),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: Text(
                    'CANCEL',
                    style: GoogleFonts.outfit(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDifficultyOption(
    BuildContext context,
    String label,
    String description,
    Color color,
    String value,
  ) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, value),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.righteous(
                    fontSize: 16,
                    color: color,
                    letterSpacing: 1.0,
                  ),
                ),
                Text(
                  description,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            Icon(Icons.chevron_right_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _showChallengeDialog(BuildContext context, PresenceUser player) async {
    if (player.status == 'in_match') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${player.username} is currently in a match.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final diff = await _showDifficultyPicker(context, 'CHALLENGE ${player.username.toUpperCase()}');
    if (diff == null) return;

    try {
      await ref.read(multiplayerProvider.notifier).challengePlayer(player, diff);
      // Notifier will update state, causing listener to navigate to waiting room.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initiate challenge: $e')),
        );
      }
    }
  }

  Future<void> _declineChallenge(Room room) async {
    try {
      await FirebaseFirestore.instance.collection('rooms').doc(room.id).delete();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to decline: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final multiState = ref.watch(multiplayerProvider);
    final auth = ref.watch(authProvider);

    // Watch for match pairing / creation to route correctly
    ref.listen<MultiplayerState>(multiplayerProvider, (prev, next) async {
      if (_isNavigating) return;

      if (next.matchmakingStatus == MatchmakingStatus.matched && next.myRoom != null) {
        setState(() => _isNavigating = true);
        
        ref.read(gameArgsProvider.notifier).state = GameArgs(
          difficulty: _parseDifficulty(next.myRoom!.difficulty),
          playerCount: 2,
          isOnline: true,
          roomId: next.myRoom!.id,
          seed: next.myRoom!.seed,
        );

        // Allow "MATCH FOUND!" card to animate before redirecting
        await Future.delayed(const Duration(milliseconds: 2000));
        
        if (mounted) {
          _isNavigating = false;
          context.go('/game');
        }
      } else if (next.myRoom != null && (prev?.myRoom == null)) {
        // We created a room (matchmaking host or direct challenger host)
        context.go('/waiting-room');
      }
    });

    if (auth.isLoading || multiState.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.deepNavy,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.cyanGlow),
        ),
      );
    }

    if (auth.status == AuthStatus.guest) {
      return _buildGuestOverlay(context);
    }

    final myId = auth.user?.id;
    final incomingChallenges = multiState.activeRooms.where((r) => r.challengedUserId == myId && r.hostId != myId).toList();
    final publicRooms = multiState.activeRooms.where((r) => r.challengedUserId == null && r.hostId != myId).toList();

    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      body: aquaBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AquaHeader(onBack: () => context.go('/lobby')),
                const SizedBox(height: 12),
                _buildHeader(),
                const SizedBox(height: 16),
                
                // Enhanced Radar showing presence users
                _buildPresenceRadar(multiState.onlineUsers),
                const SizedBox(height: 20),

                // Matchmaking Status & Controls
                _buildMatchmakingControls(multiState),
                const SizedBox(height: 20),

                // Dynamic panels: Incoming challenges or public rooms
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      if (incomingChallenges.isNotEmpty) ...[
                        _buildSectionHeader('INCOMING DUELS'),
                        const SizedBox(height: 8),
                        ...incomingChallenges.map((r) => _buildIncomingChallengeCard(r)),
                        const SizedBox(height: 16),
                      ],
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: _buildSectionHeader('PUBLIC BATTLES'),
                          ),
                          if (multiState.matchmakingStatus == MatchmakingStatus.idle)
                            SizedBox(
                              width: 130,
                              height: 38,
                              child: GlowButton(
                                height: 38,
                                label: 'CREATE ROOM',
                                icon: Icons.add_rounded,
                                onTap: () async {
                                  final diff = await _showDifficultyPicker(context, 'CREATE CUSTOM ROOM');
                                  if (diff != null) {
                                    try {
                                      await ref.read(multiplayerProvider.notifier).startMatchmaking(diff);
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Failed to create room: $e')),
                                        );
                                      }
                                    }
                                  }
                                },
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (publicRooms.isEmpty)
                        _buildNoRooms()
                      else
                        ...publicRooms.map((r) => _buildRoomCard(r)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'COMBAT HUB',
          style: GoogleFonts.righteous(
            fontSize: 28,
            color: Colors.white,
            shadows: [const Shadow(color: AppColors.cyanGlow, blurRadius: 15)],
          ),
        ),
        Text(
          'CHALLENGE THE WORLD FOR PURITY',
          style: GoogleFonts.outfit(
            fontSize: 11,
            color: AppColors.textSecondary,
            letterSpacing: 1.5,
          ),
        ),
      ],
    ).animate().fadeIn().slideX(begin: -0.05);
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.righteous(
        fontSize: 13,
        color: AppColors.tealAccent,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildPresenceRadar(List<PresenceUser> users) {
    return Container(
      height: 190,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          _RadarSweeper(),
          for (var i = 1; i <= 3; i++)
            Container(
              width: 55.0 * i * 2,
              height: 55.0 * i * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.cyanGlow.withOpacity(math.max(0.0, 0.08 - (i * 0.015))),
                ),
              ),
            ),
          for (var i = 0; i < users.length; i++)
            _UserRadarPip(
              user: users[i],
              delay: (i * 150).ms,
              angle: (i * 2.0 * math.pi / (users.isEmpty ? 1 : users.length)) + 0.4,
              radius: 42.0 + (i % 3 * 16.0),
              onTap: (player) => _showChallengeDialog(context, player),
            ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${users.length}',
                  style: GoogleFonts.righteous(fontSize: 26, color: AppColors.cyanGlow),
                ),
                Text(
                  'PLAYERS ONLINE',
                  style: GoogleFonts.outfit(fontSize: 9, color: AppColors.textSecondary, letterSpacing: 0.8),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().scale(delay: 100.ms, duration: 300.ms);
  }

  Widget _buildMatchmakingControls(MultiplayerState state) {
    if (state.matchmakingStatus == MatchmakingStatus.searching) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.amberAccent.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.amberAccent,
                strokeWidth: 2,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FINDING MATCH...',
                    style: GoogleFonts.righteous(
                      color: Colors.amberAccent,
                      fontSize: 14,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    '${state.searchingCount} player(s) in queue',
                    style: GoogleFonts.outfit(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => ref.read(multiplayerProvider.notifier).stopMatchmaking(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                ),
                child: Text(
                  'CANCEL',
                  style: GoogleFonts.outfit(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ).animate(onPlay: (c) => c.repeat(reverse: true))
       .custom(
         duration: 1.5.seconds,
         builder: (context, val, child) => Container(
           decoration: BoxDecoration(
             borderRadius: BorderRadius.circular(20),
             boxShadow: [
               BoxShadow(
                 color: Colors.amberAccent.withOpacity(0.05 * val),
                 blurRadius: 10 * val,
                 spreadRadius: 1 * val,
               )
             ],
           ),
           child: child,
         ),
       );
    }

    if (state.matchmakingStatus == MatchmakingStatus.matched) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F3E2E), Color(0xFF1B6A4C)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.greenAccent, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.greenAccent.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 2,
            )
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.flash_on_rounded, color: Colors.greenAccent, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MATCH FOUND!',
                    style: GoogleFonts.righteous(
                      color: Colors.white,
                      fontSize: 18,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    'PREPARE FOR BATTLE',
                    style: GoogleFonts.outfit(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().scale(duration: 400.ms, curve: Curves.bounceOut);
    }

    return GlowButton(
      label: 'FIND MATCH',
      icon: Icons.radar_rounded,
      onTap: () async {
        final diff = await _showDifficultyPicker(context, 'FIND MATCH');
        if (diff != null) {
          try {
            await ref.read(multiplayerProvider.notifier).startMatchmaking(diff);
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to start matchmaking: $e')),
              );
            }
          }
        }
      },
    );
  }

  Widget _buildIncomingChallengeCard(Room room) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141F32),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orangeAccent.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.orangeAccent.withOpacity(0.1),
            blurRadius: 8,
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.orangeAccent.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bolt_rounded, color: Colors.orangeAccent, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${room.hostUsername ?? "Player"} (LV ${room.hostLevel})',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'CHALLENGED YOU • ${room.difficulty.toUpperCase()}',
                  style: GoogleFonts.righteous(
                    fontSize: 10,
                    color: _getDifficultyColor(room.difficulty),
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              SizedBox(
                width: 90,
                height: 32,
                child: GlowButton(
                  label: 'ACCEPT',
                  glowColor: Colors.greenAccent,
                  gradientColors: const [Color(0xFF0F3E2E), Colors.greenAccent],
                  onTap: () async {
                    try {
                      await ref.read(multiplayerProvider.notifier).joinRoom(room.id);
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to join duel: $e')),
                        );
                      }
                    }
                  },
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => _declineChallenge(room),
                child: Text(
                  'DECLINE',
                  style: GoogleFonts.outfit(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().slideX(begin: 0.1, duration: 300.ms);
  }

  Widget _buildRoomCard(Room room) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cyanGlow.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.cyanGlow.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.videogame_asset_rounded, color: AppColors.cyanGlow, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${room.hostUsername ?? "Opponent"}',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    children: [
                      TextSpan(text: 'LEVEL ${room.hostLevel} • '),
                      TextSpan(
                        text: room.difficulty.toUpperCase(),
                        style: GoogleFonts.righteous(
                          color: _getDifficultyColor(room.difficulty),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 90,
            height: 36,
            child: GlowButton(
              label: 'BATTLE',
              onTap: () async {
                try {
                  await ref.read(multiplayerProvider.notifier).joinRoom(room.id);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to join room: $e')),
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoRooms() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.radar_rounded, size: 48, color: Colors.white.withOpacity(0.08)),
            const SizedBox(height: 12),
            Text(
              'NO PUBLIC BATTLES DETECTED',
              style: GoogleFonts.righteous(
                fontSize: 12,
                color: AppColors.textMuted,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap FIND MATCH or CREATE ROOM to start',
              style: GoogleFonts.outfit(
                color: AppColors.textMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestOverlay(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      body: aquaBackground(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.deepNavy.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.cyanGlow.withOpacity(0.35), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cyanGlow.withOpacity(0.12),
                      blurRadius: 30,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Glowing Lock Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.cyanGlow.withOpacity(0.08),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.cyanGlow.withOpacity(0.3), width: 1),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.lock_person_rounded,
                          size: 40,
                          color: AppColors.cyanGlow,
                        ),
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true))
                     .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.08, 1.08), duration: 2.seconds, curve: Curves.easeInOut),
                    
                    const SizedBox(height: 28),
                    
                    // Title
                    Text(
                      'AUTHENTICATION REQUIRED',
                      style: GoogleFonts.righteous(
                        fontSize: 20,
                        color: Colors.white,
                        letterSpacing: 1.5,
                        shadows: [
                          const Shadow(color: AppColors.cyanGlow, blurRadius: 12),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Description
                    Text(
                      'Online multiplayer is a premium feature. Register or sign in to your WebSpider Studios account to join the matchmaking queue, challenge global players, and sync your level progress and rewards.',
                      style: GoogleFonts.outfit(
                        fontSize: 13.5,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 36),
                    
                    // Sign In Button
                    GlowButton(
                      label: 'CREATE ACCOUNT / SIGN IN',
                      icon: Icons.login_rounded,
                      onTap: () {
                        context.go('/login');
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Cancel / Back Button
                    TextButton(
                      onPressed: () {
                        context.go('/lobby');
                      },
                      child: Text(
                        'BACK TO CAMPAIGN',
                        style: GoogleFonts.outfit(
                          color: AppColors.textMuted,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _RadarSweeper extends StatefulWidget {
  @override
  State<_RadarSweeper> createState() => _RadarSweeperState();
}

class _RadarSweeperState extends State<_RadarSweeper> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) => Transform.rotate(
        angle: _ctrl.value * 2 * math.pi,
        child: Container(
          width: 320,
          height: 320,
          decoration: BoxDecoration(
            gradient: SweepGradient(
              center: Alignment.center,
              startAngle: 0,
              endAngle: 1,
              colors: [
                AppColors.cyanGlow.withOpacity(0.0),
                AppColors.cyanGlow.withOpacity(0.2),
                AppColors.cyanGlow.withOpacity(0.0),
              ],
              stops: const [0.0, 0.5, 0.6],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserRadarPip extends StatelessWidget {
  final PresenceUser user;
  final Duration delay;
  final double angle;
  final double radius;
  final Function(PresenceUser) onTap;

  const _UserRadarPip({
    required this.user,
    required this.delay,
    required this.angle,
    required this.radius,
    required this.onTap,
  });

  Color _getStatusColor() {
    switch (user.status) {
      case 'searching':
        return Colors.amberAccent;
      case 'in_match':
        return Colors.redAccent;
      default:
        return Colors.greenAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    String label = user.username.toUpperCase();
    if (label == 'GUEST' || label == 'ANONYMOUS' || label.isEmpty) {
      label = 'GUE';
    } else {
      label = label.substring(0, math.min(label.length, 3));
    }

    final statusColor = _getStatusColor();

    return Transform.translate(
      offset: Offset(math.cos(angle) * radius, math.sin(angle) * radius),
      child: GestureDetector(
        onTap: () => onTap(user),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: statusColor, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: statusColor.withOpacity(0.2),
                blurRadius: 6,
              )
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '$label • L${user.level}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 7.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .fadeIn(delay: delay)
          .scale(begin: const Offset(0.9, 0.9), duration: 2.seconds),
    );
  }
}
