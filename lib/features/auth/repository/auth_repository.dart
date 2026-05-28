import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:cims/core/services/credential_store.dart';
import 'package:cims/core/services/token_storage.dart';
import 'package:cims/core/session/auth_session_controller.dart';

import 'package:cims/features/auth/models/change_password_request.dart';
import 'package:cims/features/auth/models/current_user.dart';
import 'package:cims/features/auth/models/login_request.dart';
import 'package:cims/features/auth/models/login_response.dart';
import 'package:cims/features/auth/models/message_response.dart';

import 'package:cims/features/auth/services/auth_service.dart';

class AuthRepository {
  final AuthService _service =
      AuthService();

  final FlutterSecureStorage
  _storage =
      const FlutterSecureStorage();

  Future<LoginResponse> login({
    required String username,
    required String password,
  }) async {
    final response =
        await _service.login(
      LoginRequest(
        username: username,
        password: password,
      ),
    );

    // SAVE TOKENS

    await TokenStorage.saveToken(response.accessToken);

    await _storage.write(
      key: 'refresh_token',
      value: response.refreshToken,
    );

    await _storage.write(
      key: 'role',
      value: response.role,
    );

    AuthSessionController.instance
        .setAuthenticated(response.role);

    return response;
  }

  Future<CurrentUser> getMe() {
    return _service.getMe();
  }

  Future<MessageResponse> changePassword(
    ChangePasswordRequest request,
  ) {
    return _service.changePassword(request);
  }

  Future<void> logout() async {
    await CredentialStore.clearAll();
    await AuthSessionController.instance.signOut();
  }

  Future<String?> getToken() async {
    return TokenStorage.getToken();
  }

  Future<String?> getRole() async {
    return _storage.read(
      key: 'role',
    );
  }
}