import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/progress_bar.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/group_model.dart';
import 'groups_controller.dart';

class GroupsScreen extends ConsumerStatefulWidget {
  const GroupsScreen({super.key});

  @override
  ConsumerState<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends ConsumerState<GroupsScreen> {
  final _inviteCodeController = TextEditingController();
  bool _isJoining = false;

  @override
  void dispose() {
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _joinGroup() async {
    final code = _inviteCodeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter an invite code')),
      );
      return;
    }
    if (_isJoining) return;

    setState(() => _isJoining = true);
    final group = await ref
        .read(groupActionControllerProvider.notifier)
        .joinGroupByCode(code);
    if (!mounted) return;
    setState(() => _isJoining = false);

    if (group != null) {
      _inviteCodeController.clear();
      context.push(RoutePaths.groupDetail(group.id));
    } else {
      final error = ref.read(groupActionControllerProvider).errorMessage ??
          'Could not join group';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error, style: const TextStyle(color: Colors.white)),
          backgroundColor: AppColors.warningBg,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(userGroupsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with Title & Create Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Groups',
                    style: AppTypography.heroNumber(fontSize: 40),
                  ),
                  Semantics(
                    label: 'Create a new group challenge',
                    button: true,
                    child: InkWell(
                      onTap: () => context.push(RoutePaths.createGroup),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.accentLime,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.add_rounded,
                          color: AppColors.textOnAccent,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Invite code field with an inline join action.
              TextField(
                controller: _inviteCodeController,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _joinGroup(),
                style: AppTypography.bodyLarge(),
                decoration: InputDecoration(
                  hintText: 'Enter invite code (e.g. GYM-4K9X)',
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  suffixIcon: _isJoining
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.accentLime,
                            ),
                          ),
                        )
                      : TextButton(
                          onPressed: _joinGroup,
                          child: Text(
                            'Join',
                            style: AppTypography.titleMedium(
                              color: AppColors.accentLime,
                              fontSize: 16,
                            ),
                          ),
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.borderLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.borderLight),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: groupsAsync.when(
                  loading: () => const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.accentLime),
                  ),
                  error: (err, stack) => ListView(
                    children: [
                      AppCard(
                        borderRadius: 18,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const Icon(Icons.cloud_off_rounded,
                                color: AppColors.warning, size: 36),
                            const SizedBox(height: 10),
                            Text(
                              'Could not load groups',
                              style: AppTypography.titleMedium(),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              err.toString(),
                              style: AppTypography.caption(),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton(
                              onPressed: () => ref.refresh(userGroupsProvider),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.surface),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  data: (groups) {
                    if (groups.isEmpty) {
                      return ListView(
                        children: [
                          AppCard(
                            borderRadius: 20,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.accentLime.withOpacity(0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.groups_rounded,
                                    color: AppColors.accentLime,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No groups yet',
                                  style: AppTypography.titleLarge(fontSize: 20),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Create a challenge with friends or enter an invite code to join an active squad.',
                                  style: AppTypography.bodySmall(
                                      color: AppColors.textMuted),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                OutlinedButton(
                                  onPressed: () =>
                                      context.push(RoutePaths.createGroup),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                        color: AppColors.accentLime),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Text(
                                    'Create your first group',
                                    style: AppTypography.titleMedium(
                                      color: AppColors.accentLime,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: groups.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _GroupListItem(group: groups[index]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupListItem extends ConsumerWidget {
  final GroupModel group;

  const _GroupListItem({required this.group});

  String _ordinal(int value) {
    final mod100 = value % 100;
    if (mod100 >= 11 && mod100 <= 13) return '${value}th';
    switch (value % 10) {
      case 1:
        return '${value}st';
      case 2:
        return '${value}nd';
      case 3:
        return '${value}rd';
      default:
        return '${value}th';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(groupMembersProvider(group.id)).value ??
        const <GroupMemberModel>[];
    final currentUserId =
        ref.watch(currentUserProvider).value?.uid ?? 'user-yerosen-1';
    GroupMemberModel? currentMember;
    for (final member in members) {
      if (member.uid == currentUserId || member.uid == 'user-yerosen-1') {
        currentMember = member;
        break;
      }
    }

    final subtitle =
        '${group.totalRepsInPeriod} / ${group.goal} reps ${group.periodLabel}';
    final trailing = currentMember != null
        ? 'You: ${_ordinal(currentMember.rank)}'
        : group.daysLeftText;

    return Semantics(
      label:
          'Group ${group.name}, ${group.memberCount} members, $subtitle, $trailing',
      button: true,
      child: AppCard(
        onTap: () => context.push(RoutePaths.groupDetail(group.id)),
        borderRadius: 20,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    group.name,
                    style: AppTypography.titleLarge(fontSize: 20),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${group.memberCount} members',
                  style: AppTypography.bodySmall(color: AppColors.textMuted)
                      .copyWith(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ProgressBar(value: group.progressPercent, height: 8),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    subtitle,
                    style: AppTypography.bodySmall(color: AppColors.textMuted)
                        .copyWith(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  trailing,
                  style: AppTypography.titleMedium(
                      color: AppColors.accentLime, fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
