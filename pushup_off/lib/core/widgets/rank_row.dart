import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class RankRow extends StatelessWidget {
  final int rank;
  final String name;
  final int reps;
  final String? formScore;
  final String? subtitle;
  final bool isCurrentUser;
  final VoidCallback? onTap;
  final bool showDivider;

  const RankRow({
    super.key,
    required this.rank,
    required this.name,
    required this.reps,
    this.formScore,
    this.subtitle,
    this.isCurrentUser = false,
    this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    Color rankColor;
    if (rank == 1) {
      rankColor = AppColors.accentLime;
    } else if (rank == 2 || rank == 3) {
      rankColor = AppColors.text;
    } else {
      rankColor = AppColors.textMuted;
    }

    final row = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isCurrentUser ? AppColors.surfaceDark : Colors.transparent,
        border: showDivider
            ? const Border(
                bottom: BorderSide(color: AppColors.border, width: 1.0),
              )
            : null,
      ),
      child: Row(
        children: [
          // Rank Number
          SizedBox(
            width: 28,
            child: Text(
              '$rank',
              style: AppTypography.displaySmall(color: rankColor),
            ),
          ),
          const SizedBox(width: 8),

          // Avatar / Initials Circle
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isCurrentUser
                  ? AppColors.accentLime.withOpacity(0.2)
                  : AppColors.border,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: AppTypography.buttonUppercase(
                color: isCurrentUser ? AppColors.accentLime : AppColors.text,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name and Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: AppTypography.titleMedium(
                          color: isCurrentUser ? AppColors.accentLime : AppColors.text,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accentLime.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'YOU',
                          style: AppTypography.caption(color: AppColors.accentLime),
                        ),
                      ),
                    ],
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AppTypography.bodySmall(),
                  ),
                ],
              ],
            ),
          ),

          // Optional Form Score
          if (formScore != null) ...[
            Text(
              formScore!,
              style: AppTypography.bodySmall(color: AppColors.textMuted),
            ),
            const SizedBox(width: 12),
          ],

          // Rep Count
          Text(
            '$reps',
            style: AppTypography.displaySmall(
              color: isCurrentUser ? AppColors.accentLime : AppColors.text,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        child: row,
      );
    }
    return row;
  }
}

