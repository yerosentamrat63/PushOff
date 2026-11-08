import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import 'package:pushup_off/features/workout/domain/models/rep_counter_output.dart';
import '../../groups/domain/group_model.dart';
import '../../groups/presentation/groups_controller.dart';
import 'controllers/workout_history_controller.dart';
import 'controllers/workout_session_controller.dart';

class SetSummaryScreen extends ConsumerStatefulWidget {
  const SetSummaryScreen({super.key});

  @override
  ConsumerState<SetSummaryScreen> createState() => _SetSummaryScreenState();
}

class _SetSummaryScreenState extends ConsumerState<SetSummaryScreen> {
  bool _isSaving = false;

  Future<void> _saveAndExit({required bool anotherSet}) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final summary = ref.read(lastCompletedSetProvider);
    if (summary != null) {
      await ref
          .read(workoutHistoryControllerProvider.notifier)
          .saveCompletedSet(summary);
    }

    if (!mounted) return;
    if (anotherSet) {
      context.push(RoutePaths.setup);
    } else {
      context.go(RoutePaths.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(lastCompletedSetProvider);
    final groups = ref.watch(userGroupsProvider).value ?? const <GroupModel>[];
    final groupNames = groups.map((group) => group.name).take(2).join(' and ');
    final extraGroups =
        groups.length > 2 ? ' and ${groups.length - 2} more' : '';

    // Use live session data if available, fallback to design reference mock
    final validReps = summary?.validReps ?? 18;
    final rejectedReps = summary?.rejectedReps ?? 3;
    final formScore =
        summary != null ? summary.formScore.toStringAsFixed(0) : '91';
    final durationText = summary?.formattedDuration ?? '1:04';
    final addedToGroupsText = validReps <= 0
        ? 'No valid reps added to groups this set'
        : (groups.isEmpty
            ? 'Saved $validReps valid reps'
            : 'Added $validReps reps to $groupNames$extraGroups');

    final rejectedList = summary?.rejectedRepsList ??
        const [
          RejectedRepDetail(
            repNumber: 7,
            reason: RejectionReason.notDeepEnough,
            detail: 'Elbow 118°',
            timestamp: null,
          ),
          RejectedRepDetail(
            repNumber: 13,
            reason: RejectionReason.hipsSagging,
            detail: 'Body 158°',
            timestamp: null,
          ),
          RejectedRepDetail(
            repNumber: 19,
            reason: RejectionReason.noLockout,
            detail: 'Elbow 151°',
            timestamp: null,
          ),
        ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Set complete',
                    style: AppTypography.bodySmall(color: AppColors.textMuted)
                        .copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Nice set',
                    style: AppTypography.heroNumber(fontSize: 40),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Valid Reps vs Rejected Hero Row
              Row(
                children: [
                  Expanded(
                    child: AppCard(
                      borderRadius: 20,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Valid reps',
                              style: AppTypography.caption(
                                  color: AppColors.textMuted)),
                          const SizedBox(height: 4),
                          Text(
                            '$validReps',
                            style: AppTypography.heroNumber(
                              color: AppColors.accentLime,
                              fontSize: 72,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppCard(
                      borderRadius: 20,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Rejected',
                              style: AppTypography.caption(
                                  color: AppColors.textMuted)),
                          const SizedBox(height: 4),
                          Text(
                            '$rejectedReps',
                            style: AppTypography.heroNumber(
                              color: AppColors.warning,
                              fontSize: 72,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Form Score & Duration Row
              Row(
                children: [
                  Expanded(
                    child: AppCard(
                      borderRadius: 16,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Form score',
                              style: AppTypography.bodySmall(
                                  color: AppColors.textMuted)),
                          Text(formScore, style: AppTypography.displaySmall()),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppCard(
                      borderRadius: 16,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Time',
                              style: AppTypography.bodySmall(
                                  color: AppColors.textMuted)),
                          Text(durationText,
                              style: AppTypography.displaySmall()),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // "Why reps were rejected" List
              Text(
                'Why reps were rejected',
                style: AppTypography.titleLarge(fontSize: 18),
              ),
              const SizedBox(height: 10),

              AppCard(
                borderRadius: 18,
                padding: EdgeInsets.zero,
                child: rejectedList.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            'Perfect set! Zero reps rejected.',
                            style: AppTypography.bodyMedium(
                                color: AppColors.accentLime),
                          ),
                        ),
                      )
                    : Column(
                        children: List.generate(rejectedList.length, (index) {
                          final item = rejectedList[index];
                          final isLast = index == rejectedList.length - 1;
                          return Column(
                            children: [
                              _RejectionSummaryRow(
                                reason:
                                    'Rep ${item.repNumber}: ${item.reason.displayTitle.toLowerCase()}',
                                metric: item.detail,
                              ),
                              if (!isLast)
                                const Divider(
                                    height: 1, color: AppColors.border),
                            ],
                          );
                        }),
                      ),
              ),

              const SizedBox(height: 14),

              // Social progress badge
              AppCard(
                borderRadius: 16,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    const Icon(
                      Icons.group_outlined,
                      color: AppColors.accentLime,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        addedToGroupsText,
                        style: AppTypography.bodyMedium(
                            color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Bottom Buttons
              PrimaryButton(
                label: 'Save and finish',
                height: 60,
                borderRadius: 18,
                isLoading: _isSaving,
                onPressed:
                    _isSaving ? null : () => _saveAndExit(anotherSet: false),
              ),
              const SizedBox(height: 10),
              SecondaryButton(
                label: 'Another set',
                height: 52,
                borderRadius: 16,
                onPressed:
                    _isSaving ? null : () => _saveAndExit(anotherSet: true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RejectionSummaryRow extends StatelessWidget {
  final String reason;
  final String metric;

  const _RejectionSummaryRow({
    required this.reason,
    required this.metric,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              reason,
              style: AppTypography.titleMedium(fontSize: 16),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              metric,
              style: AppTypography.titleMedium(
                color: const Color(0xFFFFB794),
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
