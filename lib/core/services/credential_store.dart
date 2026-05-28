import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:cims/core/services/student_session_storage.dart';
import 'package:cims/core/services/token_storage.dart';

/// Clears access token and secure storage (refresh token, role, etc.).
class CredentialStore {
  CredentialStore._();

  static const FlutterSecureStorage _secure =
      FlutterSecureStorage();

  static Future<void> clearAll() async {
    await TokenStorage.clear();
    await StudentSessionStorage.clear();
    await _secure.deleteAll();
  }
}
