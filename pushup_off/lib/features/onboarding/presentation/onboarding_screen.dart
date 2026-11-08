import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/primary_button.dart';
import '../../settings/presentation/settings_controller.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  Future<void> _completeOnboarding(WidgetRef ref) async {
    await ref.read(preferencesServiceProvider).setHasSeenOnboarding(true);
  }

  Future<void> _handleCameraPermission(
      BuildContext context, WidgetRef ref) async {
    final status = await Permission.camera.request();

    if (status.isGranted) {
      await _completeOnboarding(ref);
      if (context.mounted) {
        context.go(RoutePaths.home);
      }
    } else if (status.isPermanentlyDenied) {
      if (context.mounted) {
        _showPermissionDeniedDialog(context, ref, isPermanent: true);
      }
    } else {
      if (context.mounted) {
        _showPermissionDeniedDialog(context, ref, isPermanent: false);
      }
    }
  }

  void _showPermissionDeniedDialog(
    BuildContext context,
    WidgetRef ref, {
    required bool isPermanent,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        title: Text(
          'Camera Permission Needed',
          style: AppTypography.titleLarge(),
        ),
        content: Text(
          isPermanent
              ? 'Camera permission is permanently denied. Please enable it in device settings to track your push-ups.'
              : 'Push-Up Off requires camera access to track your body joints and count reps on-device.',
          style: AppTypography.bodyMedium(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _completeOnboarding(ref);
              if (context.mounted) context.go(RoutePaths.home);
            },
            child: Text(
              'Skip',
              style: AppTypography.titleMedium(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              if (isPermanent) {
                await openAppSettings();
              } else {
                final newStatus = await Permission.camera.request();
                if (newStatus.isGranted) {
                  await _completeOnboarding(ref);
                  if (context.mounted) context.go(RoutePaths.home);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentLime,
              foregroundColor: AppColors.textOnAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              isPermanent ? 'Open Settings' : 'Grant Permission',
              style: AppTypography.buttonUppercase(
                  color: AppColors.textOnAccent, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Visual Card with Push-Up Pose Illustration
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Stack(
                  children: [
                    // Floor baseline
                    Positioned(
                      left: 24,
                      right: 24,
                      bottom: 40,
                      child: Container(
                        height: 2,
                        color: AppColors.borderSubtle,
                      ),
                    ),
                    // Simulated Pose Skeleton
                    Center(
                      child: CustomPaint(
                        size: const Size(260, 140),
                        painter: _OnboardingSkeletonPainter(),
                      ),
                    ),
                    // Valid Check Circle Badge
                    Positioned(
                      top: 20,
                      right: 20,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: AppColors.accentLime,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: AppColors.textOnAccent,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Title
              Text(
                'ONLY CLEAN\nREPS COUNT',
                style: AppTypography.heroNumber(fontSize: 44),
              ),

              const SizedBox(height: 10),

              // Subtitle
              Text(
                "Prop your phone up, do your push-ups, and the camera tracks your elbows and body line. Half reps and sagging hips don't make the cut.",
                style: AppTypography.bodyMedium(color: AppColors.textMuted),
              ),

              const SizedBox(height: 24),

              // Feature bullets
              const _FeatureBullet(
                icon: Icons.camera_alt_outlined,
                text: 'Camera tracking runs on your phone',
              ),
              const SizedBox(height: 12),
              const _FeatureBullet(
                icon: Icons.lock_outline_rounded,
                text: 'Video is never saved or uploaded',
              ),
              const SizedBox(height: 12),
              const _FeatureBullet(
                icon: Icons.bar_chart_rounded,
                text: 'Only your rep counts reach friends',
              ),

              const Spacer(),

              // Primary "Allow Camera" Button
              PrimaryButton(
                label: 'Allow camera',
                height: 60,
                borderRadius: 18,
                onPressed: () => _handleCameraPermission(context, ref),
              ),

              const SizedBox(height: 8),

              // "Not now" button
              Center(
                child: TextButton(
                  onPressed: () async {
                    await _completeOnboarding(ref);
                    if (context.mounted) context.go(RoutePaths.home);
                  },
                  child: Text(
                    'Not now',
                    style:
                        AppTypography.titleMedium(color: AppColors.textMuted),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureBullet extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureBullet({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22, color: AppColors.accentLime),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodyMedium(),
          ),
        ),
      ],
    );
  }
}

class _OnboardingSkeletonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppColors.accentLime
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final jointPaint = Paint()
      ..color = AppColors.accentLime
      ..style = PaintingStyle.fill;

    // Head
    canvas.drawCircle(
        Offset(size.width * 0.15, size.height * 0.55), 14, linePaint);

    final shoulder = Offset(size.width * 0.25, size.height * 0.58);
    final elbow = Offset(size.width * 0.42, size.height * 0.45);
    final wrist = Offset(size.width * 0.45, size.height * 0.82);
    final hip = Offset(size.width * 0.68, size.height * 0.58);
    final ankle = Offset(size.width * 0.88, size.height * 0.82);

    canvas.drawLine(shoulder, elbow, linePaint);
    canvas.drawLine(elbow, wrist, linePaint);
    canvas.drawLine(shoulder, hip, linePaint);
    canvas.drawLine(hip, ankle, linePaint);

    for (final pt in [shoulder, elbow, wrist, hip, ankle]) {
      canvas.drawCircle(pt, 6, jointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
