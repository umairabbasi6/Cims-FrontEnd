import 'package:dio/dio.dart';

import 'package:cims/core/network/dio_client.dart';
import 'package:cims/features/admin/sessions/models/academic_session_model.dart';

class SessionService {
  final Dio _dio = DioClient.dio;

  Future<AcademicSessionModel> getCurrentSession() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/sessions/current',
    );
    return AcademicSessionModel.fromJson(
      response.data!,
    );
  }

  Future<AcademicSessionListResponse> listSessions({
    bool? isActive,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/sessions/',
      queryParameters: {
        if (isActive != null) 'is_active': isActive,
      },
    );
    return AcademicSessionListResponse.fromJson(
      response.data!,
    );
  }

  Future<AcademicSessionModel> getSession(int id) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/sessions/$id',
    );
    return AcademicSessionModel.fromJson(
      response.data!,
    );
  }

  Future<AcademicSessionModel> createSession({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/sessions/',
      data: {
        'name': name,
        'start_date': _formatDate(startDate),
        'end_date': _formatDate(endDate),
      },
    );
    return AcademicSessionModel.fromJson(response.data!);
  }

  Future<AcademicSessionModel> updateSession({
    required int id,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/sessions/$id',
      data: {
        if (name != null) 'name': name,
        if (startDate != null) 'start_date': _formatDate(startDate),
        if (endDate != null) 'end_date': _formatDate(endDate),
        if (isActive != null) 'is_active': isActive,
      },
    );
    return AcademicSessionModel.fromJson(response.data!);
  }

  Future<AcademicSessionModel> setCurrentSession(int id) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/sessions/$id/set-current',
    );
    return AcademicSessionModel.fromJson(response.data!);
  }

  Future<void> deleteSession(int id) async {
    await _dio.delete(
      '/sessions/$id',
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
