import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_off/features/workout/domain/angle_calculator.dart';
import 'package:pushup_off/features/workout/domain/models/pose_frame.dart';
import 'package:pushup_off/features/workout/domain/models/rep_counter_output.dart';
import 'package:pushup_off/features/workout/domain/rep_counter.dart';
import 'package:pushup_off/features/workout/domain/rep_counter_config.dart';

/// Helper to generate synthetic PoseFrame with exact elbow and body-line angles.
PoseFrame createSyntheticFrame({
  required double elbowAngleDegrees,
  required double bodyLineAngleDegrees,
  bool hipsSagging = true,
  double confidence = 0.9,
  BodySide side = BodySide.left,
  DateTime? timestamp,
}) {
  // 1. Elbow construction: Vertex at Elbow E(100, 200)
  const ex = 100.0;
  const ey = 200.0;
  // Shoulder S directly above E
  const sx = 100.0;
  const sy = 100.0;

  // Wrist W positioned at elbowAngle relative to vertical line ES
  final radElbow = elbowAngleDegrees * (math.pi / 180.0);
  final wx = ex + 100.0 * math.sin(radElbow);
  final wy = ey - 100.0 * math.cos(radElbow);

  // 2. Body-line construction: Shoulder S(100, 100), Hip H, Ankle A(400, 100)
  // Base line from (100, 100) to (400, 100)
  const ax = 400.0;
  const ay = 100.0;
  const hx = 250.0;

  double hy;
  if ((bodyLineAngleDegrees - 180.0).abs() < 0.1) {
    hy = 100.0;
  } else {
    // Offset hip vertically to generate exact desired body angle
    final deltaRad = (180.0 - bodyLineAngleDegrees) * (math.pi / 180.0);
    final offset = 150.0 * math.tan(deltaRad / 2.0);
    hy = hipsSagging ? 100.0 + offset : 100.0 - offset;
  }

  final landmarks = <LandmarkId, PosePoint>{};

  if (side == BodySide.left) {
    landmarks[LandmarkId.leftShoulder] = PosePoint(x: sx, y: sy, confidence: confidence);
    landmarks[LandmarkId.leftElbow] = PosePoint(x: ex, y: ey, confidence: confidence);
    landmarks[LandmarkId.leftWrist] = PosePoint(x: wx, y: wy, confidence: confidence);
    landmarks[LandmarkId.leftHip] = PosePoint(x: hx, y: hy, confidence: confidence);
    landmarks[LandmarkId.leftAnkle] = PosePoint(x: ax, y: ay, confidence: confidence);
    // Lower right side confidence so left is prominent
    landmarks[LandmarkId.rightShoulder] = const PosePoint(x: 0, y: 0, confidence: 0.2);
    landmarks[LandmarkId.rightElbow] = const PosePoint(x: 0, y: 0, confidence: 0.2);
    landmarks[LandmarkId.rightWrist] = const PosePoint(x: 0, y: 0, confidence: 0.2);
    landmarks[LandmarkId.rightHip] = const PosePoint(x: 0, y: 0, confidence: 0.2);
    landmarks[LandmarkId.rightAnkle] = const PosePoint(x: 0, y: 0, confidence: 0.2);
  } else {
    landmarks[LandmarkId.rightShoulder] = PosePoint(x: sx, y: sy, confidence: confidence);
    landmarks[LandmarkId.rightElbow] = PosePoint(x: ex, y: ey, confidence: confidence);
    landmarks[LandmarkId.rightWrist] = PosePoint(x: wx, y: wy, confidence: confidence);
    landmarks[LandmarkId.rightHip] = PosePoint(x: hx, y: hy, confidence: confidence);
    landmarks[LandmarkId.rightAnkle] = PosePoint(x: ax, y: ay, confidence: confidence);
    landmarks[LandmarkId.leftShoulder] = const PosePoint(x: 0, y: 0, confidence: 0.2);
    landmarks[LandmarkId.leftElbow] = const PosePoint(x: 0, y: 0, confidence: 0.2);
    landmarks[LandmarkId.leftWrist] = const PosePoint(x: 0, y: 0, confidence: 0.2);
    landmarks[LandmarkId.leftHip] = const PosePoint(x: 0, y: 0, confidence: 0.2);
    landmarks[LandmarkId.leftAnkle] = const PosePoint(x: 0, y: 0, confidence: 0.2);
  }

  return PoseFrame(landmarks: landmarks, timestamp: timestamp);
}

