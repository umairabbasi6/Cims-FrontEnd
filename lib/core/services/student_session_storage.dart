import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the numeric student record id for the logged-in student role.
class StudentSessionStorage {
  StudentSessionStorage._();

  static const _key = 'student_id';
  static const FlutterSecureStorage _secure =
      FlutterSecureStorage();

  static Future<int?> readId() async {
    final raw = await _secure.read(key: _key);
    return int.tryParse(raw ?? '');
  }

  static Future<void> saveId(int id) async {
    await _secure.write(key: _key, value: id.toString());
  }

  static Future<void> clear() async {
    await _secure.delete(key: _key);
  }
}
