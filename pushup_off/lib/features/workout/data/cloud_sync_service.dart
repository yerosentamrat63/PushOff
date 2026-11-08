import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/workout_session_record.dart';
import '../../groups/data/group_repository.dart';

class CloudSyncService {
  FirebaseFirestore? _firestore;
  bool _isFirebaseAvailable = false;
  final GroupRepository _groupRepo;

  CloudSyncService(this._groupRepo) {
    _init();
  }

  void _init() {
    try {
      _firestore = FirebaseFirestore.instance;
      _isFirebaseAvailable = true;
    } catch (_) {
      _isFirebaseAvailable = false;
    }
  }

  /// Verifies anti-cheat constraints before transmitting session telemetry:
  /// Maximum human cadence cap: 90 reps/minute.
  bool verifyAntiCheatCadence(int validReps, int durationSeconds) {
    if (durationSeconds < 5) return false;
    if (validReps < 0 || validReps > 250) return false;
    final repsPerMinute = validReps / (durationSeconds / 60.0);
    return repsPerMinute <= 90.0;
  }

  Future<void> uploadSessionCounts({
    required WorkoutSessionRecord session,
    required String userId,
  }) async {
    // 1. Client-side Anti-Cheat Sanity Check
    if (!verifyAntiCheatCadence(session.validReps, session.durationSeconds)) {
      throw Exception(
        'Anti-Cheat Warning: Workout cadence exceeds the maximum allowable rate of 90 reps/min.',
      );
    }

    // 2. Upload strictly numerical metrics to Firestore (Never video)
    if (_isFirebaseAvailable && _firestore != null) {
      final sessionDoc = _firestore!.collection('sessions').doc(session.id);
      await sessionDoc.set({
        'id': session.id,
        'userId': userId,
        'validReps': session.validReps,
        'rejectedReps': session.rejectedReps,
        'formScore': session.formScore,
        'durationSeconds': session.durationSeconds,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Increment user lifetime valid reps
      final userDoc = _firestore!.collection('users').doc(userId);
      await userDoc.set({
        'totalValidReps': FieldValue.increment(session.validReps),
      }, SetOptions(merge: true));
    }

    // 3. Update active groups & leaderboards
    await _groupRepo.recordReps(
      userId: userId,
      reps: session.validReps,
    );
  }
}