void main() {
  group('AngleCalculator Unit Tests', () {
    test('Calculates 90 degree angle correctly', () {
      const a = PosePoint(x: 100, y: 0, confidence: 1.0);
      const b = PosePoint(x: 100, y: 100, confidence: 1.0);
      const c = PosePoint(x: 200, y: 100, confidence: 1.0);

      final angle = AngleCalculator.calculateAngle(a, b, c);
      expect((angle - 90.0).abs() < 0.01, true);
    });

    test('Calculates 180 degree straight line correctly', () {
      const a = PosePoint(x: 0, y: 100, confidence: 1.0);
      const b = PosePoint(x: 100, y: 100, confidence: 1.0);
      const c = PosePoint(x: 200, y: 100, confidence: 1.0);

      final angle = AngleCalculator.calculateAngle(a, b, c);
      expect((angle - 180.0).abs() < 0.01, true);
    });

    test('Detects sagging hips vs piked hips correctly', () {
      const shoulder = PosePoint(x: 100, y: 100, confidence: 1.0);
      const ankle = PosePoint(x: 400, y: 100, confidence: 1.0);

      // Sagging hip (y = 140 is below the line y = 100)
      const saggingHip = PosePoint(x: 250, y: 140, confidence: 1.0);
      expect(
        AngleCalculator.isHipSagging(shoulder: shoulder, hip: saggingHip, ankle: ankle),
        true,
      );

      // Piked hip (y = 60 is above the line y = 100)
      const pikedHip = PosePoint(x: 250, y: 60, confidence: 1.0);
      expect(
        AngleCalculator.isHipSagging(shoulder: shoulder, hip: pikedHip, ankle: ankle),
        false,
      );
    });
  });

  group('MovingAverageFilter Unit Tests', () {
    test('Correctly smoothes sequence and dampens noise', () {
      final filter = MovingAverageFilter(windowSize: 3);

      expect(filter.add(100.0), 100.0);
      expect(filter.add(110.0), 105.0);
      expect(filter.add(120.0), 110.0);
      // Window is full (100, 110, 120), adding 130 drops 100 -> avg (110+120+130)/3 = 120
      expect(filter.add(130.0), 120.0);
    });
  });

  group('RepCounter Engine Unit Tests', () {
    late RepCounter counter;
    // Use windowSize: 1 in tests for direct deterministic angle mapping
    const testConfig = RepCounterConfig(
      movingAverageWindowSize: 1,
      minRepDurationSeconds: 0.4,
      minElbowDepthAngle: 90.0,
      enterDownAngle: 100.0,
      leaveDownAngle: 120.0,
      enterUpAngle: 155.0,
      minBodyLineAngle: 165.0,
    );

    setUp(() {
      counter = RepCounter(config: testConfig);
    });

    test('Valid rep sequence produces 1 valid rep and high form score', () {
      var time = DateTime.now();

      // 1. Initial High Plank at Lockout (165°, 175° body line)
      counter.processFrame(createSyntheticFrame(
        elbowAngleDegrees: 165.0,
        bodyLineAngleDegrees: 175.0,
        timestamp: time,
      ));

      // 2. Descending
      time = time.add(const Duration(milliseconds: 200));
      counter.processFrame(createSyntheticFrame(
        elbowAngleDegrees: 130.0,
        bodyLineAngleDegrees: 175.0,
        timestamp: time,
      ));

      // 3. Reaches Bottom (Elbow 85° <= 90° depth, enters DOWN)
      time = time.add(const Duration(milliseconds: 250));
      counter.processFrame(createSyntheticFrame(
        elbowAngleDegrees: 85.0,
        bodyLineAngleDegrees: 175.0,
        timestamp: time,
      ));

      // 4. Ascending (Leaves DOWN > 120°)
      time = time.add(const Duration(milliseconds: 250));
      counter.processFrame(createSyntheticFrame(
        elbowAngleDegrees: 125.0,
        bodyLineAngleDegrees: 175.0,
        timestamp: time,
      ));

      // 5. Full Lockout at Top (Elbow 160° >= 155°)
      time = time.add(const Duration(milliseconds: 200));
      final output = counter.processFrame(createSyntheticFrame(
        elbowAngleDegrees: 160.0,
        bodyLineAngleDegrees: 175.0,
        timestamp: time,
      ));

      expect(output.validReps, 1);
      expect(output.rejectedReps, 0);
      expect(output.latestRejectionReason, null);
      expect(output.formScore >= 90.0, true);
    });

    test('Half rep (not deep enough) is rejected', () {
      var time = DateTime.now();

      // Top Lockout
      counter.processFrame(createSyntheticFrame(
        elbowAngleDegrees: 165.0,
        bodyLineAngleDegrees: 175.0,
        timestamp: time,
      ));

      // Descend to only 98° (does not reach 90°)
      time = time.add(const Duration(milliseconds: 500));
      counter.processFrame(createSyntheticFrame(
        elbowAngleDegrees: 98.0,
        bodyLineAngleDegrees: 175.0,
        timestamp: time,
      ));

      // Ascend back to Lockout
      time = time.add(const Duration(milliseconds: 500));
      final output = counter.processFrame(createSyntheticFrame(
        elbowAngleDegrees: 160.0,
        bodyLineAngleDegrees: 175.0,
        timestamp: time,
      ));

      expect(output.validReps, 0);
      expect(output.rejectedReps, 1);
      expect(output.latestRejectionReason, RejectionReason.notDeepEnough);
      expect(output.rejectedRepsList.length, 1);
      expect(output.rejectedRepsList.first.reason, RejectionReason.notDeepEnough);
    });

    test('Sagging hips during descent is rejected with hipsSagging', () {
      var time = DateTime.now();

      // 1. Top Lockout
      counter.processFrame(createSyntheticFrame(
        elbowAngleDegrees: 165.0,
        bodyLineAngleDegrees: 175.0,
        timestamp: time,
      ));

      // 2. Descending with hips sagging (body line 154° < 165°)
      time = time.add(const Duration(milliseconds: 200));
      counter.processFrame(createSyntheticFrame(
        elbowAngleDegrees: 130.0,
        bodyLineAngleDegrees: 154.0,
        hipsSagging: true,
        timestamp: time,
      ));

      // 3. Bottom depth
      time = time.add(const Duration(milliseconds: 250));
      counter.processFrame(createSyntheticFrame(
        elbowAngleDegrees: 85.0,
        bodyLineAngleDegrees: 154.0,
        hipsSagging: true,
        timestamp: time,
      ));

      // 4. Ascending
      time = time.add(const Duration(milliseconds: 250));
      counter.processFrame(createSyntheticFrame(
        elbowAngleDegrees: 125.0,
        bodyLineAngleDegrees: 170.0,
        timestamp: time,
      ));

      // 5. Ascend back to Lockout
      time = time.add(const Duration(milliseconds: 200));
      final output = counter.processFrame(createSyntheticFrame(
        elbowAngleDegrees: 160.0,
        bodyLineAngleDegrees: 175.0,
        timestamp: time,
      ));

      expect(output.validReps, 0);
      expect(output.rejectedReps, 1);
      expect(output.latestRejectionReason, RejectionReason.hipsSagging);
    });

    test('Piked hips during rep is rejected with hipsPiked', () {
      var time = DateTime.now();

      // 1. Top Lockout
      counter.processFrame(createSyntheticFrame(
        elbowAngleDegrees: 165.0,
        bodyLineAngleDegrees: 175.0,
        timestamp: time,
      ));

      // 2. Descending with hips piked (body line 152° < 165°)
      time = time.add(const Duration(milliseconds: 200));
      counter.processFrame(createSyntheticFrame(
        elbowAngleDegrees: 130.0,
        bodyLineAngleDegrees: 152.0,
        hipsSagging: false,
        timestamp: time,
      ));

      // 3. Bottom depth
      time = time.add(const Duration(milliseconds: 250));
      counter.processFrame(createSyntheticFrame(
        elbowAngleDegrees: 85.0,
        bodyLineAngleDegrees: 152.0,
        hipsSagging: false,
        timestamp: time,
      ));

      // 4. Ascending
      time = time.add(const Duration(milliseconds: 250));
      counter.processFrame(createSyntheticFrame(
        elbowAngleDegrees: 125.0,
        bodyLineAngleDegrees: 170.0,
        timestamp: time,
      ));

      // 5. Ascend back to Lockout
      time = time.add(const Duration(milliseconds: 200));
      final output = counter.processFrame(createSyntheticFrame(
        elbowAngleDegrees: 160.0,
        bodyLineAngleDegrees: 175.0,
        timestamp: time,
      ));

      expect(output.validReps, 0);
      expect(output.rejectedReps, 1);
      expect(output.latestRejectionReason, RejectionReason.hipsPiked);
    });

    test('Too fast rep (< 0.4s) is rejected', () {
      var time = DateTime.now();

      // Top Lockout
      counter.processFrame(createSyntheticFrame(
        elbowAngleDegrees: 165.0,
        bodyLineAngleDegrees: 175.0,
        timestamp: time,
      ));

      // Descend in only 50ms
      time = time.add(const Duration(milliseconds: 50));
      counter.processFrame(createSyntheticFrame(
        elbowAngleDegrees: 85.0,
        bodyLineAngleDegrees: 175.0,
        timestamp: time,
      ));

      // Ascend in 50ms (total rep took 100ms < 400ms)
      time = time.add(const Duration(milliseconds: 50));
      final output = counter.processFrame(createSyntheticFrame(
        elbowAngleDegrees: 160.0,
        bodyLineAngleDegrees: 175.0,
        timestamp: time,
      ));

      expect(output.validReps, 0);
      expect(output.rejectedReps, 1);
      expect(output.latestRejectionReason, RejectionReason.tooFast);
    });

    test('Rep without full lockout is rejected with noLockout', () {
      var time = DateTime.now();

      // Top Lockout
      counter.processFrame(createSyntheticFrame(
        elbowAngleDegrees: 165.0,
        bodyLineAngleDegrees: 175.0,
        timestamp: time,
      ));

      // Descend
      time = time.add(const Duration(milliseconds: 200));
      counter.processFrame(createSyntheticFrame(
        elbowAngleDegrees: 130.0,
        bodyLineAngleDegrees: 175.0,
        timestamp: time,
      ));

      // Bottom depth
      time = time.add(const Duration(milliseconds: 250));
      counter.processFrame(createSyntheticFrame(
        elbowAngleDegrees: 85.0,
        bodyLineAngleDegrees: 175.0,
        timestamp: time,
      ));

      // Partial ascent, but never reaches the 155° lockout threshold
      time = time.add(const Duration(milliseconds: 250));
      counter.processFrame(createSyntheticFrame(
        elbowAngleDegrees: 125.0,
        bodyLineAngleDegrees: 175.0,
        timestamp: time,
      ));

      // Lower again without locking out
      time = time.add(const Duration(milliseconds: 100));
      final output = counter.processFrame(createSyntheticFrame(
        elbowAngleDegrees: 98.0,
        bodyLineAngleDegrees: 175.0,
        timestamp: time,
      ));

      expect(output.validReps, 0);
      expect(output.rejectedReps, 1);
      expect(output.latestRejectionReason, RejectionReason.noLockout);
    });

    test('Tracking pauses when landmark confidence drops below threshold', () {
      final output = counter.processFrame(createSyntheticFrame(
        elbowAngleDegrees: 165.0,
        bodyLineAngleDegrees: 175.0,
        confidence: 0.3, // Below 0.6 threshold
      ));

      expect(output.isTrackingPaused, true);
      expect(output.validReps, 0);
    });

    test('Side selection automatically picks prominent side with higher confidence', () {
      final output = counter.processFrame(createSyntheticFrame(
        elbowAngleDegrees: 165.0,
        bodyLineAngleDegrees: 175.0,
        side: BodySide.right,
        confidence: 0.85,
      ));

      expect(output.activeSide, BodySide.right);
    });
  });
}

