import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ProgressBar extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final double height;
  final Color fillColor;
  final Color trackColor;
  final BorderRadiusGeometry borderRadius;

  const ProgressBar({
    super.key,
    required this.value,
    this.height = 8.0,
    this.fillColor = AppColors.accentLime,
    this.trackColor = AppColors.border,
    this.borderRadius = const BorderRadius.all(Radius.circular(999)),
  });

  @override
  Widget build(BuildContext context) {
    final clampedValue = value.clamp(0.0, 1.0);

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: borderRadius,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Align(
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: constraints.maxWidth * clampedValue,
              height: height,
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: borderRadius,
              ),
            ),
          );
        },
      ),
    );
  }
}

