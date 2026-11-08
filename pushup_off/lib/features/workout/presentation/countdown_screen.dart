import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../settings/presentation/settings_controller.dart';
import 'controllers/workout_detection_controller.dart';

class CountdownScreen extends ConsumerStatefulWidget {
  const CountdownScreen({super.key});

  @override
  ConsumerState<CountdownScreen> createState() => _CountdownScreenState();
}

class _CountdownScreenState extends ConsumerState<CountdownScreen> {
  int _secondsRemaining = 3;
  Timer? _countdownTimer;
  bool _countdownStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(workoutDetectionProvider.notifier).startDetection(
            preferFront: ref.read(preferFrontCameraProvider),
          );
    });
  }

  void _triggerCountdown() {
    if (_countdownStarted) return;
    _countdownStarted = true;

    _countdownTimer?.cancel();
    HapticFeedback.selectionClick();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 1) {
        setState(() => _secondsRemaining--);
        HapticFeedback.mediumImpact();
      } else {
        _countdownTimer?.cancel();
        HapticFeedback.heavyImpact();
        if (mounted) {
          context.go(RoutePaths.live);
        }
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detectionState = ref.watch(workoutDetectionProvider);
    final allJointsDetected =
        detectionState.visibilityStatus.allKeyJointsVisible;

    // Automatically trigger countdown when all joints are detected
    if (allJointsDetected && !_countdownStarted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerCountdown();
      });
    }

    return Scaffold(
      backgroundColor: AppColors.surfaceDark,
      body: Stack(
        children: [
          // Floor reference line
          Positioned(
            left: 0,
            right: 0,
            top: 520,
            child: Container(
              height: 2,
              color: const Color(0xFF2A2F34),
            ),
          ),

          // Background Plank Skeleton
          Positioned(
            left: 0,
            right: 0,
            top: 380,
            height: 220,
            child: Opacity(
              opacity: 0.7,
              child: CustomPaint(
                painter: _PlankSkeletonPainter(),
              ),
            ),
          ),

          // Top Safe Area with Cancel Button
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Align(
                alignment: Alignment.topRight,
                child: InkWell(
                  onTap: () {
                    _countdownTimer?.cancel();
                    context.go(RoutePaths.home);
                  },
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: AppColors.overlayDark,
                      borderRadius: BorderRadius.circular(999),
                      border:
                          Border.all(color: const Color(0xFF2A2F34), width: 1),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Cancel',
                      style: AppTypography.titleMedium(fontSize: 15),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Central Countdown Content
          Positioned(
            left: 0,
            right: 0,
            top: 130,
            child: Column(
              children: [
                Text(
                  _countdownStarted ? 'Set starts in' : 'Align body in frame',
                  style: AppTypography.bodyMedium(color: AppColors.textMuted)
                      .copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                Text(
                  _countdownStarted ? '$_secondsRemaining' : 'READY',
                  style: AppTypography.heroNumber(
                    color: AppColors.accentLime,
                    fontSize: _countdownStarted ? 200 : 96,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _countdownStarted
                      ? 'GET INTO PLANK'
                      : 'Awaiting joint detection',
                  style: AppTypography.displayMedium(fontSize: 26),
                ),
              ],
            ),
          ),

          // Bottom Joints Status & Start Now Button
          Positioned(
            left: 20,
            right: 20,
            bottom: 32,
            child: Column(
              children: [
                // All joints detected status card
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.overlaySurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: allJointsDetected
                          ? AppColors.accentLime
                          : AppColors.border,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: allJointsDetected
                              ? AppColors.accentLime
                              : AppColors.warning,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        allJointsDetected
                            ? 'All joints detected'
                            : 'Position whole body in frame',
                        style: AppTypography.titleMedium(
                          fontSize: 15,
                          color: allJointsDetected
                              ? AppColors.text
                              : AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Start now button
                SizedBox(
                  height: 56,
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      _countdownTimer?.cancel();
                      context.go(RoutePaths.live);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: AppColors.borderLight, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      'Start now',
                      style: AppTypography.titleMedium(color: AppColors.text),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlankSkeletonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppColors.accentLime
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final jointPaint = Paint()
      ..color = AppColors.accentLime
      ..style = PaintingStyle.fill;

    // Head
    canvas.drawCircle(
        Offset(size.width * 0.14, size.height * 0.46), 16, linePaint);

    final shoulder = Offset(size.width * 0.22, size.height * 0.48);
    final elbow = Offset(size.width * 0.44, size.height * 0.40);
    final wrist = Offset(size.width * 0.46, size.height * 0.72);
    final hip = Offset(size.width * 0.76, size.height * 0.48);
    final ankle = Offset(size.width * 0.90, size.height * 0.72);

    canvas.drawLine(shoulder, elbow, linePaint);
    canvas.drawLine(elbow, wrist, linePaint);
    canvas.drawLine(shoulder, hip, linePaint);
    canvas.drawLine(hip, ankle, linePaint);

    for (final pt in [shoulder, elbow, wrist, hip, ankle]) {
      canvas.drawCircle(pt, 7, jointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
