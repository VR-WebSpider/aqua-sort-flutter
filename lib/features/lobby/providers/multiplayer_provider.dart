import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aqua_sort/features/auth/providers/auth_provider.dart';
import 'package:aqua_sort/features/lobby/providers/level_provider.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class PresenceUser {
  final String userId;
  final String displayName;
  final String username;
  final int level;
  final String? avatarUrl;
  final String status; // 'idle' | 'searching' | 'in_match'

  const PresenceUser({
    required this.userId,
    required this.displayName,
    required this.username,
    required this.level,
    this.avatarUrl,
    this.status = 'idle',
  });

  factory PresenceUser.fromPayload(Map<String, dynamic> p) => PresenceUser(
        userId: p['user_id'] ?? '',
        displayName: p['display_name'] ?? 'Player',
        username: p['username'] ?? 'anon',
        level: (p['level'] as num?)?.toInt() ?? 1,
        avatarUrl: p['avatar_url'],
        status: p['status'] ?? 'idle',
      );
}

class Room {
  final String id;
  final String hostId;
  final String? guestId;
  final String status; // 'waiting' | 'playing' | 'finished'
  final int seed;
  final String difficulty;
  final String? hostUsername;
  final int hostLevel;
  final String? guestUsername;
  final String? challengedUserId;
  final DateTime? createdAt;

  const Room({
    required this.id,
    required this.hostId,
    this.guestId,
    required this.status,
    required this.seed,
    required this.difficulty,
    this.hostUsername,
    this.hostLevel = 1,
    this.guestUsername,
    this.challengedUserId,
    this.createdAt,
  });

  factory Room.fromJson(Map<String, dynamic> j) => Room(
        id: j['id'],
        hostId: j['host_id'],
        guestId: j['guest_id'],
        status: j['status'],
        seed: j['seed'],
        difficulty: j['difficulty'],
        hostUsername: j['host_username'],
        hostLevel: (j['host_level'] as num?)?.toInt() ?? 1,
        guestUsername: j['guest_username'],
        challengedUserId: j['challenged_user_id'],
        createdAt: j['created_at'] != null
            ? DateTime.tryParse(j['created_at'])
            : null,
      );

  bool get isFull => guestId != null;
  bool get isPublic => challengedUserId == null;
}

// ── Matchmaking status ────────────────────────────────────────────────────────

enum MatchmakingStatus { idle, searching, matched }

// ── State ─────────────────────────────────────────────────────────────────────

class MultiplayerState {
  final List<Room> activeRooms;
  final List<PresenceUser> onlineUsers;
  final bool isLoading;
  final MatchmakingStatus matchmakingStatus;
  final Room? myRoom;
  final String? error;

  const MultiplayerState({
    this.activeRooms = const [],
    this.onlineUsers = const [],
    this.isLoading = false,
    this.matchmakingStatus = MatchmakingStatus.idle,
    this.myRoom,
    this.error,
  });

  MultiplayerState copyWith({
    List<Room>? activeRooms,
    List<PresenceUser>? onlineUsers,
    bool? isLoading,
    MatchmakingStatus? matchmakingStatus,
    Room? myRoom,
    bool clearMyRoom = false,
    String? error,
  }) =>
      MultiplayerState(
        activeRooms: activeRooms ?? this.activeRooms,
        onlineUsers: onlineUsers ?? this.onlineUsers,
        isLoading: isLoading ?? this.isLoading,
        matchmakingStatus: matchmakingStatus ?? this.matchmakingStatus,
        myRoom: clearMyRoom ? null : (myRoom ?? this.myRoom),
        error: error ?? this.error,
      );

  /// Online users excluding myself and those in a match
  List<PresenceUser> get challengeablePlayers =>
      onlineUsers.where((u) => u.status != 'in_match').toList();

