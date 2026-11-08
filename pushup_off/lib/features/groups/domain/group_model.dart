import 'package:intl/intl.dart';

class GroupModel {
  final String id;
  final String name;
  final int goal;
  final String period; // 'week', 'month', 'custom'
  final DateTime startsAt;
  final DateTime endsAt;
  final String inviteCode;
  final List<String> memberIds;
  final String createdBy;
  final int totalRepsInPeriod;

  const GroupModel({
    required this.id,
    required this.name,
    required this.goal,
    required this.period,
    required this.startsAt,
    required this.endsAt,
    required this.inviteCode,
    required this.memberIds,
    required this.createdBy,
    this.totalRepsInPeriod = 0,
  });

  int get memberCount => memberIds.length;

  double get progressPercent {
    if (goal <= 0) return 0.0;
    return (totalRepsInPeriod / goal).clamp(0.0, 1.0);
  }

  int get remainingReps => (goal - totalRepsInPeriod).clamp(0, goal);

  String get daysLeftText {
    final now = DateTime.now();
    final remaining = endsAt.difference(now);
    if (remaining.isNegative) return 'Ended';

    // Round up so a freshly created 7-day group reads "7 days left" rather
    // than "6 days left".
    final diff = (remaining.inMinutes / (60 * 24)).ceil();
    if (diff <= 0) return 'Ending today';
    if (diff == 1) return '1 day left';
    return '$diff days left';
  }

  String get periodLabel {
    if (period == 'week') return 'this week';
    if (period == 'month') return 'this month';
    return 'this challenge';
  }

  String get formattedPeriodGoal {
    return '${NumberFormat('#,###').format(goal)} reps $periodLabel';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'goal': goal,
      'period': period,
      'startsAt': startsAt.toIso8601String(),
      'endsAt': endsAt.toIso8601String(),
      'inviteCode': inviteCode,
      'memberIds': memberIds,
      'createdBy': createdBy,
      'totalRepsInPeriod': totalRepsInPeriod,
    };
  }

  factory GroupModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return GroupModel(
      id: id ?? map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Push-Up Squad',
      goal: (map['goal'] as num?)?.toInt() ?? 500,
      period: map['period'] as String? ?? 'week',
      startsAt: map['startsAt'] != null
          ? DateTime.tryParse(map['startsAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      endsAt: map['endsAt'] != null
          ? DateTime.tryParse(map['endsAt'] as String) ??
              DateTime.now().add(const Duration(days: 7))
          : DateTime.now().add(const Duration(days: 7)),
      inviteCode: map['inviteCode'] as String? ?? 'PUSH-001',
      memberIds: (map['memberIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdBy: map['createdBy'] as String? ?? '',
      totalRepsInPeriod: (map['totalRepsInPeriod'] as num?)?.toInt() ?? 0,
    );
  }

  GroupModel copyWith({
    String? name,
    int? goal,
    String? period,
    DateTime? startsAt,
    DateTime? endsAt,
    String? inviteCode,
    List<String>? memberIds,
    String? createdBy,
    int? totalRepsInPeriod,
  }) {
    return GroupModel(
      id: id,
      name: name ?? this.name,
      goal: goal ?? this.goal,
      period: period ?? this.period,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      inviteCode: inviteCode ?? this.inviteCode,
      memberIds: memberIds ?? this.memberIds,
      createdBy: createdBy ?? this.createdBy,
      totalRepsInPeriod: totalRepsInPeriod ?? this.totalRepsInPeriod,
    );
  }
}

class GroupMemberModel {
  final String uid;
  final String displayName;
  final String? photoUrl;
  final int repsInPeriod;
  final int rank;
  final DateTime lastActive;

  const GroupMemberModel({
    required this.uid,
    required this.displayName,
    this.photoUrl,
    required this.repsInPeriod,
    required this.rank,
    required this.lastActive,
  });

  String get initials {
    if (displayName.trim().isEmpty) return 'U';
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return displayName.trim().substring(0, 1).toUpperCase();
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'repsInPeriod': repsInPeriod,
      'rank': rank,
      'lastActive': lastActive.toIso8601String(),
    };
  }

  factory GroupMemberModel.fromMap(Map<String, dynamic> map, {String? uid}) {
    return GroupMemberModel(
      uid: uid ?? map['uid'] as String? ?? '',
      displayName: map['displayName'] as String? ?? 'Member',
      photoUrl: map['photoUrl'] as String?,
      repsInPeriod: (map['repsInPeriod'] as num?)?.toInt() ?? 0,
      rank: (map['rank'] as num?)?.toInt() ?? 99,
      lastActive: map['lastActive'] != null
          ? DateTime.tryParse(map['lastActive'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
