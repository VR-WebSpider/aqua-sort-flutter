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
import 'dart:math' as math;

class MultiplayerLobbyScreen extends ConsumerStatefulWidget {
  const MultiplayerLobbyScreen({super.key});

  @override
  ConsumerState<MultiplayerLobbyScreen> createState() =>
      _MultiplayerLobbyState();
}

class _MultiplayerLobbyState extends ConsumerState<MultiplayerLobbyScreen> {
  @override
  Widget build(BuildContext context) {
    debugPrint('MULTI_LOBBY: Building...');
    final multiState = ref.watch(multiplayerProvider);
    final auth = ref.watch(authProvider);
    
    debugPrint('MULTI_LOBBY: auth.isLoading=${auth.isLoading}, multiState.isLoading=${multiState.isLoading}');
    debugPrint('MULTI_LOBBY: roomsCount=${multiState.activeRooms.length}, usersCount=${multiState.onlineUsers.length}');

    if (auth.isLoading || multiState.isLoading) {
       debugPrint('MULTI_LOBBY: Showing Loading Spinner');
       return Scaffold(
         backgroundColor: AppColors.deepNavy,
         body: Center(child: CircularProgressIndicator(color: AppColors.cyanGlow)),
       );
    }

    return Scaffold(
      backgroundColor: AppColors.deepNavy, // never black
      body: aquaBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AquaHeader(onBack: () => context.go('/lobby')),
                const SizedBox(height: 16),
                _buildHeader(),
                const SizedBox(height: 24),
                _buildPresenceRadar(multiState.onlineUsers),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ACTIVE CHALLENGES',
                      style: GoogleFonts.righteous(
                          fontSize: 14,
                          color: AppColors.tealAccent,
                          letterSpacing: 2),
                    ),
                    SizedBox(
                      width: 160,
                      child: GlowButton(
                        label: 'CREATE ROOM',
                        icon: Icons.add_rounded,
                        onTap: () => _createRoom(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: multiState.activeRooms.isEmpty
                      ? _buildNoRooms()
                      : ListView.builder(
                          itemCount: multiState.activeRooms.length,
                          itemBuilder: (context, i) =>
                              _buildRoomCard(multiState.activeRooms[i]),
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
            fontSize: 32,
            color: Colors.white,
            shadows: [const Shadow(color: AppColors.cyanGlow, blurRadius: 20)],
          ),
        ),
        Text(
          'CHALLENGE THE WORLD FOR PURITY',
          style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppColors.textSecondary,
              letterSpacing: 1.5),
        ),
      ],
    ).animate().fadeIn().slideX(begin: -0.1);
  }

  Widget _buildPresenceRadar(List<Map<String, dynamic>> users) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          _RadarSweeper(),
          for (var i = 1; i <= 3; i++)
            Container(
              width: 50.0 * i * 2,
              height: 50.0 * i * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.cyanGlow
                      .withOpacity(math.max(0.0, 0.1 - (i * 0.02))),
                ),
              ),
            ),
          for (var i = 0; i < users.length; i++)
            _UserPip(
              name: users[i]['display_name'] ?? 'Unknown',
              delay: (i * 200).ms,
              angle: (i * 2.4) + 0.5,
              radius: 40.0 + (i % 2 * 20.0),
            ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${users.length}',
                  style: GoogleFonts.righteous(
                      fontSize: 24, color: AppColors.cyanGlow),
                ),
                Text(
                  'ONLINE',
                  style: GoogleFonts.outfit(
                      fontSize: 10, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().scale(delay: 200.ms);
  }

  Widget _buildRoomCard(Room room) {
    final shortId = room.hostId.length >= 8
        ? room.hostId.substring(0, 8)
        : room.hostId;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.deepNavy,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cyanGlow.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: AppColors.cyanGlow.withOpacity(0.1), blurRadius: 10)
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
                color: Colors.white10, shape: BoxShape.circle),
            child: const Icon(Icons.person_outline, color: AppColors.cyanGlow),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Challenge from: $shortId',
                  style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  'MODE: ${room.difficulty.toUpperCase()}',
                  style: GoogleFonts.outfit(
                      fontSize: 11, color: AppColors.tealAccent),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 100,
            child: GlowButton(
              label: 'BATTLE',
              onTap: () => _joinMatch(context, room),
            ),
          ),
        ],
      ).animate().fadeIn().slideY(begin: 0.1),
    );
  }

  Widget _buildNoRooms() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.radar_rounded,
              size: 64, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 16),
          Text('Scanning for signals...',
              style: GoogleFonts.outfit(color: AppColors.textMuted)),
          const SizedBox(height: 8),
          Text('Be the first to create a challenge!',
              style:
                  GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 11)),
        ],
      ),
    );
  }

  Future<void> _createRoom(BuildContext context) async {
    try {
      final room =
          await ref.read(multiplayerProvider.notifier).createRoom('medium');
      if (mounted) {
        ref.read(gameArgsProvider.notifier).state = GameArgs(
          difficulty: Difficulty.medium,
          playerCount: 2,
          isOnline: true,
          roomId: room.id,
          seed: room.seed,
        );
        context.go('/game');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _joinMatch(BuildContext context, Room room) async {
    try {
      await ref.read(multiplayerProvider.notifier).joinRoom(room.id);
      if (mounted) {
        ref.read(gameArgsProvider.notifier).state = GameArgs(
          difficulty: Difficulty.medium,
          playerCount: 2,
          isOnline: true,
          roomId: room.id,
          seed: room.seed,
        );
        context.go('/game');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _RadarSweeper extends StatefulWidget {
  @override
  State<_RadarSweeper> createState() => _RadarSweeperState();
}

class _RadarSweeperState extends State<_RadarSweeper>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..repeat();
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
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            gradient: SweepGradient(
              center: Alignment.center,
              startAngle: 0,
              endAngle: 1,
              colors: [
                AppColors.cyanGlow.withOpacity(0.0),
                AppColors.cyanGlow.withOpacity(0.3),
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

class _UserPip extends StatelessWidget {
  final String name;
  final Duration delay;
  final double angle;
  final double radius;

  const _UserPip({
    required this.name,
    required this.delay,
    required this.angle,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    String label = name.toUpperCase();
    if (label == 'GUEST' || label == 'ANONYMOUS' || label.isEmpty) {
      label = 'GUE';
    } else {
      label = label.substring(0, math.min(label.length, 3));
    }

    return Transform.translate(
      offset: Offset(math.cos(angle) * radius, math.sin(angle) * radius),
      child: GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Challenging $name... Click CREATE ROOM to start a public match!'),
              backgroundColor: AppColors.midTeal,
              duration: const Duration(seconds: 2),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.cyanGlow.withOpacity(0.4),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.cyanGlow, width: 0.5),
          ),
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold)),
        ),
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .fadeIn(delay: delay)
          .scale(begin: const Offset(0.8, 0.8), duration: 2.seconds),
    );
  }
}
