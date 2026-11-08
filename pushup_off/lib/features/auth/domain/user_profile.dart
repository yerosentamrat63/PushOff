class UserProfile {
  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;
  final int totalValidReps;
  final int streakDays;
  final int bestSet;
  final double avgForm;
  final DateTime createdAt;

  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.totalValidReps = 0,
    this.streakDays = 0,
    this.bestSet = 0,
    this.avgForm = 0.0,
    required this.createdAt,
  });

  String get initials {
    if (displayName.trim().isEmpty) return 'Y';
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
      'email': email,
      'photoUrl': photoUrl,
      'totalValidReps': totalValidReps,
      'streakDays': streakDays,
      'bestSet': bestSet,
      'avgForm': avgForm,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map, {String? uid}) {
    return UserProfile(
      uid: uid ?? map['uid'] as String? ?? '',
      displayName: map['displayName'] as String? ?? 'User',
      email: map['email'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      totalValidReps: (map['totalValidReps'] as num?)?.toInt() ?? 0,
      streakDays: (map['streakDays'] as num?)?.toInt() ?? 0,
      bestSet: (map['bestSet'] as num?)?.toInt() ?? 0,
      avgForm: (map['avgForm'] as num?)?.toDouble() ?? 0.0,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  UserProfile copyWith({
    String? displayName,
    String? email,
    String? photoUrl,
    int? totalValidReps,
    int? streakDays,
    int? bestSet,
    double? avgForm,
  }) {
    return UserProfile(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      totalValidReps: totalValidReps ?? this.totalValidReps,
      streakDays: streakDays ?? this.streakDays,
      bestSet: bestSet ?? this.bestSet,
      avgForm: avgForm ?? this.avgForm,
      createdAt: createdAt,
    );
  }
}

