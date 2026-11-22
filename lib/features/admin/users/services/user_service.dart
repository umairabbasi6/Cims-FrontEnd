import 'package:dio/dio.dart';
import 'package:cims/core/network/dio_client.dart';
import 'package:cims/features/admin/users/models/invite_user_request.dart';
import 'package:cims/features/admin/users/models/update_user_request.dart';
import 'package:cims/features/admin/users/models/user_model.dart';

class UserService {
  final Dio _dio = DioClient.dio;

  Future<UserListResponse> getUsers({
    int skip = 0,
    int limit = 100,
    String? role,
    bool? isActive,
    String? search,
  }) async {
    final response = await _dio.get(
      '/users/',
      queryParameters: {
        'skip': skip,
        'limit': limit,
        if (role != null && role.isNotEmpty) 'role': role,
        if (isActive != null) 'is_active': isActive,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );

    return UserListResponse.fromJson(response.data);
  }

  Future<UserModel> getUser(String id) async {
    final response = await _dio.get('/users/$id');
    return UserModel.fromJson(response.data);
  }

  Future<UserModel> inviteUser(InviteUserRequest request) async {
    final response = await _dio.post(
      '/users/invite',
      data: request.toJson(),
    );
    return UserModel.fromJson(response.data);
  }

  Future<UserModel> updateUser({
    required String id,
    required UpdateUserRequest request,
  }) async {
    final response = await _dio.patch(
      '/users/$id',
      data: request.toJson(),
    );
    return UserModel.fromJson(response.data);
  }

  Future<void> deleteUser(String id) async {
    await _dio.delete('/users/$id');
  }
}
