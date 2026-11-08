import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'pose_frame.dart';

class MLKitPoseAdapter {
  static PoseFrame toPoseFrame(Pose pose, {DateTime? timestamp}) {
    final Map<LandmarkId, PosePoint> pointMap = {};

    for (final entry in pose.landmarks.entries) {
      final id = _mapMLKitTypeToLandmarkId(entry.key);
      if (id != null) {
        final mark = entry.value;
        pointMap[id] = PosePoint(
          x: mark.x,
          y: mark.y,
          z: mark.z,
          confidence: mark.likelihood,
        );
      }
    }

    return PoseFrame(
      landmarks: pointMap,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  static LandmarkId? _mapMLKitTypeToLandmarkId(PoseLandmarkType type) {
    switch (type) {
      case PoseLandmarkType.nose:
        return LandmarkId.nose;
      case PoseLandmarkType.leftEyeInner:
        return LandmarkId.leftEyeInner;
      case PoseLandmarkType.leftEye:
        return LandmarkId.leftEye;
      case PoseLandmarkType.leftEyeOuter:
        return LandmarkId.leftEyeOuter;
      case PoseLandmarkType.rightEyeInner:
        return LandmarkId.rightEyeInner;
      case PoseLandmarkType.rightEye:
        return LandmarkId.rightEye;
      case PoseLandmarkType.rightEyeOuter:
        return LandmarkId.rightEyeOuter;
      case PoseLandmarkType.leftEar:
        return LandmarkId.leftEar;
      case PoseLandmarkType.rightEar:
        return LandmarkId.rightEar;
      case PoseLandmarkType.leftMouth:
        return LandmarkId.mouthLeft;
      case PoseLandmarkType.rightMouth:
        return LandmarkId.mouthRight;
      case PoseLandmarkType.leftShoulder:
        return LandmarkId.leftShoulder;
      case PoseLandmarkType.rightShoulder:
        return LandmarkId.rightShoulder;
      case PoseLandmarkType.leftElbow:
        return LandmarkId.leftElbow;
      case PoseLandmarkType.rightElbow:
        return LandmarkId.rightElbow;
      case PoseLandmarkType.leftWrist:
        return LandmarkId.leftWrist;
      case PoseLandmarkType.rightWrist:
        return LandmarkId.rightWrist;
      case PoseLandmarkType.leftPinky:
        return LandmarkId.leftPinky;
      case PoseLandmarkType.rightPinky:
        return LandmarkId.rightPinky;
      case PoseLandmarkType.leftIndex:
        return LandmarkId.leftIndex;
      case PoseLandmarkType.rightIndex:
        return LandmarkId.rightIndex;
      case PoseLandmarkType.leftThumb:
        return LandmarkId.leftThumb;
      case PoseLandmarkType.rightThumb:
        return LandmarkId.rightThumb;
      case PoseLandmarkType.leftHip:
        return LandmarkId.leftHip;
      case PoseLandmarkType.rightHip:
        return LandmarkId.rightHip;
      case PoseLandmarkType.leftKnee:
        return LandmarkId.leftKnee;
      case PoseLandmarkType.rightKnee:
        return LandmarkId.rightKnee;
      case PoseLandmarkType.leftAnkle:
        return LandmarkId.leftAnkle;
      case PoseLandmarkType.rightAnkle:
        return LandmarkId.rightAnkle;
      case PoseLandmarkType.leftHeel:
        return LandmarkId.leftHeel;
      case PoseLandmarkType.rightHeel:
        return LandmarkId.rightHeel;
      case PoseLandmarkType.leftFootIndex:
        return LandmarkId.leftFootIndex;
      case PoseLandmarkType.rightFootIndex:
        return LandmarkId.rightFootIndex;
    }
  }
}

