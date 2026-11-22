import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:cims/features/admin/users/models/user_model.dart';
import 'package:cims/features/admin/users/repository/user_repository.dart';

class UserFilter {
  final String? role;
  final bool? isActive;
  final String? search;

  const UserFilter({
    this.role,
    this.isActive,
    this.search,
  });

  UserFilter copyWith({
    String? Function()? role,
    bool? Function()? isActive,
    String? Function()? search,
  }) {
    return UserFilter(
      role: role != null ? role() : this.role,
      isActive: isActive != null ? isActive() : this.isActive,
      search: search != null ? search() : this.search,
    );
  }
}

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

final userFilterProvider = StateProvider<UserFilter>((ref) {
  return const UserFilter();
});

final usersListProvider = FutureProvider.autoDispose<List<UserModel>>((ref) async {
  final repo = ref.read(userRepositoryProvider);
  final filter = ref.watch(userFilterProvider);

  final response = await repo.getUsers(
    role: filter.role,
    isActive: filter.isActive,
    search: filter.search,
  );

  return response.users;
});
