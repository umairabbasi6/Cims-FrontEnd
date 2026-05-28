import 'package:dio/dio.dart';

import 'package:cims/core/network/dio_client.dart';

class EnrollmentService {
  final Dio _dio = DioClient.dio;

  Future<List<Map<String, dynamic>>> listEnrollments({
    int? sessionId,
    int? stage,
    String? status,
    int skip = 0,
    int limit = 100,
  }) async {
    final response = await _dio.get<dynamic>(
      '/enrollments/',
      queryParameters: {
        'skip': skip,
        'limit': limit,
        if (sessionId != null) 'session_id': sessionId,
        if (stage != null) 'stage': stage,
        if (status != null) 'status': status,
      },
    );
    return _asMapList(response.data);
  }

  Future<List<Map<String, dynamic>>> studentEnrollments(
    int studentId, {
    int? sessionId,
  }) async {
    final response = await _dio.get<dynamic>(
      '/enrollments/student/$studentId',
      queryParameters: {
        if (sessionId != null) 'session_id': sessionId,
      },
    );
    return _asMapList(response.data);
  }

  Future<List<Map<String, dynamic>>> subjectEnrollments(
    int subjectId, {
    int? sessionId,
  }) async {
    final response = await _dio.get<dynamic>(
      '/enrollments/subject/$subjectId',
      queryParameters: {
        if (sessionId != null) 'session_id': sessionId,
      },
    );
    return _asMapList(response.data);
  }

  Future<Map<String, dynamic>> enrollSingle(
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/enrollments/',
      data: body,
    );
    return response.data!;
  }

  Future<Map<String, dynamic>> bulkEnroll(
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/enrollments/bulk',
      data: body,
    );
    return response.data!;
  }

  Future<Map<String, dynamic>> repeatEnrollment(
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/enrollments/repeat',
      data: body,
    );
    return response.data!;
  }

  Future<void> dropEnrollment(int enrollmentId) async {
    await _dio.patch<void>(
      '/enrollments/$enrollmentId/drop',
    );
  }

  Future<Map<String, dynamic>> updateEnrollmentStatus(
    int enrollmentId, {
    required String status,
    required String remarks,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/enrollments/$enrollmentId',
      data: {
        'status': status,
        'remarks': remarks,
      },
    );
    return response.data!;
  }

  Future<List<String>> getStatusOptions() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/enrollments/status-options',
    );
    final list = response.data!['statuses'] as List? ?? [];
    return list.map((e) => e.toString()).toList();
  }

  Future<void> deleteEnrollment(int enrollmentId) async {
    await _dio.delete<void>(
      '/enrollments/$enrollmentId',
    );
  }

  List<Map<String, dynamic>> _asMapList(Object? data) {
    if (data is List) {
      return data
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    if (data is Map<String, dynamic>) {
      final inner = data['enrollments'] ?? data['items'];
      if (inner is List) {
        return inner
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
    }
    return [];
  }
}
