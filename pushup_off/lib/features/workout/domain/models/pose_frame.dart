/// Pure Dart representation of a 2D/3D landmark point.
/// No Flutter imports.
class PosePoint {
  final double x;
  final double y;
  final double z;
  final double confidence;

  const PosePoint({
    required this.x,
    required this.y,
    this.z = 0.0,
    required this.confidence,
  });

  static const PosePoint zero = PosePoint(x: 0, y: 0, confidence: 0);

  @override
  String toString() => 'PosePoint($x, $y, conf: $confidence)';
}

/// Standard 33 body landmark indices matching ML Kit / MediaPipe pose topology.
enum LandmarkId {
  nose, // 0
  leftEyeInner, // 1
  leftEye, // 2
  leftEyeOuter, // 3
  rightEyeInner, // 4
  rightEye, // 5
  rightEyeOuter, // 6
  leftEar, // 7
  rightEar, // 8
  mouthLeft, // 9
  mouthRight, // 10
  leftShoulder, // 11
  rightShoulder, // 12
  leftElbow, // 13
  rightElbow, // 14
  leftWrist, // 15
  rightWrist, // 16
  leftPinky, // 17
  rightPinky, // 18
  leftIndex, // 19
  rightIndex, // 20
  leftThumb, // 21
  rightThumb, // 22
  leftHip, // 23
  rightHip, // 24
  leftKnee, // 25
  rightKnee, // 26
  leftAnkle, // 27
  rightAnkle, // 28
  leftHeel, // 29
  rightHeel, // 30
  leftFootIndex, // 31
  rightFootIndex, // 32
}

enum BodySide { left, right }

/// Represents a single frame of pose detection data with a timestamp.
class PoseFrame {
  final Map<LandmarkId, PosePoint> landmarks;
  final DateTime timestamp;

  PoseFrame({
    required this.landmarks,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  PosePoint? get(LandmarkId id) => landmarks[id];

  /// Calculates average confidence for the left key pushup joints:
  /// (shoulder, elbow, wrist, hip, ankle).
  double get leftConfidence {
    final s = landmarks[LandmarkId.leftShoulder]?.confidence ?? 0;
    final e = landmarks[LandmarkId.leftElbow]?.confidence ?? 0;
    final w = landmarks[LandmarkId.leftWrist]?.confidence ?? 0;
    final h = landmarks[LandmarkId.leftHip]?.confidence ?? 0;
    final a = landmarks[LandmarkId.leftAnkle]?.confidence ?? 0;
    return (s + e + w + h + a) / 5.0;
  }

  /// Calculates average confidence for the right key pushup joints:
  /// (shoulder, elbow, wrist, hip, ankle).
  double get rightConfidence {
    final s = landmarks[LandmarkId.rightShoulder]?.confidence ?? 0;
    final e = landmarks[LandmarkId.rightElbow]?.confidence ?? 0;
    final w = landmarks[LandmarkId.rightWrist]?.confidence ?? 0;
    final h = landmarks[LandmarkId.rightHip]?.confidence ?? 0;
    final a = landmarks[LandmarkId.rightAnkle]?.confidence ?? 0;
    return (s + e + w + h + a) / 5.0;
  }

  /// Returns the body side that has the higher confidence.
  BodySide get prominentSide =>
      leftConfidence >= rightConfidence ? BodySide.left : BodySide.right;

  /// Returns confidence of the prominent side.
  double get prominentConfidence =>
      prominentSide == BodySide.left ? leftConfidence : rightConfidence;
}

