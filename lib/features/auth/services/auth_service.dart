import 'package:cims/features/auth/models/change_password_request.dart';
import 'package:cims/features/auth/models/current_user.dart';
import 'package:cims/features/auth/models/login_request.dart';
import 'package:cims/features/auth/models/login_response.dart';
import 'package:cims/features/auth/models/message_response.dart';

import 'package:cims/core/network/api_client.dart';

class AuthService {
  Future<LoginResponse> login(
    LoginRequest request,
  ) {
    return ApiClient.auth.login(request.toJson());
  }

  Future<CurrentUser> getMe() {
    return ApiClient.auth.getMe();
  }

  Future<MessageResponse> changePassword(
    ChangePasswordRequest request,
  ) {
    return ApiClient.auth.changePassword(
      request.toJson(),
    );
  }
}
