import 'package:cims/features/admin/users/models/invite_user_request.dart';
import 'package:cims/features/admin/users/models/update_user_request.dart';
import 'package:cims/features/admin/users/models/user_model.dart';
import 'package:cims/features/admin/users/services/user_service.dart';

class UserRepository {
  final UserService _service;

  UserRepository([UserService? service]) : _service = service ?? UserService();

  Future<UserListResponse> getUsers({
    int skip = 0,
    int limit = 100,
    String? role,
    bool? isActive,
    String? search,
  }) {
    return _service.getUsers(
      skip: skip,
      limit: limit,
      role: role,
      isActive: isActive,
      search: search,
    );
  }

  Future<UserModel> getUser(String id) {
    return _service.getUser(id);
  }

  Future<UserModel> inviteUser(InviteUserRequest request) {
    return _service.inviteUser(request);
  }

  Future<UserModel> updateUser({
    required String id,
    required UpdateUserRequest request,
  }) {
    return _service.updateUser(id: id, request: request);
  }

  Future<void> deleteUser(String id) {
    return _service.deleteUser(id);
  }
}
