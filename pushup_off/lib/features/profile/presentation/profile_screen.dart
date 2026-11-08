import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../workout/presentation/controllers/workout_history_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(profileStatsProvider);
    final recentAsync = ref.watch(recentSessionsProvider);
    final user = ref.watch(currentUserProvider).value;

    final stats = statsAsync.value;
    final recentSessions = recentAsync.value ?? [];
    final displayName = user?.displayName ?? 'Yerosen';
    final initials = user?.initials ?? 'Y';
    final memberSince = user != null
        ? DateFormat('MMM yyyy').format(user.createdAt)
        : 'Oct 2026';

    final numberFormat = NumberFormat('#,###');
    final totalRepsStr = stats != null ? numberFormat.format(stats.totalValidReps) : '1,248';
    final bestSetStr = stats != null ? stats.bestSetReps.toString() : '31';
    final avgFormStr = stats != null ? stats.averageFormScore.toStringAsFixed(0) : '89';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          children: [
            // Top Header: User Profile Avatar, Name & Settings Button
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: AppColors.accentLime,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: AppTypography.heroNumber(
                      color: AppColors.textOnAccent,
                      fontSize: 32,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: AppTypography.heroNumber(fontSize: 32),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Member since $memberSince',
                        style: AppTypography.bodySmall(color: AppColors.textMuted).copyWith(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => context.push(RoutePaths.settings),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderLight, width: 1),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.tune_rounded,
                      color: AppColors.text,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 3 Stat Tiles Grid
            Row(
              children: [
                Expanded(
                  child: _ProfileMetricCard(
                    value: totalRepsStr,
                    label: 'Valid reps',
                    valueColor: AppColors.accentLime,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ProfileMetricCard(
                    value: bestSetStr,
                    label: 'Best set',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ProfileMetricCard(
                    value: avgFormStr,
                    label: 'Avg form',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 7-Day Activity Chart Card
            AppCard(
              borderRadius: 20,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reps, last 7 days',
                    style: AppTypography.bodySmall(color: AppColors.textMuted).copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 96,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: stats != null && stats.last7Days.isNotEmpty
                          ? stats.last7Days.map((day) {
                              final maxReps = stats.maxDayReps;
                              final factor = (day.validReps / maxReps).clamp(0.08, 1.0);
                              final dayName = day.isToday
                                  ? 'Today'
                                  : DateFormat('E').format(day.date);
                              return _ChartBarItem(
                                heightFactor: factor,
                                day: dayName,
                                isToday: day.isToday,
                              );
                            }).toList()
                          : const [
                              _ChartBarItem(heightFactor: 0.50, day: 'Tue'),
                              _ChartBarItem(heightFactor: 0.69, day: 'Wed'),
                              _ChartBarItem(heightFactor: 0.08, day: 'Thu'),
                              _ChartBarItem(heightFactor: 0.90, day: 'Fri'),
                              _ChartBarItem(heightFactor: 0.60, day: 'Sat'),
                              _ChartBarItem(heightFactor: 1.00, day: 'Sun'),
                              _ChartBarItem(heightFactor: 0.80, day: 'Today', isToday: true),
                            ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Recent Sessions Header
            Text(
              'Recent sessions',
              style: AppTypography.titleLarge(fontSize: 18),
            ),
            const SizedBox(height: 10),

            // Recent Sessions Card List
            AppCard(
              borderRadius: 18,
              padding: EdgeInsets.zero,
              child: Column(
                children: recentSessions.isNotEmpty
                    ? recentSessions.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final session = entry.value;
                        return Semantics(
                          label: 'Session on ${session.formattedRelativeDate}, ${session.validReps} valid reps, form score ${session.formScore.toStringAsFixed(0)}',
                          child: _RecentSessionItem(
                            title: session.formattedRelativeDate,
                            subtitle:
                                '${session.formattedClockDuration} • form ${session.formScore.toStringAsFixed(0)}',
                            reps: '${session.validReps}',
                            isHighlight: idx == 0,
                            showDivider: idx < recentSessions.length - 1,
                          ),
                        );
                      }).toList()
                    : [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 28.0),
                          child: Column(
                            children: [
                              const Icon(Icons.fitness_center_rounded, color: AppColors.textMuted, size: 30),
                              const SizedBox(height: 10),
                              Text('No sessions logged yet', style: AppTypography.titleMedium()),
                              const SizedBox(height: 4),
                              Text(
                                'Complete your first set to unlock form analytics and streak tracking.',
                                style: AppTypography.caption(color: AppColors.textMuted),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMetricCard extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;

  const _ProfileMetricCard({
    required this.value,
    required this.label,
    this.valueColor = AppColors.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTypography.heroNumber(
              color: valueColor,
              fontSize: 34,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.caption(color: AppColors.textMuted).copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ChartBarItem extends StatelessWidget {
  final double heightFactor;
  final String day;
  final bool isToday;

  const _ChartBarItem({
    required this.heightFactor,
    required this.day,
    this.isToday = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              height: 70 * heightFactor,
              decoration: BoxDecoration(
                color: isToday ? AppColors.accentLime : AppColors.borderSubtle,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              day,
              style: AppTypography.caption(
                color: isToday ? AppColors.accentLime : AppColors.textMuted,
              ).copyWith(
                fontSize: 12,
                fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentSessionItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String reps;
  final bool isHighlight;
  final bool showDivider;

  const _RecentSessionItem({
    required this.title,
    required this.subtitle,
    required this.reps,
    this.isHighlight = false,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: AppColors.border, width: 1))
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.titleMedium(fontSize: 16)),
              const SizedBox(height: 2),
              Text(subtitle, style: AppTypography.bodySmall(color: AppColors.textMuted).copyWith(fontSize: 13)),
            ],
          ),
          Text(
            reps,
            style: AppTypography.heroNumber(
              color: isHighlight ? AppColors.accentLime : AppColors.text,
              fontSize: 26,
            ),
          ),
        ],
      ),
    );
  }
}
