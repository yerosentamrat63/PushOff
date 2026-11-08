import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_card.dart';

class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String? secondaryValue;
  final String? subtitle;
  final Widget? trailing;
  final Color valueColor;
  final double valueFontSize;
  final bool isCard;
  final EdgeInsetsGeometry padding;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.secondaryValue,
    this.subtitle,
    this.trailing,
    this.valueColor = AppColors.text,
    this.valueFontSize = 48.0,
    this.isCard = true,
    this.padding = const EdgeInsets.all(20.0),
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyMedium(color: AppColors.textMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: AppTypography.heroNumber(
                color: valueColor,
                fontSize: valueFontSize,
              ),
            ),
            if (secondaryValue != null) ...[
              const SizedBox(width: 8),
              Text(
                secondaryValue!,
                style: AppTypography.displaySmall(color: AppColors.textMuted),
              ),
            ],
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: AppTypography.bodySmall(color: AppColors.textMuted),
          ),
        ],
      ],
    );

    if (isCard) {
      return AppCard(
        padding: padding,
        child: content,
      );
    }

    return Padding(
      padding: padding,
      child: content,
    );
  }
}

