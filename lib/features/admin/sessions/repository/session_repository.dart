import 'package:dio/dio.dart';

import 'package:cims/features/admin/sessions/models/academic_session_model.dart';
import 'package:cims/features/admin/sessions/services/session_service.dart';

class SessionRepository {
  final SessionService _service = SessionService();

  /// Uses `GET /sessions/current`, or on 404 picks `is_current` from list.
  Future<AcademicSessionModel?> getCurrentWithFallback() async {
    try {
      return await _service.getCurrentSession();
    } on DioException catch (e) {
      if (e.response?.statusCode != 404) {
        rethrow;
      }
      final list = await _service.listSessions();
      final sessions = list.sessions;
      for (final s in sessions) {
        if (s.isCurrent) return s;
      }
      return sessions.isNotEmpty ? sessions.first : null;
    }
  }

  Future<List<AcademicSessionModel>> listSessions({
    bool? isActive,
  }) async {
    final res = await _service.listSessions(isActive: isActive);
    return res.sessions;
  }

  Future<AcademicSessionModel> getSession(int id) {
    return _service.getSession(id);
  }

  Future<AcademicSessionModel> createSession({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _service.createSession(
      name: name,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<AcademicSessionModel> updateSession({
    required int id,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
  }) {
    return _service.updateSession(
      id: id,
      name: name,
      startDate: startDate,
      endDate: endDate,
      isActive: isActive,
    );
  }

  Future<AcademicSessionModel> setCurrentSession(int id) {
    return _service.setCurrentSession(id);
  }

  Future<void> deleteSession(int id) {
    return _service.deleteSession(id);
  }
}
