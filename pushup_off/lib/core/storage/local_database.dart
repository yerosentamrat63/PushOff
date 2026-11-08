import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../../features/workout/domain/models/rep_counter_output.dart';
import '../../features/workout/domain/models/workout_session_record.dart';

class LocalDatabase {
  static const String _dbName = 'pushup_off.db';
  static const int _dbVersion = 1;

  Database? _db;
  Future<void>? _initFuture;

  // In-memory fallback if sqflite native binding is unavailable
  final List<WorkoutSessionRecord> _memorySessions = [];

  /// Initializes the database exactly once. Concurrent callers await the same
  /// future, so queries cannot run before the seed data is ready.
  Future<void> init() {
    return _initFuture ??= _initialize();
  }

  Future<void> _initialize() async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = p.join(databasesPath, _dbName);

      _db = await openDatabase(
        path,
        version: _dbVersion,
        onCreate: _onCreate,
      );
    } catch (_) {
      // In-memory fallback for environments without SQLite platform binaries
    }

    // Check if initial seed is needed
    final count = await getSessionCount();
    if (count == 0) {
      await _seedInitialData();
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE workout_sessions (
        id TEXT PRIMARY KEY,
        started_at TEXT NOT NULL,
        completed_at TEXT NOT NULL,
        duration_seconds INTEGER NOT NULL,
        valid_reps INTEGER NOT NULL,
        rejected_reps INTEGER NOT NULL,
        form_score REAL NOT NULL,
        average_elbow_angle REAL,
        average_body_line_angle REAL,
        prominent_side TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE rejected_reps (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT NOT NULL,
        rep_number INTEGER NOT NULL,
        reason TEXT NOT NULL,
        detail TEXT NOT NULL,
        timestamp TEXT,
        FOREIGN KEY (session_id) REFERENCES workout_sessions (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_sessions_completed_at ON workout_sessions(completed_at)
    ''');
  }

  Future<int> getSessionCount() async {
    if (_db != null) {
      try {
        final result = await _db!
            .rawQuery('SELECT COUNT(*) as count FROM workout_sessions');
        return Sqflite.firstIntValue(result) ?? 0;
      } catch (_) {
        return _memorySessions.length;
      }
    }
    return _memorySessions.length;
  }

  Future<void> insertSession(WorkoutSessionRecord session) async {
    if (_db != null) {
      try {
        await _db!.transaction((txn) async {
          await txn.insert(
            'workout_sessions',
            session.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          for (final rej in session.rejectedRepsList) {
            await txn.insert('rejected_reps', {
              'session_id': session.id,
              'rep_number': rej.repNumber,
              'reason': rej.reason.name,
              'detail': rej.detail,
              'timestamp': rej.timestamp?.toIso8601String(),
            });
          }
        });
        return;
      } catch (_) {
        // Fall back to memory storage on DB transaction error
      }
    }

    _memorySessions.removeWhere((s) => s.id == session.id);
    _memorySessions.insert(0, session);
  }

  Future<List<WorkoutSessionRecord>> getAllSessions() async {
    if (_db != null) {
      try {
        final rows = await _db!.query(
          'workout_sessions',
          orderBy: 'completed_at DESC',
        );

        final List<WorkoutSessionRecord> sessions = [];
        for (final row in rows) {
          final id = row['id'] as String;
          final rejRows = await _db!.query(
            'rejected_reps',
            where: 'session_id = ?',
            whereArgs: [id],
            orderBy: 'rep_number ASC',
          );

          final rejections = rejRows.map((r) {
            final reasonName = r['reason'] as String;
            final reason = RejectionReason.values.firstWhere(
              (e) => e.name == reasonName,
              orElse: () => RejectionReason.none,
            );
            return RejectedRepDetail(
              repNumber: (r['rep_number'] as num).toInt(),
              reason: reason,
              detail: r['detail'] as String,
              timestamp: r['timestamp'] != null
                  ? DateTime.tryParse(r['timestamp'] as String)
                  : null,
            );
          }).toList();

          sessions
              .add(WorkoutSessionRecord.fromMap(row, rejections: rejections));
        }
        return sessions;
      } catch (_) {
        // Fall back to in-memory list
      }
    }

    _memorySessions.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return List.unmodifiable(_memorySessions);
  }

  Future<List<WorkoutSessionRecord>> getRecentSessions(int limit) async {
    final all = await getAllSessions();
    if (all.length <= limit) return all;
    return all.sublist(0, limit);
  }

  Future<void> clearAll() async {
    if (_db != null) {
      try {
        await _db!.delete('rejected_reps');
        await _db!.delete('workout_sessions');
      } catch (_) {}
    }
    _memorySessions.clear();
  }

  /// Seeds initial historical workout sets matching the app design mocks
  /// (64 reps today across 3 sets, 7-day streak, 1,248 total lifetime reps, 31 best set)
  Future<void> _seedInitialData() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    // Keep seeded "today" sessions in the past so they never sort above a set
    // the user has just finished.
    DateTime todayTime(Duration ago, int fallbackSeconds) {
      final candidate = now.subtract(ago);
      return candidate.isAfter(startOfDay)
          ? candidate
          : startOfDay.add(Duration(seconds: fallbackSeconds));
    }

    final today1Completed = todayTime(const Duration(hours: 3), 1);
    final today2Completed = todayTime(const Duration(hours: 1), 2);
    final today3Completed = todayTime(const Duration(minutes: 5), 3);

    // 3 sessions today totaling 64 reps (matching Home design hero card)
    final todaySession1 = WorkoutSessionRecord(
      id: 'seed-today-1',
      startedAt:
          today1Completed.subtract(const Duration(minutes: 1, seconds: 15)),
      completedAt: today1Completed,
      durationSeconds: 75,
      validReps: 24,
      rejectedReps: 2,
      formScore: 92.0,
      averageElbowAngle: 84.0,
      averageBodyLineAngle: 168.0,
      prominentSide: 'right',
      rejectedRepsList: const [
        RejectedRepDetail(
          repNumber: 12,
          reason: RejectionReason.notDeepEnough,
          detail: 'Elbow 98°',
        ),
        RejectedRepDetail(
          repNumber: 22,
          reason: RejectionReason.noLockout,
          detail: 'Elbow 151°',
        ),
      ],
    );

    final todaySession2 = WorkoutSessionRecord(
      id: 'seed-today-2',
      startedAt:
          today2Completed.subtract(const Duration(minutes: 1, seconds: 20)),
      completedAt: today2Completed,
      durationSeconds: 80,
      validReps: 22,
      rejectedReps: 1,
      formScore: 94.0,
      averageElbowAngle: 82.0,
      averageBodyLineAngle: 171.0,
      prominentSide: 'right',
      rejectedRepsList: const [
        RejectedRepDetail(
          repNumber: 15,
          reason: RejectionReason.hipsSagging,
          detail: 'Body 160°',
        ),
      ],
    );

    final todaySession3 = WorkoutSessionRecord(
      id: 'seed-today-3',
      startedAt:
          today3Completed.subtract(const Duration(minutes: 1, seconds: 4)),
      completedAt: today3Completed,
      durationSeconds: 64,
      validReps: 18,
      rejectedReps: 3,
      formScore: 88.0,
      averageElbowAngle: 85.0,
      averageBodyLineAngle: 167.0,
      prominentSide: 'right',
      rejectedRepsList: const [
        RejectedRepDetail(
          repNumber: 7,
          reason: RejectionReason.notDeepEnough,
          detail: 'Elbow 118°',
        ),
        RejectedRepDetail(
          repNumber: 13,
          reason: RejectionReason.hipsSagging,
          detail: 'Body 158°',
        ),
        RejectedRepDetail(
          repNumber: 19,
          reason: RejectionReason.noLockout,
          detail: 'Elbow 151°',
        ),
      ],
    );

    // Prior days to establish the 7-day streak & 7-day chart
    final historySessions = <WorkoutSessionRecord>[
      // Yesterday (Day -1): 31 reps (Best set)
      WorkoutSessionRecord(
        id: 'seed-hist-1',
        startedAt: now.subtract(const Duration(days: 1, hours: 2)),
        completedAt:
            now.subtract(const Duration(days: 1, hours: 1, minutes: 58)),
        durationSeconds: 120,
        validReps: 31,
        rejectedReps: 2,
        formScore: 90.0,
      ),
      // Day -2: 45 reps (across 2 sets)
      WorkoutSessionRecord(
        id: 'seed-hist-2a',
        startedAt: now.subtract(const Duration(days: 2, hours: 5)),
        completedAt:
            now.subtract(const Duration(days: 2, hours: 4, minutes: 58)),
        durationSeconds: 90,
        validReps: 25,
        rejectedReps: 1,
        formScore: 89.0,
      ),
      WorkoutSessionRecord(
        id: 'seed-hist-2b',
        startedAt: now.subtract(const Duration(days: 2, hours: 2)),
        completedAt:
            now.subtract(const Duration(days: 2, hours: 1, minutes: 58)),
        durationSeconds: 85,
        validReps: 20,
        rejectedReps: 2,
        formScore: 87.0,
      ),
      // Day -3: 50 reps
      WorkoutSessionRecord(
        id: 'seed-hist-3',
        startedAt: now.subtract(const Duration(days: 3, hours: 3)),
        completedAt:
            now.subtract(const Duration(days: 3, hours: 2, minutes: 58)),
        durationSeconds: 110,
        validReps: 28,
        rejectedReps: 1,
        formScore: 91.0,
      ),
      // Day -4: 40 reps
      WorkoutSessionRecord(
        id: 'seed-hist-4',
        startedAt: now.subtract(const Duration(days: 4, hours: 4)),
        completedAt:
            now.subtract(const Duration(days: 4, hours: 3, minutes: 58)),
        durationSeconds: 95,
        validReps: 24,
        rejectedReps: 3,
        formScore: 86.0,
      ),
      // Day -5: 60 reps
      WorkoutSessionRecord(
        id: 'seed-hist-5',
        startedAt: now.subtract(const Duration(days: 5, hours: 3)),
        completedAt:
            now.subtract(const Duration(days: 5, hours: 2, minutes: 58)),
        durationSeconds: 105,
        validReps: 30,
        rejectedReps: 2,
        formScore: 90.0,
      ),
      // Day -6: 35 reps (completes 7-day streak)
      WorkoutSessionRecord(
        id: 'seed-hist-6',
        startedAt: now.subtract(const Duration(days: 6, hours: 4)),
        completedAt:
            now.subtract(const Duration(days: 6, hours: 3, minutes: 58)),
        durationSeconds: 88,
        validReps: 26,
        rejectedReps: 2,
        formScore: 88.0,
      ),
    ];

    await insertSession(todaySession1);
    await insertSession(todaySession2);
    await insertSession(todaySession3);
    for (final s in historySessions) {
      await insertSession(s);
    }
  }
}