  /// How many players are searching for a match
  int get searchingCount =>
      onlineUsers.where((u) => u.status == 'searching').length;
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class MultiplayerNotifier extends StateNotifier<MultiplayerState> {
  final Ref _ref;
  final SupabaseClient _sb = Supabase.instance.client;

  StreamSubscription? _roomsSub;
  StreamSubscription? _myRoomSub;
  RealtimeChannel? _presenceChannel;
  Timer? _matchmakingTimer;
  Timer? _cleanupTimer;

  MultiplayerNotifier(this._ref) : super(const MultiplayerState()) {
    _init();
    _ref.listen(authProvider, (prev, next) {
      if (next.user != null && prev?.user?.id != next.user!.id) {
        _init();
      }
    });
  }

  // ── Init ──────────────────────────────────────────────────────────────────

  void _init() {
    _listenToRooms();
    _setupPresence();
    // Cleanup stale rooms every 5 minutes
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _sb.rpc('cleanup_stale_rooms').then((_) {}).catchError((_) {});
    });
  }

  // ── Room Stream ───────────────────────────────────────────────────────────

  void _listenToRooms() {
    _roomsSub?.cancel();
    _roomsSub = _sb
        .from('rooms')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .listen((data) {
      final myId = _ref.read(authProvider).user?.id;
      final rooms = data
          .map((j) => Room.fromJson(j))
          .where((r) =>
              r.status == 'waiting' &&
              (r.isPublic ||
                  r.challengedUserId == myId ||
                  r.hostId == myId))
          .toList();
      state = state.copyWith(activeRooms: rooms);
    });
  }

  // ── Presence ──────────────────────────────────────────────────────────────

  void _setupPresence() {
    final auth = _ref.read(authProvider);
    if (auth.user == null) return;

    _presenceChannel?.unsubscribe();
    _presenceChannel = _sb.channel(
      'combat_hub_presence',
      opts: const RealtimeChannelConfig(self: true),
    );

    _presenceChannel!
        .onPresenceSync((_) => _syncPresence())
        .onPresenceJoin((_) => _syncPresence())
        .onPresenceLeave((_) => _syncPresence())
        .subscribe((status, [_]) async {
      if (status == RealtimeSubscribeStatus.subscribed) {
        await _trackPresence('idle');
      }
    });
  }

  void _syncPresence() {
    final presenceList = _presenceChannel?.presenceState() ?? [];
    final myId = _ref.read(authProvider).user?.id;
    final users = <PresenceUser>[];
    for (final p in presenceList) {
      for (final presence in p.presences) {
        final user = PresenceUser.fromPayload(presence.payload);
        if (user.userId != myId) users.add(user);
      }
    }
    state = state.copyWith(onlineUsers: users);
  }

  Future<void> _trackPresence(String status) async {
    final auth = _ref.read(authProvider);
    if (auth.user == null) return;
    final progress = _ref.read(levelProvider);
    try {
      await _presenceChannel?.track({
        'user_id': auth.user!.id,
        'display_name': auth.user!.displayName,
        'username': auth.user!.username,
        'level': progress.currentLevel,
        'avatar_url': auth.user!.avatarUrl,
        'status': status,
      });
    } catch (_) {}
  }

  // ── Matchmaking ───────────────────────────────────────────────────────────

  /// Start auto-matchmaking for the given difficulty.
  /// 1. Update presence to 'searching'
  /// 2. Look for an existing waiting room at the same difficulty by a
  ///    searching player (closest level). If found → join it.
  /// 3. If none found after 3s → create a new waiting room and wait.
  Future<void> startMatchmaking(String difficulty) async {
    if (state.matchmakingStatus != MatchmakingStatus.idle) return;
    state = state.copyWith(matchmakingStatus: MatchmakingStatus.searching);
    await _trackPresence('searching');

    // Try to find an existing room
    final joined = await _tryJoinBestRoom(difficulty);
    if (joined) return;

    // No room found → create one and wait
    try {
      final room = await _createRoom(difficulty);
      state = state.copyWith(myRoom: room);
      _watchForMatch(room.id);
    } catch (e) {
      state = state.copyWith(
        matchmakingStatus: MatchmakingStatus.idle,
        error: 'Failed to create room: $e',
      );
      await _trackPresence('idle');
    }
  }

  Future<bool> _tryJoinBestRoom(String difficulty) async {
    final auth = _ref.read(authProvider);
    final progress = _ref.read(levelProvider);
    if (auth.user == null) return false;

    try {
      final data = await _sb
          .from('rooms')
          .select()
          .eq('status', 'waiting')
          .eq('difficulty', difficulty)
          .isFilter('challenged_user_id', null)
          .isFilter('guest_id', null)
          .neq('host_id', auth.user!.id)
          .order('created_at', ascending: true)
          .limit(20);

      if (data.isEmpty) return false;

      // Pick the room whose host level is closest to mine
      final myLevel = progress.currentLevel;
      final rooms = data.map((j) => Room.fromJson(j)).toList();
      rooms.sort((a, b) =>
          (a.hostLevel - myLevel).abs().compareTo((b.hostLevel - myLevel).abs()));
      final best = rooms.first;

      await _joinRoom(best.id);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> stopMatchmaking() async {
    _matchmakingTimer?.cancel();
    _myRoomSub?.cancel();

    // Delete our waiting room if we created one
    final myId = _ref.read(authProvider).user?.id;
    if (myId != null && state.myRoom != null) {
      try {
        await _sb
            .from('rooms')
            .delete()
            .eq('id', state.myRoom!.id)
            .eq('status', 'waiting');
      } catch (_) {}
    }

    state = state.copyWith(
      matchmakingStatus: MatchmakingStatus.idle,
      clearMyRoom: true,
    );
    await _trackPresence('idle');
  }

  // ── Direct Challenge ──────────────────────────────────────────────────────

  Future<Room> challengePlayer(PresenceUser target, String difficulty) async {
    final room = await _createRoom(difficulty, challengedUserId: target.userId);
    state = state.copyWith(myRoom: room);
    _watchForMatch(room.id);
    return room;
  }

  // ── Room CRUD ─────────────────────────────────────────────────────────────

  Future<Room> _createRoom(String difficulty, {String? challengedUserId}) async {
    final auth = _ref.read(authProvider);
    final progress = _ref.read(levelProvider);
    state = state.copyWith(isLoading: true);
    try {
      final res = await _sb.from('rooms').insert({
        'host_id': auth.user!.id,
        'host_username': auth.user!.username,
        'host_level': progress.currentLevel,
        'seed': DateTime.now().millisecondsSinceEpoch % 1000000,
        'difficulty': difficulty,
        'status': 'waiting',
        if (challengedUserId != null) 'challenged_user_id': challengedUserId,
      }).select().single();
      state = state.copyWith(isLoading: false);
      return Room.fromJson(res);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  /// Join a room as guest — returns a Room in 'playing' state.
  Future<Room> _joinRoom(String roomId) async {
    final auth = _ref.read(authProvider);
    state = state.copyWith(isLoading: true);
    try {
      final res = await _sb.from('rooms').update({
        'guest_id': auth.user!.id,
        'guest_username': auth.user!.username,
        'status': 'playing',
      }).eq('id', roomId).select().single();
      state = state.copyWith(
        isLoading: false,
        matchmakingStatus: MatchmakingStatus.matched,
        myRoom: Room.fromJson(res),
      );
      await _trackPresence('in_match');
      return Room.fromJson(res);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  /// Public join (used by manual "BATTLE" button).
  Future<Room> joinRoom(String roomId) => _joinRoom(roomId);

  /// Watch a room for status changes (host waits for guest to join).
  void _watchForMatch(String roomId) {
    _myRoomSub?.cancel();
    _myRoomSub = _sb
        .from('rooms')
        .stream(primaryKey: ['id'])
        .eq('id', roomId)
        .listen((data) {
      if (data.isEmpty) return;
      final room = Room.fromJson(data.first);
      state = state.copyWith(myRoom: room);
      if (room.status == 'playing') {
        state = state.copyWith(matchmakingStatus: MatchmakingStatus.matched);
        _trackPresence('in_match');
        _myRoomSub?.cancel();
      }
    });
  }

  Future<void> updateRoomStatus(String roomId, String status) async {
    try {
      await _sb.from('rooms').update({'status': status}).eq('id', roomId);
    } catch (_) {}
  }

  // ── Dispose ───────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _roomsSub?.cancel();
    _myRoomSub?.cancel();
    _presenceChannel?.unsubscribe();
    _matchmakingTimer?.cancel();
    _cleanupTimer?.cancel();
    super.dispose();
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final multiplayerProvider =
    StateNotifierProvider<MultiplayerNotifier, MultiplayerState>(
  (ref) => MultiplayerNotifier(ref),
);

// End of file
