import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/leaderboard_repository.dart';
import '../domain/leaderboard_entry.dart';
import '../../groups/presentation/groups_controller.dart';
import '../../auth/presentation/auth_controller.dart';

final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  final groupRepo = ref.watch(groupRepositoryProvider);
  return LeaderboardRepository(groupRepo);
});

final selectedLeaderboardPeriodProvider =
    StateProvider<LeaderboardPeriod>((ref) => LeaderboardPeriod.week);

final selectedGroupFilterProvider = StateProvider<String>((ref) => 'all');

final leaderboardEntriesProvider = StreamProvider<List<LeaderboardEntry>>((ref) {
  final repo = ref.watch(leaderboardRepositoryProvider);
  final period = ref.watch(selectedLeaderboardPeriodProvider);
  final groupFilter = ref.watch(selectedGroupFilterProvider);
  final user = ref.watch(currentUserProvider).value;

  return repo.watchLeaderboard(
    period: period,
    groupFilter: groupFilter,
    currentUserId: user?.uid,
  );
});

