import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../domain/leaderboard_entry.dart';
import 'leaderboard_controller.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  final _periodOptions = [
    LeaderboardPeriod.week,
    LeaderboardPeriod.month,
    LeaderboardPeriod.allTime,
  ];

  final _filterOptions = [
    {'label': 'Everyone', 'id': 'all'},
    {'label': 'Gym Rats', 'id': 'gym-rats'},
    {'label': 'Dorm 4B', 'id': 'dorm-4b'},
  ];

  @override
  Widget build(BuildContext context) {
    final selectedPeriod = ref.watch(selectedLeaderboardPeriodProvider);
    final selectedFilter = ref.watch(selectedGroupFilterProvider);
    final entriesAsync = ref.watch(leaderboardEntriesProvider);

    final entries = entriesAsync.value ?? [];

    LeaderboardEntry? rank1;
    LeaderboardEntry? rank2;
    LeaderboardEntry? rank3;
    List<LeaderboardEntry> remaining = [];

    if (entries.isNotEmpty) {
      rank1 = entries[0];
      if (entries.length > 1) rank2 = entries[1];
      if (entries.length > 2) rank3 = entries[2];
      if (entries.length > 3) remaining = entries.sublist(3);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          children: [
            // Title & Subtitle
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Leaderboard',
                  style: AppTypography.heroNumber(fontSize: 40),
                ),
                const SizedBox(height: 2),
                Text(
                  'Only form-verified reps count',
                  style: AppTypography.bodySmall(color: AppColors.textMuted).copyWith(fontSize: 14),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Time Period Selector
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Row(
                children: _periodOptions.map((period) {
                  final isSelected = selectedPeriod == period;
                  return Expanded(
                    child: InkWell(
                      onTap: () {
                        ref.read(selectedLeaderboardPeriodProvider.notifier).state = period;
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.accentLime : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          period.label,
                          style: AppTypography.titleMedium(
                            fontSize: 15,
                            color: isSelected ? AppColors.textOnAccent : const Color(0xFFB4BBC0),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 12),

            // Filter Chips
            Row(
              children: _filterOptions.map((filter) {
                final isSelected = selectedFilter == filter['id'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: InkWell(
                    onTap: () {
                      ref.read(selectedGroupFilterProvider.notifier).state = filter['id']!;
                    },
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.text : Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                        border: isSelected ? null : Border.all(color: AppColors.borderLight, width: 1),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        filter['label']!,
                        style: AppTypography.titleMedium(
                          fontSize: 14,
                          color: isSelected ? AppColors.background : const Color(0xFFB4BBC0),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Top 3 Podium
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Rank 2
                Expanded(
                  child: _PodiumColumn(
                    rank: '2',
                    name: rank2 != null
                        ? (rank2.isCurrentUser ? 'You' : rank2.name)
                        : 'Yerosen',
                    reps: rank2 != null ? '${rank2.reps}' : '84',
                    height: 118,
                    isWinner: false,
                  ),
                ),
                const SizedBox(width: 10),
                // Rank 1: Winner (Lime)
                Expanded(
                  child: _PodiumColumn(
                    rank: '1',
                    name: rank1 != null
                        ? (rank1.isCurrentUser ? 'You' : rank1.name)
                        : 'Dawit',
                    reps: rank1 != null ? '${rank1.reps}' : '118',
                    height: 150,
                    isWinner: true,
                  ),
                ),
                const SizedBox(width: 10),
                // Rank 3
                Expanded(
                  child: _PodiumColumn(
                    rank: '3',
                    name: rank3 != null
                        ? (rank3.isCurrentUser ? 'You' : rank3.name)
                        : 'Selam',
                    reps: rank3 != null ? '${rank3.reps}' : '62',
                    height: 100,
                    isWinner: false,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Additional Ranks Card
            AppCard(
              borderRadius: 18,
              padding: EdgeInsets.zero,
              child: Column(
                children: remaining.isNotEmpty
                    ? remaining.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final item = entry.value;
                        return _LeaderboardListRow(
                          rank: '${item.rank}',
                          name: item.isCurrentUser ? 'You (${item.name})' : item.name,
                          form: 'Verified reps',
                          reps: '${item.reps}',
                          showDivider: idx < remaining.length - 1,
                        );
                      }).toList()
                    : const [
                        _LeaderboardListRow(
                          rank: '4',
                          name: 'Kebron',
                          form: 'Form 84',
                          reps: '38',
                          showDivider: true,
                        ),
                        _LeaderboardListRow(
                          rank: '5',
                          name: 'Hana',
                          form: 'Form 90',
                          reps: '18',
                          showDivider: false,
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

class _PodiumColumn extends StatelessWidget {
  final String rank;
  final String name;
  final String reps;
  final double height;
  final bool isWinner;

  const _PodiumColumn({
    required this.rank,
    required this.name,
    required this.reps,
    required this.height,
    required this.isWinner,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        color: isWinner ? AppColors.accentLime : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: isWinner ? null : Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            rank,
            style: AppTypography.heroNumber(
              color: isWinner ? AppColors.textOnAccent : AppColors.textMuted,
              fontSize: isWinner ? 32 : 26,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            name,
            style: AppTypography.titleMedium(
              color: isWinner ? AppColors.textOnAccent : AppColors.text,
              fontSize: 15,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '$reps reps',
            style: AppTypography.bodySmall(
              color: isWinner ? AppColors.textOnAccent.withOpacity(0.8) : AppColors.textMuted,
            ).copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardListRow extends StatelessWidget {
  final String rank;
  final String name;
  final String form;
  final String reps;
  final bool showDivider;

  const _LeaderboardListRow({
    required this.rank,
    required this.name,
    required this.form,
    required this.reps,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: AppColors.border, width: 1))
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              rank,
              style: AppTypography.titleMedium(color: AppColors.textMuted, fontSize: 16),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTypography.titleMedium(fontSize: 16)),
                const SizedBox(height: 2),
                Text(form, style: AppTypography.bodySmall(color: AppColors.textMuted).copyWith(fontSize: 12)),
              ],
            ),
          ),
          Text(
            reps,
            style: AppTypography.heroNumber(
              color: AppColors.text,
              fontSize: 22,
            ),
          ),
        ],
      ),
    );
  }
}
