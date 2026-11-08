import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../data/camera_service.dart';
import '../controllers/workout_detection_controller.dart';
import 'pose_skeleton_painter.dart';

class CameraViewWidget extends ConsumerWidget {
  final bool showSkeleton;
  final Widget? overlay;

  const CameraViewWidget({
    super.key,
    this.showSkeleton = true,
    this.overlay,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detectionState = ref.watch(workoutDetectionProvider);
    final controller = ref.read(workoutDetectionProvider.notifier).cameraService.controller;

    switch (detectionState.cameraStatus) {
      case CameraStateStatus.uninitialized:
        return Container(
          color: const Color(0xFF0A0B0C),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentLime),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Starting camera stream...',
                style: AppTypography.bodySmall(color: AppColors.textMuted),
              ),
            ],
          ),
        );

      case CameraStateStatus.permissionDenied:
      case CameraStateStatus.permissionPermanentlyDenied:
        final isPermanent = detectionState.cameraStatus == CameraStateStatus.permissionPermanentlyDenied;
        return Container(
          color: AppColors.surface,
          padding: const EdgeInsets.all(24),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: AppColors.warningBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.warning, width: 1.5),
                ),
                child: const Icon(
                  Icons.videocam_off_rounded,
                  color: AppColors.warning,
                  size: 32,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Camera Access Required',
                style: AppTypography.titleLarge(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Push-Up Off uses real-time computer vision to count valid reps and verify elbow depth on device.',
                style: AppTypography.bodySmall(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: isPermanent ? 'Open Device Settings' : 'Grant Camera Access',
                onPressed: () async {
                  if (isPermanent) {
                    await openAppSettings();
                  } else {
                    ref.read(workoutDetectionProvider.notifier).startDetection();
                  }
                },
              ),
            ],
          ),
        );

      case CameraStateStatus.error:
        return Container(
          color: const Color(0xFF0A0B0C),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.warning, size: 40),
              const SizedBox(height: 12),
              Text('Unable to access camera', style: AppTypography.titleMedium()),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Retry',
                onPressed: () {
                  ref.read(workoutDetectionProvider.notifier).startDetection();
                },
              ),
            ],
          ),
        );

      case CameraStateStatus.ready:
        if (controller == null || !controller.value.isInitialized) {
          return const SizedBox.shrink();
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Live Camera Preview
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller.value.previewSize?.height ?? 720,
                  height: controller.value.previewSize?.width ?? 1280,
                  child: CameraPreview(controller),
                ),
              ),

              // 2. Real-time 33 Landmark Skeleton Overlay
              if (showSkeleton && detectionState.currentPose != null)
                CustomPaint(
                  painter: PoseSkeletonPainter(
                    pose: detectionState.currentPose,
                    imageSize: detectionState.imageSize,
                    isFrontCamera: detectionState.isFrontCamera,
                    confidenceThreshold: 0.4,
                  ),
                ),

              // 3. Custom overlay (e.g. guide lines or HUD badges)
              if (overlay != null) overlay!,
            ],
          ),
        );
    }
  }
}

