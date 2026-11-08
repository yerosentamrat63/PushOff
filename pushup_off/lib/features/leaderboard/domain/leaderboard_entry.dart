enum LeaderboardPeriod {
  week,
  month,
  allTime,
}

extension LeaderboardPeriodExt on LeaderboardPeriod {
  String get label {
    switch (this) {
      case LeaderboardPeriod.week:
        return 'This Week';
      case LeaderboardPeriod.month:
        return 'This Month';
      case LeaderboardPeriod.allTime:
        return 'All Time';
    }
  }
}

class LeaderboardEntry {
  final int rank;
  final String uid;
  final String name;
  final int reps;
  final String? avatarUrl;
  final bool isCurrentUser;
  final int streakDays;

  const LeaderboardEntry({
    required this.rank,
    required this.uid,
    required this.name,
    required this.reps,
    this.avatarUrl,
    this.isCurrentUser = false,
    this.streakDays = 0,
  });

  String get initials {
    if (name.trim().isEmpty) return 'U';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.trim().substring(0, 1).toUpperCase();
  }
}

