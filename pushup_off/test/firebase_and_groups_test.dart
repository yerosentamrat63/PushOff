import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_off/features/auth/data/auth_service.dart';
import 'package:pushup_off/features/groups/data/group_repository.dart';
import 'package:pushup_off/features/leaderboard/data/leaderboard_repository.dart';
import 'package:pushup_off/features/leaderboard/domain/leaderboard_entry.dart';
import 'package:pushup_off/features/workout/data/cloud_sync_service.dart';
import 'package:pushup_off/features/workout/domain/models/workout_session_record.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthService Tests', () {
    late AuthService authService;

    setUp(() {
      authService = AuthService();
    });

    tearDown(() {
      authService.dispose();
    });

    test('Initializes with default user profile and correct initials', () async {
      final user = authService.currentUser;
      expect(user, isNotNull);
      expect(user!.displayName, equals('Yerosen Tamrat'));
      expect(user.initials, equals('YT'));
    });

    test('Sign up with email and password creates new profile', () async {
      final newUser = await authService.createUserWithEmailAndPassword(
        'test@pushoff.app',
        'securePass123',
        'Dawit Abebe',
      );
      expect(newUser.email, equals('test@pushoff.app'));
      expect(newUser.displayName, equals('Dawit Abebe'));
      expect(newUser.initials, equals('DA'));
    });

    test('Google sign-in signs in user successfully', () async {
      final user = await authService.signInWithGoogle();
      expect(user.displayName, equals('Yerosen Tamrat'));
      expect(user.email, contains('@'));
    });
  });

  group('GroupRepository Tests', () {
    late GroupRepository groupRepo;

    setUp(() {
      groupRepo = GroupRepository();
    });

    tearDown(() {
      groupRepo.dispose();
    });

    test('Loads initial groups and members matching design', () async {
      final groups = await groupRepo.watchUserGroups('user-yerosen-1').first;
      expect(groups.length, greaterThanOrEqualTo(3));

      final gymRats = groups.firstWhere((g) => g.id == 'gym-rats');
      expect(gymRats.name, equals('Gym Rats'));
      expect(gymRats.inviteCode, equals('GYM-4K9X'));
      expect(gymRats.goal, equals(500));

      final members = await groupRepo.watchGroupMembers('gym-rats').first;
      expect(members.length, equals(5));
      expect(members.first.displayName, equals('Dawit'));
      expect(members.first.rank, equals(1));
    });

    test('Creates new group with unique invite code', () async {
      final newGroup = await groupRepo.createGroup(
        name: 'Thunder Pushers',
        goal: 1000,
        period: 'month',
        userId: 'test-user-1',
        userName: 'Test User',
      );

      expect(newGroup.name, equals('Thunder Pushers'));
      expect(newGroup.goal, equals(1000));
      expect(newGroup.inviteCode, startsWith('THU-'));
      expect(newGroup.memberIds, contains('test-user-1'));
    });

    test('Joins group via invite code', () async {
      final joined = await groupRepo.joinGroupByCode(
        inviteCode: 'GYM-4K9X',
        userId: 'new-athlete-99',
        userName: 'Athlete NinetyNine',
      );

      expect(joined.id, equals('gym-rats'));
      expect(joined.memberIds, contains('new-athlete-99'));
    });

    test('Rejects invalid invite code', () async {
      expect(
        () => groupRepo.joinGroupByCode(
          inviteCode: 'INVALID-CODE',
          userId: 'test-user',
          userName: 'Test',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('LeaderboardRepository Tests', () {
    late GroupRepository groupRepo;
    late LeaderboardRepository leaderboardRepo;

    setUp(() {
      groupRepo = GroupRepository();
      leaderboardRepo = LeaderboardRepository(groupRepo);
    });

    tearDown(() {
      groupRepo.dispose();
    });

    test('Generates leaderboard with Top 3 podium', () async {
      final entries = await leaderboardRepo.watchLeaderboard(
        period: LeaderboardPeriod.week,
        groupFilter: 'all',
      ).first;

      expect(entries.length, greaterThanOrEqualTo(5));
      expect(entries[0].rank, equals(1));
      expect(entries[0].name, equals('Dawit'));
      expect(entries[1].rank, equals(2));
      expect(entries[1].name, equals('Yerosen'));
      expect(entries[2].rank, equals(3));
      expect(entries[2].name, equals('Selam'));
    });
  });

  group('CloudSyncService Anti-Cheat Tests', () {
    late GroupRepository groupRepo;
    late CloudSyncService cloudSync;

    setUp(() {
      groupRepo = GroupRepository();
      cloudSync = CloudSyncService(groupRepo);
    });

    tearDown(() {
      groupRepo.dispose();
    });

    test('Accepts realistic workout cadence', () {
      // 30 push-ups in 60 seconds = 30 reps/min (realistic)
      expect(cloudSync.verifyAntiCheatCadence(30, 60), isTrue);
      // 50 push-ups in 45 seconds = 66.6 reps/min (fast human elite)
      expect(cloudSync.verifyAntiCheatCadence(50, 45), isTrue);
    });

    test('Rejects superhuman bot cadence exceeding 90 reps/min', () {
      // 100 push-ups in 30 seconds = 200 reps/min (impossible human rate)
      expect(cloudSync.verifyAntiCheatCadence(100, 30), isFalse);
      // 50 push-ups in 10 seconds = 300 reps/min
      expect(cloudSync.verifyAntiCheatCadence(50, 10), isFalse);
    });

    test('Rejects duration less than 5 seconds', () {
      expect(cloudSync.verifyAntiCheatCadence(5, 3), isFalse);
    });

    test('Throws exception on upload if cadence fails anti-cheat check', () async {
      final impossibleSession = WorkoutSessionRecord(
        id: 'cheater-set',
        startedAt: DateTime.now().subtract(const Duration(seconds: 10)),
        completedAt: DateTime.now(),
        durationSeconds: 10,
        validReps: 50, // 300 reps/min!
        rejectedReps: 0,
        formScore: 99.0,
      );

      expect(
        () => cloudSync.uploadSessionCounts(session: impossibleSession, userId: 'cheater-uid'),
        throwsA(isA<Exception>()),
      );
    });
  });
}

