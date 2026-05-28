import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:cims/core/services/token_storage.dart';
import 'package:cims/core/session/app_session.dart';

/// Drives [GoRouter] refresh and keeps [AppSession] aligned with persisted auth.
class AuthSessionController extends ChangeNotifier {
  AuthSessionController._();

  static final AuthSessionController instance =
      AuthSessionController._();

  static const FlutterSecureStorage _secure =
      FlutterSecureStorage();

  bool _authenticated = false;
  String _role = 'admin';

  bool get isAuthenticated => _authenticated;

  String get role => _role;

  /// Load token/role from storage into memory (call from `main` before `runApp`).
  Future<void> restore() async {
    final token = await TokenStorage.getToken();
    final storedRole =
        await _secure.read(key: 'role');

    _authenticated =
        token != null && token.isNotEmpty;
    _role = (_authenticated &&
            storedRole != null &&
            storedRole.isNotEmpty)
        ? storedRole
        : 'admin';

    if (!_authenticated) {
      AppSession.currentRole = 'admin';
    } else {
      AppSession.currentRole = _role;
    }

    notifyListeners();
  }

  void setAuthenticated(String role) {
    _authenticated = true;
    _role = role;
    AppSession.currentRole = role;
    notifyListeners();
  }

  Future<void> signOut() async {
    _authenticated = false;
    _role = 'admin';
    AppSession.currentRole = 'admin';
    notifyListeners();
  }
}
