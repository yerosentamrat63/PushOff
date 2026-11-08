import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/progress_bar.dart';
import '../../auth/presentation/auth_controller.dart';
import 'groups_controller.dart';

class GroupDetailScreen extends ConsumerWidget {
  final String groupId;

  const GroupDetailScreen({
    super.key,
    this.groupId = 'gym-rats',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(groupDetailProvider(groupId));
    final membersAsync = ref.watch(groupMembersProvider(groupId));
    final currentUser = ref.watch(currentUserProvider).value;

    final group = groupAsync.value;
    final members = membersAsync.value ?? [];

    final groupName = group?.name ?? 'Gym Rats';
    final goal = group?.goal ?? 500;
    final totalReps = group?.totalRepsInPeriod ?? 320;
    final progress = group?.progressPercent ?? 0.64;
    final daysLeft = group?.daysLeftText ?? '3 days left';
    final inviteCode = group?.inviteCode ?? 'GYM-4K9X';
    final periodName = group?.period == 'month'
        ? 'Monthly goal'
        : group?.period == 'custom'
            ? 'Custom goal'
            : 'Weekly goal';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          children: [
            // Top Header: Back Button + Group Name
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
                Expanded(
                  child: Text(
                    groupName,
                    style: AppTypography.heroNumber(fontSize: 36),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Hero Goal Card
            AppCard(
              borderRadius: 22,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        periodName,
                        style:
                            AppTypography.bodySmall(color: AppColors.textMuted)
                                .copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        daysLeft,
                        style:
                            AppTypography.bodySmall(color: AppColors.textMuted)
                                .copyWith(fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$totalReps',
                        style: AppTypography.heroNumber(
                          color: AppColors.accentLime,
                          fontSize: 64,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '/ $goal reps',
                        style: AppTypography.displaySmall(
                          color: AppColors.textMuted,
                          fontSize: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ProgressBar(value: progress, height: 8),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Dashed Invite Code Box
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.borderSubtle,
                  width: 1,
                  style: BorderStyle.solid,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Invite code',
                    style: AppTypography.bodyMedium(color: AppColors.textMuted)
                        .copyWith(fontSize: 14),
                  ),
                  Row(
                    children: [
                      Text(
                        inviteCode,
                        style: AppTypography.buttonUppercase(
                          color: AppColors.text,
                          fontSize: 20,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded,
                            color: AppColors.accentLime, size: 20),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: inviteCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Invite code $inviteCode copied to clipboard'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // "Squad Rankings" Section Header
            Text(
              'Squad Rankings',
              style: AppTypography.titleLarge(fontSize: 18),
            ),
            const SizedBox(height: 10),

            // Squad Leaderboard List
            AppCard(
              borderRadius: 18,
              padding: EdgeInsets.zero,
              child: Column(
                children: members.isNotEmpty
                    ? members.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final member = entry.value;
                        final isCurrentUser = member.uid == currentUser?.uid ||
                            member.uid == 'user-yerosen-1' ||
                            member.displayName == 'Yerosen';

                        return Column(
                          children: [
                            if (idx > 0)
                              const Divider(height: 1, color: AppColors.border),
                            _SquadMemberRankRow(
                              rank: member.rank,
                              name: isCurrentUser
                                  ? 'You (${member.displayName})'
                                  : member.displayName,
                              reps: member.repsInPeriod,
                              highlightRank: member.rank <= 3,
                              isCurrentUser: isCurrentUser,
                            ),
                          ],
                        );
                      }).toList()
                    : const [
                        _SquadMemberRankRow(
                          rank: 1,
                          name: 'Dawit',
                          reps: 118,
                          highlightRank: true,
                        ),
                        Divider(height: 1, color: AppColors.border),
                        _SquadMemberRankRow(
                          rank: 2,
                          name: 'You (Yerosen)',
                          reps: 84,
                          highlightRank: true,
                          isCurrentUser: true,
                        ),
                        Divider(height: 1, color: AppColors.border),
                        _SquadMemberRankRow(
                          rank: 3,
                          name: 'Selam',
                          reps: 62,
                        ),
                      ],
              ),
            ),

            const SizedBox(height: 14),

            // Live Activity Feed Card
            AppCard(
              borderRadius: 16,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: members.isEmpty || members.first.repsInPeriod <= 0
                  ? Text(
                      'No sets logged yet — be the first to get on the board.',
                      style: AppTypography.bodySmall(color: AppColors.textMuted)
                          .copyWith(fontSize: 14),
                    )
                  : RichText(
                      text: TextSpan(
                        style: AppTypography.bodySmall(
                          color: AppColors.textMuted,
                        ).copyWith(fontSize: 14),
                        children: [
                          TextSpan(
                            text:
                                '${members.first.displayName.isEmpty ? 'Athlete' : members.first.displayName} ',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.text,
                            ),
                          ),
                          const TextSpan(text: 'leads with '),
                          TextSpan(
                            text: '${members.first.repsInPeriod} reps',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.accentLime,
                            ),
                          ),
                          TextSpan(
                            text:
                                ' • active ${_relativeTime(members.first.lastActive)}',
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

String _relativeTime(DateTime? time) {
  if (time == null) return 'just now';
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}

class _SquadMemberRankRow extends StatelessWidget {
  final int rank;
  final String name;
  final int reps;
  final bool highlightRank;
  final bool isCurrentUser;

  const _SquadMemberRankRow({
    required this.rank,
    required this.name,
    required this.reps,
    this.highlightRank = false,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isCurrentUser ? const Color(0x14D4FF3A) : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '$rank',
              style: AppTypography.titleMedium(
                color: isCurrentUser
                    ? AppColors.accentLime
                    : (highlightRank ? AppColors.text : AppColors.textMuted),
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: AppTypography.titleMedium(
                color: isCurrentUser ? AppColors.accentLime : AppColors.text,
                fontSize: 16,
              ),
            ),
          ),
          Text(
            '$reps',
            style: AppTypography.heroNumber(
              color: isCurrentUser ? AppColors.accentLime : AppColors.text,
              fontSize: 22,
            ),
          ),
        ],
      ),
    );
  }
}
