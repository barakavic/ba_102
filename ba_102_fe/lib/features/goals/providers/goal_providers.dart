import 'package:ba_102_fe/data/api/goal_service.dart';
import 'package:ba_102_fe/data/models/models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final goalServiceProvider = Provider((ref) => GoalService());

final goalsProvider = AsyncNotifierProvider<GoalsNotifier, List<Goal>>(() {
  return GoalsNotifier();
});

class GoalsNotifier extends AsyncNotifier<List<Goal>> {
  @override
  Future<List<Goal>> build() async {
    return ref.read(goalServiceProvider).fetchGoals();
  }

  Future<void> addGoal(Goal goal) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(goalServiceProvider).createGoal(goal);
      return ref.read(goalServiceProvider).fetchGoals();
    });
  }

  Future<void> analyzeGoal(int id) async {
    // We don't set the whole state to loading to avoid flickering the whole list
    // Instead, we just update the specific goal after analysis
    try {
      final updatedGoal = await ref.read(goalServiceProvider).analyzeGoal(id);
      
      final currentGoals = state.value ?? [];
      state = AsyncValue.data(
        currentGoals.map((g) => g.id == id ? updatedGoal : g).toList(),
      );
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(goalServiceProvider).fetchGoals());
  }
}
