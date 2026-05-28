import 'package:dio/dio.dart';

import 'package:cims/core/network/dio_client.dart';
import 'package:cims/features/admin/students/models/student_api_model.dart';

class StudentService {
  final Dio _dio = DioClient.dio;

  Future<StudentListResponse> listStudents({
    int? programId,
    int? sessionId,
    int? stage,
    String? status,
    bool? isActive,
    String? search,
    int skip = 0,
    int limit = 50,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/students/',
      queryParameters: {
        'skip': skip,
        'limit': limit,
        if (programId != null) 'program_id': programId,
        if (sessionId != null) 'session_id': sessionId,
        if (stage != null) 'stage': stage,
        if (status != null) 'status': status,
        if (isActive != null) 'is_active': isActive,
        if (search != null && search.isNotEmpty)
          'search': search,
      },
    );
    return StudentListResponse.fromJson(
      response.data!,
    );
  }

  Future<StudentApiModel> getMe() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/students/me',
    );
    return StudentApiModel.fromJson(
      response.data!,
    );
  }

  Future<StudentApiModel> getStudent(int id) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/students/$id',
    );
    return StudentApiModel.fromJson(
      response.data!,
    );
  }

  Future<StudentApiModel> updateStudent(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/students/$id',
      data: data,
    );
    return StudentApiModel.fromJson(response.data!);
  }

  Future<void> deleteStudent(int id) async {
    await _dio.delete('/students/$id');
  }

  Future<StudentApiModel> createStudent(
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/students/',
      data: data,
    );
    return StudentApiModel.fromJson(response.data!);
  }

  Future<StudentApiModel> updateMe(
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/students/me',
      data: data,
    );
    return StudentApiModel.fromJson(response.data!);
  }

  Future<StudentListResponse> listAlumni({
    required String sessionsCsv,
    int? programId,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/students/alumni',
      queryParameters: {
        'sessions': sessionsCsv,
        if (programId != null) 'program_id': programId,
      },
    );
    return StudentListResponse.fromJson(
      response.data!,
    );
  }

  Future<StudentApiModel> promoteStudent(
    int studentId, {
    required int sessionId,
    required String remarks,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/students/$studentId/promote',
      data: {
        'session_id': sessionId,
        'remarks': remarks,
      },
    );
    return StudentApiModel.fromJson(response.data!);
  }

  Future<StudentApiModel> graduateStudent(
    int studentId, {
    required int sessionId,
    required String graduationDate,
    required String remarks,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/students/$studentId/graduate',
      data: {
        'session_id': sessionId,
        'graduation_date': graduationDate,
        'remarks': remarks,
      },
    );
    return StudentApiModel.fromJson(response.data!);
  }

  Future<StudentApiModel> freezeStudent(
    int studentId, {
    required int sessionId,
    required String remarks,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/students/$studentId/freeze',
      data: {
        'session_id': sessionId,
        'remarks': remarks,
      },
    );
    return StudentApiModel.fromJson(response.data!);
  }

  Future<StudentApiModel> strikeOffStudent(
    int studentId, {
    required int sessionId,
    required String remarks,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/students/$studentId/strike-off',
      data: {
        'session_id': sessionId,
        'remarks': remarks,
      },
    );
    return StudentApiModel.fromJson(response.data!);
  }

  Future<StudentApiModel> restoreStudent(
    int studentId, {
    required int sessionId,
    required String remarks,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/students/$studentId/restore',
      data: {
        'session_id': sessionId,
        'remarks': remarks,
      },
    );
    return StudentApiModel.fromJson(response.data!);
  }

  Future<StudentHistoryResponse> getStudentHistory(int studentId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/students/$studentId/history',
    );
    return StudentHistoryResponse.fromJson(response.data!);
  }

  Future<StudentApiModel> getStudentByRegistration(String registrationNumber) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/students/by-registration/$registrationNumber',
    );
    return StudentApiModel.fromJson(response.data!);
  }
}
