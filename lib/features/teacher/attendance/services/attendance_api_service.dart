import 'dart:typed_data';
import 'package:dio/dio.dart';

import 'package:cims/core/network/dio_client.dart';

class AttendanceService {
  final Dio _dio = DioClient.dio;

  Future<Map<String, dynamic>> createSession(
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/attendance/sessions',
      data: body,
    );
    return response.data!;
  }

  Future<List<Map<String, dynamic>>> listSessions({
    int? subjectId,
    int? sessionId,
    int? staffId,
    int? stage,
    int skip = 0,
    int limit = 50,
  }) async {
    final response = await _dio.get<dynamic>(
      '/attendance/sessions',
      queryParameters: {
        'skip': skip,
        'limit': limit,
        if (subjectId != null) 'subject_id': subjectId,
        if (sessionId != null) 'session_id': sessionId,
        if (staffId != null) 'staff_id': staffId,
        if (stage != null) 'stage': stage,
      },
    );
    return _unwrapList(response.data);
  }

  Future<Map<String, dynamic>> getSession(int id) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/attendance/sessions/$id',
    );
    return response.data!;
  }

  Future<Map<String, dynamic>> bulkMark(
    int sessionId,
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/attendance/sessions/$sessionId/mark',
      data: body,
    );
    return response.data!;
  }

  Future<Map<String, dynamic>> studentReport(
    int studentId, {
    required int sessionId,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/attendance/report/student/$studentId',
      queryParameters: {'session_id': sessionId},
    );
    return response.data!;
  }

  Future<Map<String, dynamic>> shortageList({
    required int sessionId,
    int? programId,
    int? stage,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/attendance/shortage',
      queryParameters: {
        'session_id': sessionId,
        if (programId != null) 'program_id': programId,
        if (stage != null) 'stage': stage,
      },
    );
    return response.data!;
  }

  List<Map<String, dynamic>> _unwrapList(Object? data) {
    if (data is List) {
      return data
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    if (data is Map<String, dynamic>) {
      final inner = data['sessions'] ?? data['items'];
      if (inner is List) {
        return inner
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
    }
    return [];
  }

  // ── Teacher self check-in status ──────────────────────────────────────────
  Future<Map<String, dynamic>> getTeacherStatus() async {
    final response = await _dio.get<Map<String, dynamic>>('/attendance/status');
    return response.data!;
  }

  // ── Teacher self check-in ─────────────────────────────────────────────────
  Future<Map<String, dynamic>> teacherCheckIn({
    double? latitude,
    double? longitude,
    String? ipAddress,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/attendance/check-in',
      data: {
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (ipAddress != null) 'ip_address': ipAddress,
      },
    );
    return response.data!;
  }

  // ── Admin daily attendance records ────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getAdminAttendanceRecords({String? dateVal}) async {
    final response = await _dio.get<dynamic>(
      '/attendance/admin/records',
      queryParameters: {
        if (dateVal != null) 'date_val': dateVal,
      },
    );
    if (response.data is List) {
      return (response.data as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    return [];
  }

  // ── Admin override teacher attendance ─────────────────────────────────────
  Future<Map<String, dynamic>> overrideTeacherAttendance({
    required int teacherId,
    required String dateVal,
    required String newStatus,
    String? notes,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/attendance/admin/override',
      data: {
        'teacher_id': teacherId,
        'date': dateVal,
        'new_status': newStatus,
        if (notes != null) 'notes': notes,
      },
    );
    return response.data!;
  }

  // ── Admin daily teacher attendance PDF report ─────────────────────────────
  Future<Uint8List> getTeacherAttendancePdf({String? dateVal}) async {
    final response = await _dio.get<dynamic>(
      '/reports/teacher-attendance',
      queryParameters: {
        if (dateVal != null) 'date_val': dateVal,
      },
      options: Options(responseType: ResponseType.bytes),
    );
    final data = response.data;
    if (data == null) return Uint8List(0);
    if (data is Uint8List) return data;
    if (data is List<int>) return Uint8List.fromList(data);
    return Uint8List.fromList(List<int>.from(data as List<dynamic>));
  }
}
