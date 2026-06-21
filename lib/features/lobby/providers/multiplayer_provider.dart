import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aqua_sort/features/auth/providers/auth_provider.dart';

class Room {
  final String id;
  final String hostId;
  final String? guestId;
  final String status;
  final int seed;
  final String difficulty;

  Room({
    required this.id,
    required this.hostId,
    this.guestId,
    required this.status,
    required this.seed,
    required this.difficulty,
  });

  factory Room.fromJson(Map<String, dynamic> json) => Room(
    id: json['id'],
    hostId: json['host_id'],
    guestId: json['guest_id'],
    status: json['status'],
    seed: json['seed'],
    difficulty: json['difficulty'],
  );
}

class MultiplayerState {
  final List<Room> activeRooms;
  final List<Map<String, dynamic>> onlineUsers;
  final bool isLoading;

  const MultiplayerState({
    this.activeRooms = const [],
    this.onlineUsers = const [],
    this.isLoading = false,
  });

  MultiplayerState copyWith({
    List<Room>? activeRooms,
    List<Map<String, dynamic>>? onlineUsers,
    bool? isLoading,
  }) {
    return MultiplayerState(
      activeRooms: activeRooms ?? this.activeRooms,
      onlineUsers: onlineUsers ?? this.onlineUsers,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class MultiplayerNotifier extends StateNotifier<MultiplayerState> {
  final Ref ref;
  final SupabaseClient _supabase = Supabase.instance.client;
  StreamSubscription? _roomsSub;
  RealtimeChannel? _presenceChannel;

  MultiplayerNotifier(this.ref) : super(const MultiplayerState()) {
    _init();
    // Re-init if auth state changes (e.g. from unauthenticated to guest/auth)
    ref.listen(authProvider, (prev, next) {
      if (next.user != null && prev?.user?.id != next.user!.id) {
        _init();
      }
    });
  }

  void _init() {
    try {
      _listenToRooms();
      _setupPresence();
    } catch (_) {
      // Non-fatal — screen will show empty rooms list
    }
  }

  void _listenToRooms() {
    // Note: .eq() is not chainable on stream() — filter client-side
    _roomsSub = _supabase
        .from('rooms')
        .stream(primaryKey: ['id'])
        .listen((data) {
      final waitingRooms = data
          .where((json) => json['status'] == 'waiting')
          .map((json) => Room.fromJson(json))
          .toList();
      state = state.copyWith(activeRooms: waitingRooms);
    });
  }

  void _setupPresence() {
    final auth = ref.read(authProvider);
    if (auth.user == null) return;

    _presenceChannel = _supabase.channel('lobby_presence', opts: const RealtimeChannelConfig(self: true));
    
    _presenceChannel!.onPresenceSync((payload) {
      final presenceList = _presenceChannel!.presenceState();
      final users = <Map<String, dynamic>>[];
      
      for (final p in presenceList) {
        if (p.presences.isNotEmpty) {
           users.add(Map<String, dynamic>.from(p.presences.first.payload));
        }
      }
      
      state = state.copyWith(onlineUsers: users);
    }).subscribe((status, [error]) async {
      if (status == RealtimeSubscribeStatus.subscribed) {
        await _presenceChannel!.track({
          'user_id': auth.user!.id,
          'display_name': auth.user!.displayName,
          'avatar_url': auth.user!.avatarUrl,
        });
      }
    });
  }

  Future<Room> createRoom(String difficulty) async {
    state = state.copyWith(isLoading: true);
    final auth = ref.read(authProvider);
    final seed = DateTime.now().millisecondsSinceEpoch;

    try {
      final res = await _supabase.from('rooms').insert({
        'host_id': auth.user!.id,
        'seed': seed,
        'difficulty': difficulty,
        'status': 'waiting',
      }).select().single();

      state = state.copyWith(isLoading: false);
      return Room.fromJson(res);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> joinRoom(String roomId) async {
    state = state.copyWith(isLoading: true);
    final auth = ref.read(authProvider);

    try {
      await _supabase.from('rooms').update({
        'guest_id': auth.user!.id,
        'status': 'playing',
      }).eq('id', roomId);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> updateRoomStatus(String roomId, String status) async {
    try {
      await _supabase.from('rooms').update({
        'status': status,
      }).eq('id', roomId);
    } catch (_) {}
  }

  @override
  void dispose() {
    _roomsSub?.cancel();
    _presenceChannel?.unsubscribe();
    super.dispose();
  }
}

final multiplayerProvider = StateNotifierProvider<MultiplayerNotifier, MultiplayerState>((ref) {
  return MultiplayerNotifier(ref);
});
