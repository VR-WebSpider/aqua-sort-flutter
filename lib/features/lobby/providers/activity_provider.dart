import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActivityState {
  final double purity; // 0.0 to 1.0
  final int streak;

  ActivityState({required this.purity, required this.streak});

  ActivityState copyWith({double? purity, int? streak}) {
    return ActivityState(
      purity: purity ?? this.purity,
      streak: streak ?? this.streak,
    );
  }
}

class ActivityNotifier extends StateNotifier<ActivityState> {
  ActivityNotifier() : super(ActivityState(purity: 0.5, streak: 0));

  void recordWin() {
    state = state.copyWith(
      purity: (state.purity + 0.1).clamp(0.0, 1.0),
      streak: state.streak + 1,
    );
  }

  void recordLoss() {
    state = state.copyWith(
      purity: (state.purity - 0.05).clamp(0.0, 1.0),
      streak: 0,
    );
  }
}

final activityProvider = StateNotifierProvider<ActivityNotifier, ActivityState>((ref) {
  return ActivityNotifier();
});
