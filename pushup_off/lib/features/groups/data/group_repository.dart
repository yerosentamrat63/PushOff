import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/group_model.dart';

class GroupRepository {
  FirebaseFirestore? _firestore;
  bool _isFirebaseAvailable = false;

  final _groupsController = StreamController<List<GroupModel>>.broadcast();
  final List<GroupModel> _mockGroups = [];
  final Map<String, List<GroupMemberModel>> _mockMembers = {};

  GroupRepository() {
    _init();
  }

  void _init() {
    try {
      _firestore = FirebaseFirestore.instance;
      _isFirebaseAvailable = true;
    } catch (_) {
      _isFirebaseAvailable = false;
    }
    _setupInitialMockData();
  }

  void _setupInitialMockData() {
    final now = DateTime.now();

    final gymRats = GroupModel(
      id: 'gym-rats',
      name: 'Gym Rats',
      goal: 500,
      period: 'week',
      startsAt: now.subtract(const Duration(days: 4)),
      endsAt: now.add(const Duration(days: 3)),
      inviteCode: 'GYM-4K9X',
      memberIds: const [
        'u-dawit',
        'user-yerosen-1',
        'u-selam',
        'u-kebron',
        'u-hana'
      ],
      createdBy: 'u-dawit',
      totalRepsInPeriod: 320,
    );

    final dorm4b = GroupModel(
      id: 'dorm-4b',
      name: 'Dorm 4B',
      goal: 1000,
      period: 'month',
      startsAt: now.subtract(const Duration(days: 18)),
      endsAt: now.add(const Duration(days: 12)),
      inviteCode: 'DORM-8B2X',
      memberIds: const [
        'user-yerosen-1',
        'u-mike',
        'u-alex',
        'u-kebron',
        'u-sam',
        'u-david',
        'u-leo',
        'u-chris'
      ],
      createdBy: 'user-yerosen-1',
      totalRepsInPeriod: 680,
    );

    final a2sv = GroupModel(
      id: 'a2sv-crew',
      name: 'A2SV Crew',
      goal: 2500,
      period: 'month',
      startsAt: now.subtract(const Duration(days: 10)),
      endsAt: now.add(const Duration(days: 20)),
      inviteCode: 'A2SV-7K11',
      memberIds: const ['user-yerosen-1', 'u-dawit', 'u-selam', 'u-hana'],
      createdBy: 'u-selam',
      totalRepsInPeriod: 1840,
    );

    _mockGroups.addAll([gymRats, dorm4b, a2sv]);

    _mockMembers['gym-rats'] = [
      GroupMemberModel(
        uid: 'u-dawit',
        displayName: 'Dawit',
        repsInPeriod: 118,
        rank: 1,
        lastActive: now.subtract(const Duration(minutes: 15)),
      ),
      GroupMemberModel(
        uid: 'user-yerosen-1',
        displayName: 'Yerosen',
        repsInPeriod: 84,
        rank: 2,
        lastActive: now.subtract(const Duration(hours: 1)),
      ),
      GroupMemberModel(
        uid: 'u-selam',
        displayName: 'Selam',
        repsInPeriod: 62,
        rank: 3,
        lastActive: now.subtract(const Duration(hours: 3)),
      ),
      GroupMemberModel(
        uid: 'u-kebron',
        displayName: 'Kebron',
        repsInPeriod: 38,
        rank: 4,
        lastActive: now.subtract(const Duration(hours: 6)),
      ),
      GroupMemberModel(
        uid: 'u-hana',
        displayName: 'Hana',
        repsInPeriod: 18,
        rank: 5,
        lastActive: now.subtract(const Duration(days: 1)),
      ),
    ];

    _mockMembers['dorm-4b'] = [
      GroupMemberModel(
        uid: 'user-yerosen-1',
        displayName: 'Yerosen',
        repsInPeriod: 240,
        rank: 1,
        lastActive: now.subtract(const Duration(hours: 1)),
      ),
      GroupMemberModel(
        uid: 'u-mike',
        displayName: 'Mike',
        repsInPeriod: 185,
        rank: 2,
        lastActive: now.subtract(const Duration(hours: 2)),
      ),
      GroupMemberModel(
        uid: 'u-alex',
        displayName: 'Alex',
        repsInPeriod: 140,
        rank: 3,
        lastActive: now.subtract(const Duration(hours: 5)),
      ),
      GroupMemberModel(
        uid: 'u-kebron',
        displayName: 'Kebron',
        repsInPeriod: 115,
        rank: 4,
        lastActive: now.subtract(const Duration(hours: 8)),
      ),
      GroupMemberModel(
        uid: 'u-sam',
        displayName: 'Sam',
        repsInPeriod: 0,
        rank: 5,
        lastActive: now.subtract(const Duration(days: 2)),
      ),
      GroupMemberModel(
        uid: 'u-david',
        displayName: 'David',
        repsInPeriod: 0,
        rank: 6,
        lastActive: now.subtract(const Duration(days: 3)),
      ),
      GroupMemberModel(
        uid: 'u-leo',
        displayName: 'Leo',
        repsInPeriod: 0,
        rank: 7,
        lastActive: now.subtract(const Duration(days: 4)),
      ),
      GroupMemberModel(
        uid: 'u-chris',
        displayName: 'Chris',
        repsInPeriod: 0,
        rank: 8,
        lastActive: now.subtract(const Duration(days: 5)),
      ),
    ];

    _mockMembers['a2sv-crew'] = [
      GroupMemberModel(
        uid: 'u-selam',
        displayName: 'Selam',
        repsInPeriod: 620,
        rank: 1,
        lastActive: now.subtract(const Duration(minutes: 42)),
      ),
      GroupMemberModel(
        uid: 'user-yerosen-1',
        displayName: 'Yerosen',
        repsInPeriod: 490,
        rank: 2,
        lastActive: now.subtract(const Duration(hours: 1)),
      ),
      GroupMemberModel(
        uid: 'u-dawit',
        displayName: 'Dawit',
        repsInPeriod: 420,
        rank: 3,
        lastActive: now.subtract(const Duration(hours: 3)),
      ),
      GroupMemberModel(
        uid: 'u-hana',
        displayName: 'Hana',
        repsInPeriod: 310,
        rank: 4,
        lastActive: now.subtract(const Duration(hours: 6)),
      ),
    ];

    _groupsController.add(List.unmodifiable(_mockGroups));
  }

