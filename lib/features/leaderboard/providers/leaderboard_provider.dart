import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/score_entry.dart';
import 'package:aqua_sort/features/auth/providers/auth_provider.dart';
import 'package:aqua_sort/core/services/game_services.dart';

// Live Stream of all scores, limited to top 100 from Cloud Firestore
final leaderboardStreamProvider = StreamProvider<List<ScoreEntry>>((ref) {
  return FirebaseFirestore.instance
      .collection('scores')
      .orderBy('moves', descending: false)
      .limit(100)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return ScoreEntry.fromJson(data);
          }).toList());
});

class LeaderboardNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

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
      // 1. Submit to Cloud Firestore
      await FirebaseFirestore.instance.collection('scores').add({
        if (userId != null) 'user_id': userId,
        'username': username,
        'moves': moves,
        'seconds': seconds,
        'difficulty': difficulty,
        'created_at': FieldValue.serverTimestamp(),
      });

      // 2. Submit to Play Games Services (Track B)
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
