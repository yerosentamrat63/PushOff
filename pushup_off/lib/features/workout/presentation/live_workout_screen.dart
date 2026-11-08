import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'package:pushup_off/features/workout/data/camera_service.dart';
import 'package:pushup_off/features/workout/domain/models/rep_counter_output.dart';
import '../../settings/presentation/settings_controller.dart';
import 'controllers/workout_detection_controller.dart';
import 'controllers/workout_session_controller.dart';
import 'widgets/pose_skeleton_painter.dart';

class LiveWorkoutScreen extends ConsumerStatefulWidget {
  const LiveWorkoutScreen({super.key});

  @override
  ConsumerState<LiveWorkoutScreen> createState() => _LiveWorkoutScreenState();
}

class _LiveWorkoutScreenState extends ConsumerState<LiveWorkoutScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Release the setup/countdown camera before the live session opens its
      // own camera. Both use the same physical device, so this order matters.
      await ref.read(workoutDetectionProvider.notifier).stopDetection();
      if (!mounted) return;
      await ref.read(workoutSessionProvider.notifier).startWorkoutSession(
            preferFront: ref.read(preferFrontCameraProvider),
          );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    final notifier = ref.read(workoutSessionProvider.notifier);
    switch (lifecycleState) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        unawaited(notifier.handleAppPaused());
        break;
      case AppLifecycleState.resumed:
        unawaited(notifier.handleAppResumed());
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  String _formatTimer(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(workoutSessionProvider);
    final repOutput = sessionState.repOutput;
    final cameraService =
        ref.read(workoutSessionProvider.notifier).cameraService;
    final controller = cameraService.controller;
    final isCameraReady = sessionState.cameraStatus == CameraStateStatus.ready;

    final hasFailureAlert = repOutput.latestRejectionReason != null;
    final warningText = hasFailureAlert
        ? repOutput.latestRejectionReason!.coachTip
        : repOutput.latestFeedbackMessage;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0B0C),
      body: Stack(
        children: [
          // 1. Live Camera Stream with Pose Skeleton & Accessibility Semantics
          Positioned.fill(
            child: Semantics(
              label:
                  'Camera preview tracking push-up skeleton with 33 body landmarks',
              image: true,
              child: isCameraReady &&
                      controller != null &&
                      controller.value.isInitialized
                  ? FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: controller.value.previewSize?.height ?? 720,
                        height: controller.value.previewSize?.width ?? 1280,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CameraPreview(controller),
                            if (sessionState.currentPose != null)
                              CustomPaint(
                                painter: PoseSkeletonPainter(
                                  pose: sessionState.currentPose,
                                  imageSize: sessionState.imageSize,
                                  isFrontCamera: sessionState.isFrontCamera,
                                  confidenceThreshold: 0.4,
                                ),
                              ),
                          ],
                        ),
                      ),
                    )
                  : Container(
                      color: const Color(0xFF14171A),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 36,
                              height: 36,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.accentLime),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Connecting AI Pose Detector...',
                              style: AppTypography.bodySmall(),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),

          // 2. Short Red Visual Flash on Rejected Rep
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                color: sessionState.showRejectionFlash
                    ? const Color(0x66FF3B30)
                    : Colors.transparent,
              ),
            ),
          ),

          // 3. Vignette Overlays
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.75),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withOpacity(0.85),
                    ],
                    stops: const [0.0, 0.22, 0.65, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // 4. Workout HUD Content
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Row: Timer Pill + Tracking Status Pill
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Timer Pill
                      Semantics(
                        label:
                            'Workout duration: ${_formatTimer(sessionState.secondsElapsed)}',
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xCC181B1E),
                            borderRadius: BorderRadius.circular(999),
                            border:
                                Border.all(color: AppColors.border, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: sessionState.isPaused
                                      ? AppColors.warning
                                      : AppColors.accentLime,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatTimer(sessionState.secondsElapsed),
                                style: AppTypography.titleMedium(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Tracking Status Pill
                      Semantics(
                        label: repOutput.isTrackingPaused
                            ? 'Tracking paused, move back into frame'
                            : 'AI tracking active locked on ${repOutput.activeSide.name} side',
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xCC181B1E),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: repOutput.isTrackingPaused
                                  ? AppColors.warning.withOpacity(0.5)
                                  : AppColors.border,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                repOutput.isTrackingPaused
                                    ? Icons.videocam_off_rounded
                                    : Icons.remove_red_eye_rounded,
                                color: repOutput.isTrackingPaused
                                    ? AppColors.warning
                                    : AppColors.accentLime,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                repOutput.isTrackingPaused
                                    ? 'Lost tracking'
                                    : 'Tracking (${repOutput.activeSide.name})',
                                style: AppTypography.caption(
                                  color: repOutput.isTrackingPaused
                                      ? AppColors.warning
                                      : AppColors.accentLime,
                                ).copyWith(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Spacer(flex: 2),

                  // Center: Huge Valid Rep Counter
                  Center(
                    child: Semantics(
                      label: '${repOutput.validReps} valid push-ups completed',
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${repOutput.validReps}',
                            style: AppTypography.heroNumber(
                              color: AppColors.accentLime,
                              fontSize: 140,
                            ),
                          ),
                          Text(
                            repOutput.state == RepState.down
                                ? 'HOLD DEPTH'
                                : (repOutput.state == RepState.descending
                                    ? 'LOWER...'
                                    : 'VALID REPS'),
                            style: AppTypography.buttonUppercase(
                              color: repOutput.state == RepState.down
                                  ? AppColors.accentLime
                                  : AppColors.textMuted,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(flex: 3),

                  // Dynamic Warning Banner
                  if (warningText.isNotEmpty)
                    Semantics(
                      label: 'Form alert: $warningText',
                      liveRegion: true,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: hasFailureAlert
                              ? const Color(0xE62A1A12)
                              : const Color(0xCC181B1E),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: hasFailureAlert
                                ? const Color(0xFFFF9466).withOpacity(0.6)
                                : AppColors.border,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              hasFailureAlert
                                  ? Icons.error_outline_rounded
                                  : Icons.info_outline_rounded,
                              color: hasFailureAlert
                                  ? AppColors.warning
                                  : AppColors.accentLime,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                warningText,
                                style: AppTypography.bodySmall(
                                  color: hasFailureAlert
                                      ? AppColors.warning
                                      : AppColors.text,
                                ).copyWith(
                                    fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Live Form Feedback Tiles Row
                  Row(
                    children: [
                      // Live Elbow Angle
                      Expanded(
                        child: Semantics(
                          label:
                              'Live elbow angle ${repOutput.liveElbowAngle.toStringAsFixed(0)} degrees',
                          child: _LiveMetricTile(
                            label: 'Elbow',
                            value:
                                '${repOutput.liveElbowAngle.toStringAsFixed(0)}°',
                            isWarning: repOutput.liveElbowAngle > 90 &&
                                repOutput.state == RepState.down,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Live Body Line
                      Expanded(
                        child: Semantics(
                          label:
                              'Live body line angle ${repOutput.liveBodyLineAngle.toStringAsFixed(0)} degrees',
                          child: _LiveMetricTile(
                            label: 'Body line',
                            value:
                                '${repOutput.liveBodyLineAngle.toStringAsFixed(0)}°',
                            isWarning: repOutput.liveBodyLineAngle < 165 &&
                                repOutput.state != RepState.up,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Rejected Reps Counter
                      Expanded(
                        child: Semantics(
                          label: '${repOutput.rejectedReps} rejected reps',
                          child: _LiveMetricTile(
                            label: 'Rejected',
                            value: '${repOutput.rejectedReps}',
                            isWarning: repOutput.rejectedReps > 0,
                            customColor: repOutput.rejectedReps > 0
                                ? AppColors.warning
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Form Score
                      Expanded(
                        child: Semantics(
                          label:
                              'Current form score ${repOutput.formScore.toStringAsFixed(0)} percent',
                          child: _LiveMetricTile(
                            label: 'Form',
                            value: repOutput.formScore.toStringAsFixed(0),
                            customColor: AppColors.accentLime,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Bottom Controls: Pause/Resume + End Set
                  Row(
                    children: [
                      // Pause / Resume Button
                      Semantics(
                        label: sessionState.isPaused
                            ? 'Resume workout set'
                            : 'Pause workout set',
                        button: true,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xCC181B1E),
                            borderRadius: BorderRadius.circular(16),
                            border:
                                Border.all(color: AppColors.border, width: 1),
                          ),
                          child: IconButton(
                            icon: Icon(
                              sessionState.isPaused
                                  ? Icons.play_arrow_rounded
                                  : Icons.pause_rounded,
                              color: AppColors.text,
                              size: 26,
                            ),
                            onPressed: () {
                              ref
                                  .read(workoutSessionProvider.notifier)
                                  .togglePause();
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // End Set Button
                      Expanded(
                        child: Semantics(
                          label: 'End set and view summary',
                          button: true,
                          child: SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.surface,
                                foregroundColor: AppColors.text,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: const BorderSide(
                                      color: AppColors.borderLight, width: 1),
                                ),
                              ),
                              onPressed: () async {
                                final notifier =
                                    ref.read(workoutSessionProvider.notifier);
                                await notifier.endWorkoutSession();
                                if (context.mounted) {
                                  context.pushReplacement(RoutePaths.summary);
                                }
                              },
                              child: Text(
                                'End set',
                                style: AppTypography.buttonUppercase(
                                  color: AppColors.text,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final bool isWarning;
  final Color? customColor;

  const _LiveMetricTile({
    required this.label,
    required this.value,
    this.isWarning = false,
    this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    final textColor =
        isWarning ? AppColors.warning : (customColor ?? AppColors.text);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xCC181B1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isWarning ? AppColors.warning.withOpacity(0.5) : AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTypography.caption(
              color: isWarning ? AppColors.warning : AppColors.textMuted,
            ).copyWith(fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTypography.heroNumber(
              color: textColor,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}
