import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/group_repository.dart';
import '../domain/group_model.dart';
import '../../auth/presentation/auth_controller.dart';

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  final repo = GroupRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

final userGroupsProvider = StreamProvider<List<GroupModel>>((ref) {
  final repo = ref.watch(groupRepositoryProvider);
  final user = ref.watch(currentUserProvider).value;
  final uid = user?.uid ?? 'user-yerosen-1';
  return repo.watchUserGroups(uid);
});

final groupDetailProvider = StreamProvider.family<GroupModel?, String>((ref, groupId) {
  final repo = ref.watch(groupRepositoryProvider);
  return repo.watchGroup(groupId);
});

final groupMembersProvider = StreamProvider.family<List<GroupMemberModel>, String>((ref, groupId) {
  final repo = ref.watch(groupRepositoryProvider);
  return repo.watchGroupMembers(groupId);
});

class GroupActionState {
  final bool isLoading;
  final String? errorMessage;
  final GroupModel? createdOrJoinedGroup;

  const GroupActionState({
    this.isLoading = false,
    this.errorMessage,
    this.createdOrJoinedGroup,
  });
}

class GroupActionNotifier extends StateNotifier<GroupActionState> {
  final GroupRepository _repo;
  final Ref _ref;

  GroupActionNotifier(this._repo, this._ref) : super(const GroupActionState());

  Future<GroupModel?> createGroup({
    required String name,
    required int goal,
    required String period,
  }) async {
    state = const GroupActionState(isLoading: true);
    try {
      final user = _ref.read(currentUserProvider).value;
      final uid = user?.uid ?? 'user-yerosen-1';
      final displayName = user?.displayName ?? 'Yerosen Tamrat';

      final group = await _repo.createGroup(
        name: name,
        goal: goal,
        period: period,
        userId: uid,
        userName: displayName,
      );

      state = GroupActionState(createdOrJoinedGroup: group);
      return group;
    } catch (e) {
      state = GroupActionState(errorMessage: e.toString().replaceAll('Exception: ', ''));
      return null;
    }
  }

  Future<GroupModel?> joinGroupByCode(String code) async {
    state = const GroupActionState(isLoading: true);
    try {
      final user = _ref.read(currentUserProvider).value;
      final uid = user?.uid ?? 'user-yerosen-1';
      final displayName = user?.displayName ?? 'Yerosen Tamrat';

      final group = await _repo.joinGroupByCode(
        inviteCode: code,
        userId: uid,
        userName: displayName,
      );

      state = GroupActionState(createdOrJoinedGroup: group);
      return group;
    } catch (e) {
      state = GroupActionState(errorMessage: e.toString().replaceAll('Exception: ', ''));
      return null;
    }
  }
}

final groupActionControllerProvider =
    StateNotifierProvider<GroupActionNotifier, GroupActionState>((ref) {
  final repo = ref.watch(groupRepositoryProvider);
  return GroupActionNotifier(repo, ref);
});

