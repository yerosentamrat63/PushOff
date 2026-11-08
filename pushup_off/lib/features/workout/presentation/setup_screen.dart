import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/primary_button.dart';
import 'package:pushup_off/features/workout/data/camera_service.dart';
import '../../settings/presentation/settings_controller.dart';
import 'controllers/workout_detection_controller.dart';
import 'widgets/camera_view_widget.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(workoutDetectionProvider.notifier).startDetection(
            preferFront: ref.read(preferFrontCameraProvider),
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final detectionState = ref.watch(workoutDetectionProvider);
    final visibility = detectionState.visibilityStatus;

    final upperBodyVisible = visibility.shouldersVisible &&
        visibility.elbowsVisible &&
        visibility.wristsVisible;

    final lowerBodyVisible = visibility.hipsVisible && visibility.anklesVisible;
    final hasPose = detectionState.currentPose != null;
    final isLowLighting = hasPose && visibility.averageConfidence < 0.65;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Bar: Back & Camera Lens Switch
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: AppColors.text, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => context.pop(),
                  ),
                  if (detectionState.cameraStatus == CameraStateStatus.ready)
                    IconButton(
                      icon: const Icon(Icons.cameraswitch_rounded,
                          color: AppColors.textMuted, size: 22),
                      onPressed: () {
                        ref
                            .read(workoutDetectionProvider.notifier)
                            .switchCamera();
                      },
                    ),
                ],
              ),

              const SizedBox(height: 10),

              // Title & Placement Guidance
              Text(
                'Place your phone',
                style: AppTypography.heroNumber(fontSize: 40),
              ),
              const SizedBox(height: 6),
              Text(
                'Side view, about 2 metres away, propped at floor level. Your whole body must fit in the frame.',
                style: AppTypography.bodyMedium(color: AppColors.textMuted)
                    .copyWith(
                  height: 1.4,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 16),

              // Live Camera Viewport with Skeleton & Frame Bounds
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [
                        // Camera Feed with Live Skeleton
                        const Positioned.fill(
                          child: CameraViewWidget(
                            showSkeleton: true,
                          ),
                        ),

                        // Dashed Guide Frame Overlay
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: CustomPaint(
                            size: Size.infinite,
                            painter: _DashedRectPainter(),
                          ),
                        ),

                        // Ground reference baseline
                        Positioned(
                          left: 28,
                          right: 28,
                          bottom: 56,
                          child: Container(
                            height: 2,
                            color: AppColors.borderSubtle,
                          ),
                        ),

                        // Guidance watermark if no pose detected yet
                        if (detectionState.currentPose == null &&
                            detectionState.cameraStatus ==
                                CameraStateStatus.ready)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 20,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.overlayDark,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'Step into frame to align joints',
                                  style: AppTypography.caption(
                                      color: AppColors.accentLime),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Real Joint Visibility Checklist (Confidence > 0.6)
              Column(
                children: [
                  _SetupCheckItem(
                    label: 'Shoulders, elbows, wrists visible',
                    isValid: upperBodyVisible,
                    confidenceValue:
                        (visibility.shouldersVisible ? 0.33 : 0.0) +
                            (visibility.elbowsVisible ? 0.33 : 0.0) +
                            (visibility.wristsVisible ? 0.34 : 0.0),
                  ),
                  const SizedBox(height: 10),
                  _SetupCheckItem(
                    label: 'Hips and ankles visible',
                    isValid: lowerBodyVisible,
                    confidenceValue: (visibility.hipsVisible ? 0.5 : 0.0) +
                        (visibility.anklesVisible ? 0.5 : 0.0),
                  ),
                  const SizedBox(height: 10),
                  _SetupCheckItem(
                    label: !hasPose
                        ? 'Step into frame to check lighting'
                        : (isLowLighting
                            ? 'Lighting is low. Turn on a light'
                            : 'Environment lighting good'),
                    isValid: hasPose && !isLowLighting,
                    isWarning: isLowLighting,
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Begin Set Button
              PrimaryButton(
                label: 'Begin set',
                height: 60,
                borderRadius: 18,
                onPressed: () => context.push(RoutePaths.countdown),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SetupCheckItem extends StatelessWidget {
  final String label;
  final bool isValid;
  final bool isWarning;
  final double? confidenceValue;

  const _SetupCheckItem({
    required this.label,
    required this.isValid,
    this.isWarning = false,
    this.confidenceValue,
  });

  @override
  Widget build(BuildContext context) {
    Color textColor = AppColors.text;
    Widget icon;

    if (isWarning) {
      textColor = AppColors.warning;
      icon = Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.warning, width: 2),
        ),
      );
    } else if (isValid) {
      icon = Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          color: AppColors.accentLime,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded,
            color: AppColors.textOnAccent, size: 16),
      );
    } else {
      icon = Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.borderLight, width: 2),
        ),
      );
    }

    return Row(
      children: [
        icon,
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: AppTypography.titleMedium(color: textColor, fontSize: 15),
          ),
        ),
      ],
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.borderSubtle
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 8.0;
    const dashSpace = 6.0;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(16),
    );

    final path = Path()..addRRect(rrect);
    final pathMetrics = path.computeMetrics();

    for (final metric in pathMetrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final len = (distance + dashWidth < metric.length)
            ? dashWidth
            : metric.length - distance;
        final extractPath = metric.extractPath(distance, distance + len);
        canvas.drawPath(extractPath, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
