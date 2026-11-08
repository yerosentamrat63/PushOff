import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_off/features/workout/data/feedback_service.dart';
import 'package:pushup_off/features/workout/domain/models/completed_set_summary.dart';
import 'package:pushup_off/features/workout/domain/models/pose_frame.dart';
import 'package:pushup_off/features/workout/domain/rep_counter.dart';
import 'package:pushup_off/features/workout/domain/rep_counter_config.dart';
import 'package:pushup_off/features/workout/presentation/controllers/workout_session_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Step 8 Polish: FeedbackService & WakeLock Tests', () {
    late FeedbackService feedbackService;

    setUp(() {
      feedbackService = FeedbackService();
    });

    test('Wake lock activates and deactivates properly', () async {
      expect(feedbackService.isWakeLockActive, isFalse);

      await feedbackService.enableWakeLock();
      expect(feedbackService.isWakeLockActive, isTrue);

      await feedbackService.disableWakeLock();
      expect(feedbackService.isWakeLockActive, isFalse);
    });

    test('Haptic triggers complete safely without throwing in test environment', () async {
      await expectLater(feedbackService.triggerValidRepHaptic(), completes);
      await expectLater(feedbackService.triggerRejectionHaptic(), completes);
      await expectLater(feedbackService.triggerDepthReachedHaptic(), completes);
    });
  });

  group('Step 8 Polish: Workout Edge Cases & Zero Div Protection', () {
    late RepCounter repCounter;

    setUp(() {
      repCounter = RepCounter(config: RepCounterConfig.defaultConfig);
    });

    test('Zero rep workout completes cleanly without division by zero', () {
      final summary = CompletedSetSummary(
        validReps: 0,
        rejectedReps: 0,
        formScore: 100.0,
        secondsDuration: 45,
        rejectedRepsList: const [],
        completedAt: DateTime.now(),
      );

      expect(summary.validReps, equals(0));
      expect(summary.rejectedReps, equals(0));
      expect(summary.formattedDuration, equals('0:45'));
    });

    test('Rapid landmark occlusion pauses tracking and resumes without phantom reps', () {
      final validLandmarks = {
        LandmarkId.leftShoulder: const PosePoint(x: 100, y: 100, confidence: 0.95),
        LandmarkId.leftElbow: const PosePoint(x: 100, y: 150, confidence: 0.95),
        LandmarkId.leftWrist: const PosePoint(x: 100, y: 200, confidence: 0.95),
        LandmarkId.leftHip: const PosePoint(x: 100, y: 300, confidence: 0.95),
        LandmarkId.leftAnkle: const PosePoint(x: 100, y: 400, confidence: 0.95),
      };

      final lowConfidenceLandmarks = {
        LandmarkId.leftShoulder: const PosePoint(x: 100, y: 100, confidence: 0.2),
        LandmarkId.leftElbow: const PosePoint(x: 100, y: 150, confidence: 0.1),
        LandmarkId.leftWrist: const PosePoint(x: 100, y: 200, confidence: 0.2),
        LandmarkId.leftHip: const PosePoint(x: 100, y: 300, confidence: 0.1),
        LandmarkId.leftAnkle: const PosePoint(x: 100, y: 400, confidence: 0.2),
      };

      // 1. Initial good frame
      final out1 = repCounter.processFrame(PoseFrame(
        landmarks: validLandmarks,
        timestamp: DateTime.now(),
      ));
      expect(out1.isTrackingPaused, isFalse);

      // 2. Someone walks in front of camera (low confidence occlusion)
      final out2 = repCounter.processFrame(PoseFrame(
        landmarks: lowConfidenceLandmarks,
        timestamp: DateTime.now().add(const Duration(milliseconds: 100)),
      ));
      expect(out2.isTrackingPaused, isTrue);
      expect(out2.validReps, equals(0));

      // 3. User recovers visibility
      final out3 = repCounter.processFrame(PoseFrame(
        landmarks: validLandmarks,
        timestamp: DateTime.now().add(const Duration(milliseconds: 200)),
      ));
      expect(out3.isTrackingPaused, isFalse);
      expect(out3.validReps, equals(0));
    });

    test('WorkoutSessionState copyWith properly handles showRejectionFlash', () {
      const state = WorkoutSessionState();
      expect(state.showRejectionFlash, isFalse);

      final flashOn = state.copyWith(showRejectionFlash: true);
      expect(flashOn.showRejectionFlash, isTrue);

      final flashOff = flashOn.copyWith(showRejectionFlash: false);
      expect(flashOff.showRejectionFlash, isFalse);
    });
  });
}

