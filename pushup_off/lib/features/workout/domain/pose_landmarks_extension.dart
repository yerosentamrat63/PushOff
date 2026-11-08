import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class LandmarkVisibilityStatus {
  final bool shouldersVisible;
  final bool elbowsVisible;
  final bool wristsVisible;
  final bool hipsVisible;
  final bool anklesVisible;
  final double averageConfidence;

  const LandmarkVisibilityStatus({
    required this.shouldersVisible,
    required this.elbowsVisible,
    required this.wristsVisible,
    required this.hipsVisible,
    required this.anklesVisible,
    required this.averageConfidence,
  });

  bool get allKeyJointsVisible =>
      shouldersVisible &&
      elbowsVisible &&
      wristsVisible &&
      hipsVisible &&
      anklesVisible;

  factory LandmarkVisibilityStatus.fromPose(Pose? pose, {double threshold = 0.6}) {
    if (pose == null || pose.landmarks.isEmpty) {
      return const LandmarkVisibilityStatus(
        shouldersVisible: false,
        elbowsVisible: false,
        wristsVisible: false,
        hipsVisible: false,
        anklesVisible: false,
        averageConfidence: 0.0,
      );
    }

    final lm = pose.landmarks;

    bool isVisible(PoseLandmarkType type) {
      final mark = lm[type];
      return mark != null && mark.likelihood >= threshold;
    }

    // Either left or right visible with >= threshold (as side view pushups usually show one prominent side)
    final leftShoulder = isVisible(PoseLandmarkType.leftShoulder);
    final rightShoulder = isVisible(PoseLandmarkType.rightShoulder);
    final shoulders = leftShoulder || rightShoulder;

    final leftElbow = isVisible(PoseLandmarkType.leftElbow);
    final rightElbow = isVisible(PoseLandmarkType.rightElbow);
    final elbows = leftElbow || rightElbow;

    final leftWrist = isVisible(PoseLandmarkType.leftWrist);
    final rightWrist = isVisible(PoseLandmarkType.rightWrist);
    final wrists = leftWrist || rightWrist;

    final leftHip = isVisible(PoseLandmarkType.leftHip);
    final rightHip = isVisible(PoseLandmarkType.rightHip);
    final hips = leftHip || rightHip;

    final leftAnkle = isVisible(PoseLandmarkType.leftAnkle);
    final rightAnkle = isVisible(PoseLandmarkType.rightAnkle);
    final ankles = leftAnkle || rightAnkle;

    double totalConfidence = 0.0;
    int count = 0;
    for (final mark in lm.values) {
      totalConfidence += mark.likelihood;
      count++;
    }

    final avg = count > 0 ? totalConfidence / count : 0.0;

    return LandmarkVisibilityStatus(
      shouldersVisible: shoulders,
      elbowsVisible: elbows,
      wristsVisible: wrists,
      hipsVisible: hips,
      anklesVisible: ankles,
      averageConfidence: avg,
    );
  }
}

