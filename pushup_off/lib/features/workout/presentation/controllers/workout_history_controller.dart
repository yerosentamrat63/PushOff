import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/local_database.dart';
import '../../data/cloud_sync_service.dart';
import '../../data/workout_repository.dart';
import '../../domain/models/completed_set_summary.dart';
import '../../domain/models/daily_progress_data.dart';
import '../../domain/models/profile_stats_data.dart';
import '../../domain/models/workout_session_record.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../groups/presentation/groups_controller.dart';
import '../../../settings/presentation/settings_controller.dart';

final localDatabaseProvider = Provider<LocalDatabase>((ref) {
  final db = LocalDatabase();
  // Fire and forget initialization
  unawaited(db.init());
  return db;
});

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  final db = ref.watch(localDatabaseProvider);
  final repo = WorkoutRepository(db);
  ref.onDispose(repo.dispose);
  return repo;
});

final cloudSyncServiceProvider = Provider<CloudSyncService>((ref) {
  final groupRepo = ref.watch(groupRepositoryProvider);
  return CloudSyncService(groupRepo);
});

/// Stream of database modification signals
final workoutDbChangesProvider = StreamProvider<void>((ref) {
  final repo = ref.watch(workoutRepositoryProvider);
  return repo.changes;
});

/// Live Daily Progress Data driving Home Screen
final todayProgressProvider = FutureProvider<DailyProgressData>((ref) async {
  // Re-fetch when database changes or daily goal setting changes
  ref.watch(workoutDbChangesProvider);
  final dailyGoal = ref.watch(dailyGoalRepsProvider);
  final repo = ref.watch(workoutRepositoryProvider);
  return repo.getTodayProgress(dailyGoal);
});

/// Live Profile Stats driving Profile Screen
final profileStatsProvider = FutureProvider<ProfileStatsData>((ref) async {
  ref.watch(workoutDbChangesProvider);
  final repo = ref.watch(workoutRepositoryProvider);
  return repo.getProfileStats();
});

/// Live Recent Sessions list driving Profile Screen
final recentSessionsProvider = FutureProvider<List<WorkoutSessionRecord>>((ref) async {
  ref.watch(workoutDbChangesProvider);
  final repo = ref.watch(workoutRepositoryProvider);
  return repo.getRecentSessions(limit: 10);
});

/// Controller to trigger saves and resets
class WorkoutHistoryNotifier extends StateNotifier<AsyncValue<void>> {
  final WorkoutRepository _repo;
  final CloudSyncService _cloudSync;
  final Ref _ref;

  WorkoutHistoryNotifier(this._repo, this._cloudSync, this._ref)
      : super(const AsyncValue.data(null));

  Future<void> saveCompletedSet(CompletedSetSummary summary) async {
    state = const AsyncValue.loading();
    try {
      final record = WorkoutSessionRecord.fromCompletedSetSummary(summary);
      await _repo.saveSession(record);

      final user = _ref.read(currentUserProvider).value;
      final uid = user?.uid ?? 'user-yerosen-1';
      unawaited(_cloudSync.uploadSessionCounts(session: record, userId: uid).catchError((_) {}));

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> saveManualRecord(WorkoutSessionRecord record) async {
    state = const AsyncValue.loading();
    try {
      await _repo.saveSession(record);

      final user = _ref.read(currentUserProvider).value;
      final uid = user?.uid ?? 'user-yerosen-1';
      unawaited(_cloudSync.uploadSessionCounts(session: record, userId: uid).catchError((_) {}));

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final workoutHistoryControllerProvider =
    StateNotifierProvider<WorkoutHistoryNotifier, AsyncValue<void>>((ref) {
  final repo = ref.watch(workoutRepositoryProvider);
  final cloudSync = ref.watch(cloudSyncServiceProvider);
  return WorkoutHistoryNotifier(repo, cloudSync, ref);
});

