class DayActivity {
  final String dayLabel; // e.g. 'M', 'T', 'W', 'T', 'F', 'S', 'S'
  final DateTime date;
  final int validReps;
  final bool isToday;

  const DayActivity({
    required this.dayLabel,
    required this.date,
    required this.validReps,
    required this.isToday,
  });
}

class ProfileStatsData {
  final int totalValidReps;
  final int bestSetReps;
  final double averageFormScore;
  final List<DayActivity> last7Days;

  const ProfileStatsData({
    required this.totalValidReps,
    required this.bestSetReps,
    required this.averageFormScore,
    required this.last7Days,
  });

  int get maxDayReps {
    if (last7Days.isEmpty) return 1;
    final max = last7Days.map((d) => d.validReps).reduce((a, b) => a > b ? a : b);
    return max > 0 ? max : 1;
  }
}

