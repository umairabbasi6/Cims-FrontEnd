import 'package:dio/dio.dart';

import 'package:cims/core/network/dio_client.dart';

class FeesApiService {
  final Dio _dio = DioClient.dio;

  Future<Map<String, dynamic>> listStructures({
    int? programId,
    int? sessionId,
    int? stage,
    bool? isActive,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/fees/structures',
      queryParameters: {
        if (programId != null) 'program_id': programId,
        if (sessionId != null) 'session_id': sessionId,
        if (stage != null) 'stage': stage,
        if (isActive != null) 'is_active': isActive,
      },
    );
    return response.data!;
  }

  Future<Map<String, dynamic>> createStructure(
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/fees/structures',
      data: body,
    );
    return response.data!;
  }

  Future<Map<String, dynamic>> recordPayment(
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/fees/payments',
      data: body,
    );
    return response.data!;
  }

  Future<Map<String, dynamic>> getPayment(int id) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/fees/payments/$id',
    );
    return response.data!;
  }

  Future<List<Map<String, dynamic>>> studentPayments(
    int studentId, {
    int? sessionId,
  }) async {
    final response = await _dio.get<dynamic>(
      '/fees/payments/student/$studentId',
      queryParameters: {
        if (sessionId != null) 'session_id': sessionId,
      },
    );
    return _unwrapList(response.data);
  }

  Future<Map<String, dynamic>> studentDues(
    int studentId, {
    required int sessionId,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/fees/dues/student/$studentId',
      queryParameters: {'session_id': sessionId},
    );
    return response.data!;
  }

  Future<Map<String, dynamic>> defaulters({
    required int sessionId,
    int? programId,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/fees/defaulters',
      queryParameters: {
        'session_id': sessionId,
        if (programId != null) 'program_id': programId,
      },
    );
    return response.data!;
  }

  Future<Map<String, dynamic>> getAdminDashboard() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/fees/dashboard/admin',
    );
    return response.data!;
  }

  Future<Map<String, dynamic>> createAssignment(
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/fees/assignments',
      data: body,
    );
    return response.data!;
  }

  Future<List<Map<String, dynamic>>> listAssignments({
    int? studentId,
    String? statusIn,
  }) async {
    final response = await _dio.get<dynamic>(
      '/fees/assignments',
      queryParameters: {
        if (studentId != null) 'student_id': studentId,
        if (statusIn != null) 'status_in': statusIn,
      },
    );
    return _unwrapList(response.data);
  }

  Future<Map<String, dynamic>> updateAssignmentStatus(
    int assignmentId,
    String status,
  ) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/fees/assignments/$assignmentId',
      data: {'status': status},
    );
    return response.data!;
  }

  Future<void> deleteAssignment(int assignmentId) async {
    await _dio.delete('/fees/assignments/$assignmentId');
  }

  Future<List<Map<String, dynamic>>> listPayments({
    String? startDate,
    String? endDate,
    int? page,
    int? limit,
    int? sessionId,
    int? studentId,
  }) async {
    final response = await _dio.get<dynamic>(
      '/fees/payments',
      queryParameters: {
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
        if (page != null) 'page': page,
        if (limit != null) 'limit': limit,
        if (sessionId != null) 'session_id': sessionId,
        if (studentId != null) 'student_id': studentId,
      },
    );
    return _unwrapList(response.data);
  }

  Future<Map<String, dynamic>> getStudentFeeDashboard(
    int studentId, {
    int? sessionId,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/fees/dashboard/student/$studentId',
      queryParameters: {
        if (sessionId != null) 'session_id': sessionId,
      },
    );
    return response.data!;
  }

  Future<Map<String, dynamic>> updateStructure(
    int id,
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/fees/structures/$id',
      data: body,
    );
    return response.data!;
  }

  Future<Map<String, dynamic>> studentDuesTotal(
    int studentId, {
    int? sessionId,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/fees/dues/student/$studentId/total',
      queryParameters: {
        if (sessionId != null) 'session_id': sessionId,
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
      final inner = data['payments'] ?? data['assignments'] ?? data['items'];
      if (inner is List) {
        return inner
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
    }
    return [];
  }
}
