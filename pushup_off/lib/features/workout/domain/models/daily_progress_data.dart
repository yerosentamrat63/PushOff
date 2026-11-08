class DailyProgressData {
  final int todayValidReps;
  final int dailyGoal;
  final int streakDays;

  const DailyProgressData({
    required this.todayValidReps,
    required this.dailyGoal,
    required this.streakDays,
  });

  double get progressPercent {
    if (dailyGoal <= 0) return 0.0;
    final pct = todayValidReps / dailyGoal;
    return pct.clamp(0.0, 1.0);
  }

  bool get isGoalMet => todayValidReps >= dailyGoal;

  int get remainingReps => (dailyGoal - todayValidReps).clamp(0, dailyGoal);

  DailyProgressData copyWith({
    int? todayValidReps,
    int? dailyGoal,
    int? streakDays,
  }) {
    return DailyProgressData(
      todayValidReps: todayValidReps ?? this.todayValidReps,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      streakDays: streakDays ?? this.streakDays,
    );
  }
}