  Stream<List<GroupModel>> watchUserGroups(String userId) async* {
    if (_isFirebaseAvailable && _firestore != null) {
      yield* _firestore!
          .collection('groups')
          .where('memberIds', arrayContains: userId)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => GroupModel.fromMap(doc.data(), id: doc.id))
            .toList();
      });
      return;
    }
    yield List.unmodifiable(_mockGroups);
    yield* _groupsController.stream;
  }

  Stream<GroupModel?> watchGroup(String groupId) async* {
    if (_isFirebaseAvailable && _firestore != null) {
      yield* _firestore!
          .collection('groups')
          .doc(groupId)
          .snapshots()
          .map((doc) {
        if (!doc.exists || doc.data() == null) return null;
        return GroupModel.fromMap(doc.data()!, id: doc.id);
      });
      return;
    }

    try {
      yield _mockGroups.firstWhere((g) => g.id == groupId);
    } catch (_) {
      yield null;
    }

    yield* _groupsController.stream.map((groups) {
      try {
        return groups.firstWhere((g) => g.id == groupId);
      } catch (_) {
        return null;
      }
    });
  }

  Stream<List<GroupMemberModel>> watchGroupMembers(String groupId) async* {
    if (_isFirebaseAvailable && _firestore != null) {
      yield* _firestore!
          .collection('groups')
          .doc(groupId)
          .collection('members')
          .orderBy('repsInPeriod', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.asMap().entries.map((entry) {
          final idx = entry.key;
          final doc = entry.value;
          final data = doc.data();
          return GroupMemberModel.fromMap(data, uid: doc.id)
              .copyWithRank(idx + 1);
        }).toList();
      });
      return;
    }

    List<GroupMemberModel> currentMembers() =>
        List.unmodifiable(_mockMembers[groupId] ?? const <GroupMemberModel>[]);

    yield currentMembers();
    yield* _groupsController.stream.map((_) => currentMembers());
  }

  Future<GroupModel> createGroup({
    required String name,
    required int goal,
    required String period,
    required String userId,
    required String userName,
  }) async {
    final now = DateTime.now();
    final durationDays = period == 'week' ? 7 : (period == 'month' ? 30 : 14);
    final endsAt = now.add(Duration(days: durationDays));
    final inviteCode = _generateInviteCode(name);
    final groupId = 'grp-${DateTime.now().millisecondsSinceEpoch}';

    final newGroup = GroupModel(
      id: groupId,
      name: name.trim(),
      goal: goal,
      period: period,
      startsAt: now,
      endsAt: endsAt,
      inviteCode: inviteCode,
      memberIds: [userId],
      createdBy: userId,
      totalRepsInPeriod: 0,
    );

    if (_isFirebaseAvailable && _firestore != null) {
      await _firestore!.collection('groups').doc(groupId).set(newGroup.toMap());

      // Invite codes live in their own collection so group documents can stay
      // private to members. The code doc is looked up by exact id (never
      // listed), and maps back to a single group.
      try {
        await _firestore!.collection('inviteCodes').doc(inviteCode).set({
          'groupId': groupId,
          'ownerId': userId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        // Never leave an orphaned group without a usable code.
        await _firestore!.collection('groups').doc(groupId).delete();
        rethrow;
      }

      await _firestore!
          .collection('groups')
          .doc(groupId)
          .collection('members')
          .doc(userId)
          .set({
        'uid': userId,
        'displayName': userName,
        'repsInPeriod': 0,
        'rank': 1,
        'lastActive': now.toIso8601String(),
      });
    }

    _mockGroups.insert(0, newGroup);
    _mockMembers[groupId] = [
      GroupMemberModel(
        uid: userId,
        displayName: userName,
        repsInPeriod: 0,
        rank: 1,
        lastActive: now,
      ),
    ];
    _groupsController.add(List.unmodifiable(_mockGroups));

    return newGroup;
  }

  Future<GroupModel> joinGroupByCode({
    required String inviteCode,
    required String userId,
    required String userName,
  }) async {
    final cleanCode = inviteCode.trim().toUpperCase();

    if (_isFirebaseAvailable && _firestore != null) {
      // Groups are private; only the code doc is readable. It reveals the
      // group id, and the join update below is what grants membership.
      final codeDoc =
          await _firestore!.collection('inviteCodes').doc(cleanCode).get();
      if (!codeDoc.exists || codeDoc.data() == null) {
        throw Exception('Invalid group invite code: $cleanCode');
      }

      final groupId = codeDoc.data()!['groupId'] as String?;
      if (groupId == null) {
        throw Exception('Invalid group invite code: $cleanCode');
      }

      final groupRef = _firestore!.collection('groups').doc(groupId);

      // arrayUnion is idempotent; the rules only allow appending the caller.
      await groupRef.update({
        'memberIds': FieldValue.arrayUnion([userId]),
      });

      final doc = await groupRef.get();
      if (!doc.exists || doc.data() == null) {
        throw Exception('Invalid group invite code: $cleanCode');
      }

      final group = GroupModel.fromMap(doc.data()!, id: doc.id);
      if (!group.memberIds.contains(userId)) {
        throw Exception('Could not join group with code: $cleanCode');
      }

      // Only create the member row on first join; re-joining must not reset
      // the athlete's accumulated reps.
      final memberRef = groupRef.collection('members').doc(userId);
      final memberDoc = await memberRef.get();
      if (!memberDoc.exists) {
        await memberRef.set({
          'uid': userId,
          'displayName': userName,
          'repsInPeriod': 0,
          'rank': group.memberCount,
          'lastActive': DateTime.now().toIso8601String(),
        });
      }

      return group;
    } else {
      final index = _mockGroups
          .indexWhere((g) => g.inviteCode.toUpperCase() == cleanCode);
      if (index == -1) {
        throw Exception('Group not found for invite code: $cleanCode');
      }

      final existing = _mockGroups[index];
      if (!existing.memberIds.contains(userId)) {
        final updatedIds = [...existing.memberIds, userId];
        final updatedGroup = existing.copyWith(memberIds: updatedIds);
        _mockGroups[index] = updatedGroup;

        final members = _mockMembers[existing.id] ?? [];
        members.add(
          GroupMemberModel(
            uid: userId,
            displayName: userName,
            repsInPeriod: 0,
            rank: members.length + 1,
            lastActive: DateTime.now(),
          ),
        );
        _mockMembers[existing.id] = members;
        _groupsController.add(List.unmodifiable(_mockGroups));
        return updatedGroup;
      }
      return existing;
    }
  }

  Future<void> recordReps({
    required String userId,
    required int reps,
  }) async {
    if (reps <= 0) return;

    // Persist to Firestore when it is configured. Sessions themselves are
    // written by CloudSyncService; this keeps group and member tallies in sync.
    if (_isFirebaseAvailable && _firestore != null) {
      try {
        final groups = await _firestore!
            .collection('groups')
            .where('memberIds', arrayContains: userId)
            .get();

        for (final doc in groups.docs) {
          await doc.reference.update({
            'totalRepsInPeriod': FieldValue.increment(reps),
          });

          final memberRef = doc.reference.collection('members').doc(userId);
          final memberDoc = await memberRef.get();
          if (memberDoc.exists) {
            await memberRef.update({
              'repsInPeriod': FieldValue.increment(reps),
              'lastActive': DateTime.now().toIso8601String(),
            });
          } else {
            await memberRef.set({
              'uid': userId,
              'displayName': 'Athlete',
              'repsInPeriod': reps,
              'rank': 0,
              'lastActive': DateTime.now().toIso8601String(),
            });
          }
        }
      } catch (_) {
        // Local history is already saved; do not fail the set on a sync error.
      }
    }

    // Update in memory mock groups
    for (int i = 0; i < _mockGroups.length; i++) {
      final g = _mockGroups[i];
      if (g.memberIds.contains(userId)) {
        _mockGroups[i] = g.copyWith(
          totalRepsInPeriod: g.totalRepsInPeriod + reps,
        );

        final members = _mockMembers[g.id];
        if (members != null) {
          final mIdx = members.indexWhere((m) => m.uid == userId);
          if (mIdx != -1) {
            final old = members[mIdx];
            members[mIdx] = GroupMemberModel(
              uid: old.uid,
              displayName: old.displayName,
              photoUrl: old.photoUrl,
              repsInPeriod: old.repsInPeriod + reps,
              rank: old.rank,
              lastActive: DateTime.now(),
            );
            // Re-sort members by reps
            members.sort((a, b) => b.repsInPeriod.compareTo(a.repsInPeriod));
            for (int r = 0; r < members.length; r++) {
              members[r] = GroupMemberModel(
                uid: members[r].uid,
                displayName: members[r].displayName,
                photoUrl: members[r].photoUrl,
                repsInPeriod: members[r].repsInPeriod,
                rank: r + 1,
                lastActive: members[r].lastActive,
              );
            }
          }
        }
      }
    }
    _groupsController.add(List.unmodifiable(_mockGroups));
  }

  String _generateInviteCode(String groupName) {
    final prefix =
        groupName.trim().replaceAll(RegExp(r'[^a-zA-Z]'), '').toUpperCase();
    final cleanPrefix = prefix.length >= 3 ? prefix.substring(0, 3) : 'OFF';
    const chars = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
    final random = Random.secure();
    // Six random characters after the prefix (~1e9 combinations) make codes
    // impractical to guess even though the lookup endpoint is readable.
    final suffix =
        List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
    return '$cleanPrefix-$suffix';
  }

  void dispose() {
    _groupsController.close();
  }
}

extension on GroupMemberModel {
  GroupMemberModel copyWithRank(int newRank) {
    return GroupMemberModel(
      uid: uid,
      displayName: displayName,
      photoUrl: photoUrl,
      repsInPeriod: repsInPeriod,
      rank: newRank,
      lastActive: lastActive,
    );
  }
}
