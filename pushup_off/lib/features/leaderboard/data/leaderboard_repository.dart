import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/leaderboard_entry.dart';
import '../../groups/data/group_repository.dart';

class LeaderboardRepository {
  FirebaseFirestore? _firestore;
  bool _isFirebaseAvailable = false;
  final GroupRepository _groupRepo;

  LeaderboardRepository(this._groupRepo) {
    _init();
  }

  void _init() {
    try {
      _firestore = FirebaseFirestore.instance;
      _isFirebaseAvailable = true;
    } catch (_) {
      _isFirebaseAvailable = false;
    }
  }

  Stream<List<LeaderboardEntry>> watchLeaderboard({
    required LeaderboardPeriod period,
    required String groupFilter, // 'all' or groupId
    String? currentUserId,
  }) {
    // If filtering by a specific group, delegate directly to that group's member stream
    if (groupFilter != 'all') {
      return _groupRepo.watchGroupMembers(groupFilter).map((members) {
        return members.map((m) {
          return LeaderboardEntry(
            rank: m.rank,
            uid: m.uid,
            name: m.displayName,
            reps: m.repsInPeriod,
            isCurrentUser: m.uid == currentUserId || m.uid == 'user-yerosen-1',
          );
        }).toList();
      });
    }

    // Global / Multi-period Leaderboard
    if (_isFirebaseAvailable && _firestore != null) {
      if (period != LeaderboardPeriod.allTime) {
        final since = _periodStart(period);
        return _firestore!
            .collection('sessions')
            .where('timestamp', isGreaterThanOrEqualTo: since)
            .limit(1000)
            .snapshots()
            .asyncMap((snapshot) async {
          final repsByUser = <String, int>{};
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final uid = data['userId'] as String?;
            if (uid == null) continue;
            final reps = (data['validReps'] as num?)?.toInt() ?? 0;
            repsByUser[uid] = (repsByUser[uid] ?? 0) + reps;
          }

          final sorted = repsByUser.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          final entries = <LeaderboardEntry>[];
          for (var i = 0; i < sorted.length; i++) {
            final uid = sorted[i].key;
            var name = 'Athlete';
            try {
              final userDoc = await _firestore!.collection('users').doc(uid).get();
              name = userDoc.data()?['displayName'] as String? ?? name;
            } catch (_) {
              // Fall back to a generic display name.
            }
            entries.add(LeaderboardEntry(
              rank: i + 1,
              uid: uid,
              name: name,
              reps: sorted[i].value,
              isCurrentUser: uid == currentUserId,
            ));
          }
          return entries;
        });
      }

      return _firestore!
          .collection('users')
          .orderBy('totalValidReps', descending: true)
          .limit(50)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.asMap().entries.map((entry) {
          final idx = entry.key;
          final doc = entry.value;
          final data = doc.data();
          final reps = (data['totalValidReps'] as num?)?.toInt() ?? 0;
          return LeaderboardEntry(
            rank: idx + 1,
            uid: doc.id,
            name: data['displayName'] as String? ?? 'Athlete',
            reps: reps,
            isCurrentUser: doc.id == currentUserId,
          );
        }).toList();
      });
    }

    // High fidelity mock entries matching the design
    final multiplier = period == LeaderboardPeriod.week
        ? 1.0
        : (period == LeaderboardPeriod.month ? 3.5 : 10.0);

    final mock = [
      LeaderboardEntry(
        rank: 1,
        uid: 'u-dawit',
        name: 'Dawit',
        reps: (118 * multiplier).round(),
        isCurrentUser: false,
      ),
      LeaderboardEntry(
        rank: 2,
        uid: 'user-yerosen-1',
        name: 'Yerosen',
        reps: (84 * multiplier).round(),
        isCurrentUser: true,
      ),
      LeaderboardEntry(
        rank: 3,
        uid: 'u-selam',
        name: 'Selam',
        reps: (62 * multiplier).round(),
        isCurrentUser: false,
      ),
      LeaderboardEntry(
        rank: 4,
        uid: 'u-kebron',
        name: 'Kebron',
        reps: (38 * multiplier).round(),
        isCurrentUser: false,
      ),
      LeaderboardEntry(
        rank: 5,
        uid: 'u-hana',
        name: 'Hana',
        reps: (18 * multiplier).round(),
        isCurrentUser: false,
      ),
      LeaderboardEntry(
        rank: 6,
        uid: 'u-sam',
        name: 'Samuel',
        reps: (14 * multiplier).round(),
        isCurrentUser: false,
      ),
      LeaderboardEntry(
        rank: 7,
        uid: 'u-marta',
        name: 'Marta',
        reps: (10 * multiplier).round(),
        isCurrentUser: false,
      ),
    ];

    return Stream.value(mock);
  }

  DateTime _periodStart(LeaderboardPeriod period) {
    final now = DateTime.now();
    if (period == LeaderboardPeriod.week) {
      final today = DateTime(now.year, now.month, now.day);
      return today.subtract(Duration(days: today.weekday - 1));
    }
    return DateTime(now.year, now.month, 1);
  }
}

