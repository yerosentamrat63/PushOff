import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/primary_button.dart';
import 'groups_controller.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _nameController = TextEditingController();
  int _selectedPeriodIndex = 0;
  int _goalReps = 500;
  bool _isCreating = false;

  final _periods = ['Week', 'Month', 'Custom'];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateGroup() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a group name first'),
          backgroundColor: AppColors.warningBg,
        ),
      );
      return;
    }

    setState(() => _isCreating = true);
    final group =
        await ref.read(groupActionControllerProvider.notifier).createGroup(
              name: name,
              goal: _goalReps,
              period: _periods[_selectedPeriodIndex].toLowerCase(),
            );
    if (!mounted) return;
    setState(() => _isCreating = false);

    if (group != null) {
      context.pushReplacement(RoutePaths.groupDetail(group.id));
    } else {
      final error = ref.read(groupActionControllerProvider).errorMessage ??
          'Failed to create group';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.warningBg),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 16.0,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header: Back Button + "New group"
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
                            'New group',
                            style: AppTypography.heroNumber(fontSize: 36),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Group Name Field
                      Text(
                        'Group name',
                        style:
                            AppTypography.bodySmall(color: AppColors.textMuted)
                                .copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _nameController,
                        style: AppTypography.bodyLarge(),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _handleCreateGroup(),
                        scrollPadding: const EdgeInsets.only(bottom: 140),
                        decoration: InputDecoration(
                          hintText: 'e.g. Gym Rats',
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                const BorderSide(color: AppColors.borderLight),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                const BorderSide(color: AppColors.borderLight),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Goal Period Tabs
                      Text(
                        'Goal period',
                        style:
                            AppTypography.bodySmall(color: AppColors.textMuted)
                                .copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border, width: 1),
                        ),
                        child: Row(
                          children: List.generate(_periods.length, (index) {
                            final isSelected = _selectedPeriodIndex == index;
                            return Expanded(
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedPeriodIndex = index;
                                    if (index == 0) _goalReps = 500;
                                    if (index == 1) _goalReps = 1000;
                                    if (index == 2) _goalReps = 2500;
                                  });
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.accentLime
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    _periods[index],
                                    style: AppTypography.titleMedium(
                                      color: isSelected
                                          ? AppColors.textOnAccent
                                          : AppColors.textMuted,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Target Reps Counter Stepper
                      Text(
                        'Group goal (valid reps)',
                        style:
                            AppTypography.bodySmall(color: AppColors.textMuted)
                                .copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border, width: 1),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: () {
                                if (_goalReps > 50) {
                                  setState(() => _goalReps -= 50);
                                }
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: AppColors.borderLight, width: 1),
                                ),
                                alignment: Alignment.center,
                                child: const Text('−',
                                    style: TextStyle(
                                        fontSize: 26, color: AppColors.text)),
                              ),
                            ),
                            Text(
                              '$_goalReps',
                              style: AppTypography.heroNumber(
                                color: AppColors.text,
                                fontSize: 44,
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                setState(() => _goalReps += 50);
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: AppColors.borderLight, width: 1),
                                ),
                                alignment: Alignment.center,
                                child: const Text('+',
                                    style: TextStyle(
                                        fontSize: 26, color: AppColors.text)),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Dashed Share Note
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.borderSubtle,
                            width: 1,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: AppColors.accentLime,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "You'll get an invite code to share once the group is created.",
                                style: AppTypography.bodySmall(
                                        color: AppColors.textMuted)
                                    .copyWith(
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // Primary "Create group" Button
                      PrimaryButton(
                        label: _isCreating ? 'Creating...' : 'Create group',
                        height: 60,
                        borderRadius: 18,
                        onPressed: _isCreating ? null : _handleCreateGroup,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
