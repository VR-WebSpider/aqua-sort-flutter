import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/score_entry.dart';
import 'package:aqua_sort/features/auth/providers/auth_provider.dart';
import 'package:aqua_sort/core/services/game_services.dart';

// Live Stream of all scores, limited to top 100
final leaderboardStreamProvider = StreamProvider<List<ScoreEntry>>((ref) {
  final supabase = Supabase.instance.client;
  
  // We use the postgres stream for real-time updates
  return supabase
      .from('scores')
      .stream(primaryKey: ['id'])
      .order('moves', ascending: true)
      .limit(100)
      .map((data) => data.map((json) => ScoreEntry.fromJson(json)).toList());
});

class LeaderboardNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  final SupabaseClient _supabase = Supabase.instance.client;

  LeaderboardNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<void> recordScore({
    required int moves,
    required int seconds,
    required String difficulty,
  }) async {
    state = const AsyncValue.loading();
    
    final authState = ref.read(authProvider);
    final userId = authState.user?.id == 'guest' ? null : authState.user?.id;
    final username = authState.user?.displayName ?? 'Guest Sorter';

    try {
      // 1. Submit to Supabase
      await _supabase.from('scores').insert({
        if (userId != null) 'user_id': userId,
        'username': username,
        'moves': moves,
        'seconds': seconds,
        'difficulty': difficulty,
      });

      // 2. Submit to Play Games Services (Track B)
      // Leaderboard IDs should be swapped with the real ones from Play Console
      ref.read(gameServicesProvider).submitScore(
        score: moves, 
        androidLeaderboardID: 'REPLACE_WITH_YOUR_LEADERBOARD_ID',
      );

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final leaderboardNotifierProvider = StateNotifierProvider<LeaderboardNotifier, AsyncValue<void>>((ref) {
  return LeaderboardNotifier(ref);
});

// Legacy shim to keep current UI working without major refactors immediately
final leaderboardProvider = Provider<List<ScoreEntry>>((ref) {
  final stream = ref.watch(leaderboardStreamProvider);
  return stream.when(
    data: (scores) => scores,
    loading: () => [],
    error: (_, __) => [],
  );
});
