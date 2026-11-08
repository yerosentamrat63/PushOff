import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../../../../core/theme/app_colors.dart';

class PoseSkeletonPainter extends CustomPainter {
  final Pose? pose;
  final Size imageSize;
  final bool isFrontCamera;
  final double confidenceThreshold;

  PoseSkeletonPainter({
    required this.pose,
    required this.imageSize,
    this.isFrontCamera = true,
    this.confidenceThreshold = 0.4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (pose == null || pose!.landmarks.isEmpty) return;

    final linePaint = Paint()
      ..color = AppColors.accentLime
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final jointPaint = Paint()
      ..color = AppColors.accentLime
      ..style = PaintingStyle.fill;

    final jointBorderPaint = Paint()
      ..color = AppColors.textOnAccent
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final double scaleX = size.width / (imageSize.width > 0 ? imageSize.width : size.width);
    final double scaleY = size.height / (imageSize.height > 0 ? imageSize.height : size.height);

    Offset transformPoint(PoseLandmark landmark) {
      double x = landmark.x;
      double y = landmark.y;

      if (isFrontCamera) {
        x = (imageSize.width > 0 ? imageSize.width : size.width) - x;
      }

      return Offset(x * scaleX, y * scaleY);
    }

    void drawBone(PoseLandmarkType type1, PoseLandmarkType type2) {
      final mark1 = pose!.landmarks[type1];
      final mark2 = pose!.landmarks[type2];

      if (mark1 == null || mark2 == null) return;
      if (mark1.likelihood < confidenceThreshold || mark2.likelihood < confidenceThreshold) return;

      final p1 = transformPoint(mark1);
      final p2 = transformPoint(mark2);

      canvas.drawLine(p1, p2, linePaint);
    }

    // Connect standard 33 pose landmark segments:
    // Torso
    drawBone(PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
    drawBone(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip);
    drawBone(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip);
    drawBone(PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);

    // Left Arm
    drawBone(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow);
    drawBone(PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist);
    drawBone(PoseLandmarkType.leftWrist, PoseLandmarkType.leftThumb);
    drawBone(PoseLandmarkType.leftWrist, PoseLandmarkType.leftPinky);
    drawBone(PoseLandmarkType.leftWrist, PoseLandmarkType.leftIndex);

    // Right Arm
    drawBone(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow);
    drawBone(PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist);
    drawBone(PoseLandmarkType.rightWrist, PoseLandmarkType.rightThumb);
    drawBone(PoseLandmarkType.rightWrist, PoseLandmarkType.rightPinky);
    drawBone(PoseLandmarkType.rightWrist, PoseLandmarkType.rightIndex);

    // Left Leg
    drawBone(PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee);
    drawBone(PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle);
    drawBone(PoseLandmarkType.leftAnkle, PoseLandmarkType.leftHeel);
    drawBone(PoseLandmarkType.leftAnkle, PoseLandmarkType.leftFootIndex);

    // Right Leg
    drawBone(PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee);
    drawBone(PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle);
    drawBone(PoseLandmarkType.rightAnkle, PoseLandmarkType.rightHeel);
    drawBone(PoseLandmarkType.rightAnkle, PoseLandmarkType.rightFootIndex);

    // Face / Head
    drawBone(PoseLandmarkType.leftEar, PoseLandmarkType.leftEye);
    drawBone(PoseLandmarkType.leftEye, PoseLandmarkType.nose);
    drawBone(PoseLandmarkType.nose, PoseLandmarkType.rightEye);
    drawBone(PoseLandmarkType.rightEye, PoseLandmarkType.rightEar);
    drawBone(PoseLandmarkType.leftMouth, PoseLandmarkType.rightMouth);

    // Draw all 33 landmark joints
    for (final mark in pose!.landmarks.values) {
      if (mark.likelihood >= confidenceThreshold) {
        final pt = transformPoint(mark);
        canvas.drawCircle(pt, 5.0, jointPaint);
        canvas.drawCircle(pt, 5.0, jointBorderPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant PoseSkeletonPainter oldDelegate) {
    return oldDelegate.pose != pose ||
        oldDelegate.imageSize != imageSize ||
        oldDelegate.isFrontCamera != isFrontCamera;
  }
}

