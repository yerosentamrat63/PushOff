import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/progress_bar.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../groups/domain/group_model.dart';
import '../../groups/presentation/groups_controller.dart';
import '../../settings/presentation/settings_controller.dart';
import '../../workout/presentation/controllers/workout_history_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(todayProgressProvider);
    final user = ref.watch(currentUserProvider).value;
    final firstName = (user?.displayName.trim().isNotEmpty ?? false)
        ? user!.displayName.trim().split(RegExp(r'\s+')).first
        : 'Yerosen';

    final dailyGoalSetting = ref.watch(dailyGoalRepsProvider);
    final todayValidReps = progressAsync.value?.todayValidReps ?? 0;
    final dailyGoal = progressAsync.value?.dailyGoal ?? dailyGoalSetting;
    final progressPercent = progressAsync.value?.progressPercent ?? 0.0;
    final streakDays = progressAsync.value?.streakDays ?? 0;
    final isGoalMet = progressAsync.value?.isGoalMet ?? false;
    final remainingReps = progressAsync.value?.remainingReps ?? dailyGoal;
    final groupsAsync = ref.watch(userGroupsProvider);
    final groups = groupsAsync.value ?? const <GroupModel>[];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          children: [
            // Top Header: Greeting & Streak Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today',
                      style: AppTypography.bodySmall(color: AppColors.textMuted)
                          .copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Hey, $firstName',
                      style: AppTypography.displayMedium(fontSize: 34),
                    ),
                  ],
                ),
                // Dynamic Streak Pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        color: AppColors.accentLime,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$streakDays day streak',
                        style: AppTypography.titleMedium(
                            color: AppColors.text, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Hero Push-Up Progress Card
            AppCard(
              borderRadius: 24,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Valid push-ups today',
                    style: AppTypography.bodyMedium(color: AppColors.textMuted)
                        .copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$todayValidReps',
                        style: AppTypography.heroNumber(
                          color: AppColors.accentLime,
                          fontSize: 112,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '/ $dailyGoal',
                        style: AppTypography.displayMedium(
                          color: AppColors.textMuted,
                          fontSize: 28,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ProgressBar(value: progressPercent, height: 8),
                  const SizedBox(height: 12),
                  Text(
                    isGoalMet
                        ? 'Daily goal reached! Keep crushing it.'
                        : '$remainingReps to hit your daily goal',
                    style: AppTypography.bodySmall(color: AppColors.textMuted)
                        .copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Big Start Set Button
            PrimaryButton(
              label: 'Start set',
              height: 64,
              borderRadius: 20,
              icon: const Icon(Icons.play_arrow_rounded,
                  color: AppColors.textOnAccent, size: 28),
              onPressed: () => context.push(RoutePaths.setup),
            ),

            const SizedBox(height: 24),

            // Active Goals Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Active goals',
                  style: AppTypography.titleLarge(fontSize: 18),
                ),
                InkWell(
                  onTap: () => context.go(RoutePaths.groups),
                  child: Text(
                    'See all',
                    style: AppTypography.titleMedium(
                      color: AppColors.accentLime,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (groupsAsync.isLoading && groups.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.accentLime),
                ),
              )
            else if (groups.isEmpty)
              AppCard(
                borderRadius: 18,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No active goals yet',
                      style: AppTypography.titleLarge(fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Join a squad or create a challenge to get started.',
                      style:
                          AppTypography.bodySmall(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton(
                      onPressed: () => context.go(RoutePaths.groups),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.accentLime),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Find a group',
                        style: AppTypography.titleMedium(
                          color: AppColors.accentLime,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...groups.take(2).map(
                    (group) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ActiveGoalCard(
                        title: group.name,
                        subtitle: group.formattedPeriodGoal,
                        currentProgress: group.totalRepsInPeriod,
                        targetGoal: group.goal,
                        progressValue: group.progressPercent,
                        daysLeft: group.daysLeftText,
                        onTap: () =>
                            context.push(RoutePaths.groupDetail(group.id)),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _ActiveGoalCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final int currentProgress;
  final int targetGoal;
  final double progressValue;
  final String daysLeft;
  final VoidCallback onTap;

  const _ActiveGoalCard({
    required this.title,
    required this.subtitle,
    required this.currentProgress,
    required this.targetGoal,
    required this.progressValue,
    required this.daysLeft,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AppCard(
        borderRadius: 18,
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: AppTypography.titleLarge(fontSize: 18)),
                Text(
                  daysLeft,
                  style: AppTypography.bodySmall(color: AppColors.textMuted)
                      .copyWith(fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTypography.bodySmall(color: AppColors.textMuted)
                  .copyWith(fontSize: 13),
            ),
            const SizedBox(height: 12),
            ProgressBar(value: progressValue, height: 6),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$currentProgress / $targetGoal reps',
                  style: AppTypography.bodySmall(color: AppColors.textMuted)
                      .copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${(progressValue * 100).toInt()}%',
                  style: AppTypography.titleMedium(
                    color: AppColors.accentLime,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
