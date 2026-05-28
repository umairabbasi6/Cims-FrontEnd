import 'package:dio/dio.dart';

import 'package:cims/core/network/dio_client.dart';
import 'package:cims/features/admin/staff/models/staff_api_model.dart';

class StaffService {
  final Dio _dio = DioClient.dio;

  Future<StaffListResponse> listStaff({
    String? category,
    int? departmentId,
    bool? isActive,
    String? search,
    int skip = 0,
    int limit = 100,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/staff/',
      queryParameters: {
        'skip': skip,
        'limit': limit,
        if (category != null) 'category': category,
        if (departmentId != null) 'department_id': departmentId,
        if (isActive != null) 'is_active': isActive,
        if (search != null && search.isNotEmpty)
          'search': search,
      },
    );
    return StaffListResponse.fromJson(
      response.data!,
    );
  }

  Future<StaffApiModel> getStaff(int id) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/staff/$id',
    );
    return StaffApiModel.fromJson(
      response.data!,
    );
  }

  Future<Map<String, dynamic>> getStaffSubjects(int staffId, {int? sessionId}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/staff/$staffId/subjects',
      queryParameters: {
        if (sessionId != null) 'session_id': sessionId,
      },
    );
    return response.data!;
  }

  Future<Map<String, dynamic>> assignSubject({
    required int staffId,
    required int subjectId,
    required int sessionId,
    required String role,
    String? section,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/staff/$staffId/subjects',
      data: {
        'subject_id': subjectId,
        'session_id': sessionId,
        'role': role,
        if (section != null) 'section': section,
      },
    );
    return response.data!;
  }

  Future<Map<String, dynamic>> removeSubjectAssignment({
    required int staffId,
    required int assignmentId,
  }) async {
    final response = await _dio.delete<Map<String, dynamic>>(
      '/staff/$staffId/subjects/$assignmentId',
    );
    return response.data!;
  }

  Future<StaffApiModel> updateStaff(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/staff/$id',
      data: data,
    );
    return StaffApiModel.fromJson(response.data!);
  }

  Future<StaffApiModel> createStaff(
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/staff/',
      data: data,
    );
    return StaffApiModel.fromJson(response.data!);
  }

  Future<void> deleteStaff(int id) async {
    await _dio.delete(
      '/staff/$id',
    );
  }
}

