import 'dart:typed_data';
import 'package:cims/features/teacher/attendance/services/attendance_api_service.dart';

class AttendanceRepository {
  final AttendanceService _service = AttendanceService();

  Future<List<Map<String, dynamic>>> listSessions({
    int? subjectId,
    int? sessionId,
    int? staffId,
    int? stage,
    int skip = 0,
    int limit = 50,
  }) {
    return _service.listSessions(
      subjectId: subjectId,
      sessionId: sessionId,
      staffId: staffId,
      stage: stage,
      skip: skip,
      limit: limit,
    );
  }

  Future<Map<String, dynamic>> getSession(int id) {
    return _service.getSession(id);
  }

  Future<Map<String, dynamic>> createSession(Map<String, dynamic> body) {
    return _service.createSession(body);
  }

  Future<Map<String, dynamic>> bulkMark(int sessionId, Map<String, dynamic> body) {
    return _service.bulkMark(sessionId, body);
  }

  Future<Map<String, dynamic>> studentReport(int studentId, {required int sessionId}) {
    return _service.studentReport(studentId, sessionId: sessionId);
  }

  Future<Map<String, dynamic>> shortageList({required int sessionId, int? programId, int? stage}) {
    return _service.shortageList(sessionId: sessionId, programId: programId, stage: stage);
  }

  Future<Map<String, dynamic>> getTeacherStatus() {
    return _service.getTeacherStatus();
  }

  Future<Map<String, dynamic>> teacherCheckIn({
    double? latitude,
    double? longitude,
    String? ipAddress,
  }) {
    return _service.teacherCheckIn(
      latitude: latitude,
      longitude: longitude,
      ipAddress: ipAddress,
    );
  }

  Future<List<Map<String, dynamic>>> getAdminAttendanceRecords({String? dateVal}) {
    return _service.getAdminAttendanceRecords(dateVal: dateVal);
  }

  Future<Map<String, dynamic>> overrideTeacherAttendance({
    required int teacherId,
    required String dateVal,
    required String newStatus,
    String? notes,
  }) {
    return _service.overrideTeacherAttendance(
      teacherId: teacherId,
      dateVal: dateVal,
      newStatus: newStatus,
      notes: notes,
    );
  }

  Future<Uint8List> getTeacherAttendancePdf({String? dateVal}) {
    return _service.getTeacherAttendancePdf(dateVal: dateVal);
  }
}
