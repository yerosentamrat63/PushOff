import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_off/core/storage/local_database.dart';
import 'package:pushup_off/features/workout/data/workout_repository.dart';
import 'package:pushup_off/features/workout/domain/models/rep_counter_output.dart';
import 'package:pushup_off/features/workout/domain/models/workout_session_record.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalDatabase database;
  late WorkoutRepository repository;

  setUp(() async {
    database = LocalDatabase();
    await database.init();
    repository = WorkoutRepository(database);
  });

  tearDown(() {
    repository.dispose();
  });

  test('LocalDatabase initializes with initial mock seed data', () async {
    final sessions = await database.getAllSessions();
    expect(sessions.isNotEmpty, isTrue);

    // Initial seed contains today's 3 sessions (24 + 22 + 18 = 64 valid reps)
    final todayProgress = await repository.getTodayProgress(100);
    expect(todayProgress.todayValidReps, equals(64));
    expect(todayProgress.streakDays, equals(7));
    expect(todayProgress.progressPercent, closeTo(0.64, 0.01));
    expect(todayProgress.isGoalMet, isFalse);
    expect(todayProgress.remainingReps, equals(36));
  });

  test('saveSession persists new set and updates today count', () async {
    final now = DateTime.now();
    final newSession = WorkoutSessionRecord(
      id: 'test-new-set-1',
      startedAt: now.add(const Duration(minutes: 4)),
      completedAt: now.add(const Duration(minutes: 5)),
      durationSeconds: 45,
      validReps: 16,
      rejectedReps: 2,
      formScore: 93.0,
      rejectedRepsList: const [
        RejectedRepDetail(
          repNumber: 5,
          reason: RejectionReason.notDeepEnough,
          detail: 'Elbow 95°',
        ),
      ],
    );

    await repository.saveSession(newSession);

    // Today reps should increase by 16 (64 + 16 = 80)
    final progress = await repository.getTodayProgress(100);
    expect(progress.todayValidReps, equals(80));
    expect(progress.remainingReps, equals(20));

    // Recent sessions should have new session at index 0
    final recent = await repository.getRecentSessions(limit: 5);
    expect(recent.first.id, equals('test-new-set-1'));
    expect(recent.first.validReps, equals(16));
  });

  test('Profile stats calculates total lifetime reps, best set and avg form', () async {
    final stats = await repository.getProfileStats();
    expect(stats.totalValidReps, greaterThanOrEqualTo(1248));
    expect(stats.bestSetReps, greaterThanOrEqualTo(31));
    expect(stats.averageFormScore, greaterThan(80.0));
    expect(stats.last7Days.length, equals(7));
  });

  test('Goal is reached when reps exceed daily target', () async {
    final now = DateTime.now();
    final bigSession = WorkoutSessionRecord(
      id: 'test-goal-crush',
      startedAt: now.subtract(const Duration(minutes: 2)),
      completedAt: now,
      durationSeconds: 120,
      validReps: 50,
      rejectedReps: 0,
      formScore: 98.0,
    );

    await repository.saveSession(bigSession);

    final progress = await repository.getTodayProgress(100);
    expect(progress.todayValidReps, greaterThanOrEqualTo(100));
    expect(progress.isGoalMet, isTrue);
    expect(progress.remainingReps, equals(0));
    expect(progress.progressPercent, equals(1.0));
  });
}

