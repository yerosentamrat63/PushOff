import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../auth/presentation/auth_controller.dart';
import 'settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _showDailyGoalPicker(
    BuildContext context,
    WidgetRef ref,
    int currentGoal,
  ) async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Daily goal',
                  style: AppTypography.titleLarge(fontSize: 20)),
            ),
            for (final goal in const [50, 100, 150, 200, 250])
              ListTile(
                title: Text('$goal reps',
                    style: AppTypography.titleMedium(fontSize: 16)),
                trailing: goal == currentGoal
                    ? const Icon(Icons.check_rounded,
                        color: AppColors.accentLime)
                    : null,
                onTap: () => Navigator.of(ctx).pop(goal),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (selected != null) {
      ref.read(dailyGoalRepsProvider.notifier).state = selected;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voiceRepCount = ref.watch(voiceRepCountEnabledProvider);
    final preferFront = ref.watch(preferFrontCameraProvider);
    final dailyGoal = ref.watch(dailyGoalRepsProvider);
    final dailyReminder = ref.watch(dailyReminderEnabledProvider);
    final groupActivity = ref.watch(groupActivityEnabledProvider);
    final user = ref.watch(currentUserProvider).value;
    final email =
        (user?.email.isNotEmpty ?? false) ? user!.email : 'you@email.com';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header: Back Button + "Settings"
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: AppColors.text, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Settings',
                    style: AppTypography.heroNumber(fontSize: 36),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Expanded(
                child: ListView(
                  children: [
                    // Section 1: WORKOUT
                    Text(
                      'WORKOUT',
                      style: AppTypography.caption(color: AppColors.textMuted)
                          .copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),

                    AppCard(
                      borderRadius: 18,
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          // Daily Goal
                          InkWell(
                            onTap: () =>
                                _showDailyGoalPicker(context, ref, dailyGoal),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 18),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Daily goal',
                                      style: AppTypography.titleMedium(
                                          fontSize: 16)),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '$dailyGoal reps',
                                        style: AppTypography.titleMedium(
                                          color: AppColors.accentLime,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.chevron_right_rounded,
                                        color: AppColors.accentLime,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Divider(height: 1, color: AppColors.border),
                          // Camera Preference
                          InkWell(
                            onTap: () {
                              ref
                                  .read(preferFrontCameraProvider.notifier)
                                  .update((val) => !val);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 18),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Camera',
                                      style: AppTypography.titleMedium(
                                          fontSize: 16)),
                                  Text(
                                    preferFront ? 'Front' : 'Back',
                                    style: AppTypography.titleMedium(
                                      color: const Color(0xFFB4BBC0),
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Divider(height: 1, color: AppColors.border),
                          // Voice rep count
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Voice rep count',
                                    style: AppTypography.titleMedium(
                                        fontSize: 16)),
                                _DesignSwitch(
                                  value: voiceRepCount,
                                  onChanged: (val) {
                                    ref
                                        .read(voiceRepCountEnabledProvider
                                            .notifier)
                                        .state = val;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Section 2: ALERTS
                    Text(
                      'ALERTS',
                      style: AppTypography.caption(color: AppColors.textMuted)
                          .copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),

                    AppCard(
                      borderRadius: 18,
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Daily reminder',
                                    style: AppTypography.titleMedium(
                                        fontSize: 16)),
                                _DesignSwitch(
                                  value: dailyReminder,
                                  onChanged: (val) {
                                    ref
                                        .read(dailyReminderEnabledProvider
                                            .notifier)
                                        .state = val;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: AppColors.border),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Group activity',
                                    style: AppTypography.titleMedium(
                                        fontSize: 16)),
                                _DesignSwitch(
                                  value: groupActivity,
                                  onChanged: (val) {
                                    ref
                                        .read(groupActivityEnabledProvider
                                            .notifier)
                                        .state = val;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Section 3: ACCOUNT
                    Text(
                      'ACCOUNT',
                      style: AppTypography.caption(color: AppColors.textMuted)
                          .copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),

                    AppCard(
                      borderRadius: 18,
                      padding: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 18),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Email',
                                style: AppTypography.titleMedium(fontSize: 16)),
                            Text(
                              email,
                              style: AppTypography.bodyMedium(
                                color: const Color(0xFFB4BBC0),
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Log out button
              SizedBox(
                height: 56,
                child: OutlinedButton(
                  onPressed: () async {
                    await ref.read(authControllerProvider.notifier).signOut();
                    await ref
                        .read(preferencesServiceProvider)
                        .setSignedIn(false);
                    if (context.mounted) {
                      context.go(RoutePaths.login);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.warning, width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Log out',
                    style: AppTypography.titleMedium(
                      color: const Color(0xFFFFB794),
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesignSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _DesignSwitch({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 52,
        height: 32,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: value ? AppColors.accentLime : AppColors.borderSubtle,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: value ? AppColors.textOnAccent : AppColors.text,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
