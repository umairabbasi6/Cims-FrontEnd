import 'package:dio/dio.dart';

import 'package:cims/core/network/dio_client.dart';
import 'package:cims/features/admin/subjects/models/subject_api_model.dart';

class SubjectService {
  final Dio _dio = DioClient.dio;

  Future<SubjectListResponse> getSubjects({
    int? programId,
    int? stage,
    bool? isActive,
    String? search,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/subjects/',
      queryParameters: {
        if (programId != null) 'program_id': programId,
        if (stage != null) 'stage': stage,
        if (isActive != null) 'is_active': isActive,
        if (search != null && search.isNotEmpty)
          'search': search,
      },
    );
    return SubjectListResponse.fromJson(
      response.data!,
    );
  }

  Future<SubjectApiModel> getSubject(int id) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/subjects/$id',
    );
    return SubjectApiModel.fromJson(
      response.data!,
    );
  }

  Future<SubjectApiModel> createSubject({
    required int programId,
    required String name,
    required String code,
    required int stage,
    required double creditHours,
    required bool hasPractical,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/subjects/',
      data: {
        'program_id': programId,
        'name': name,
        'code': code.toUpperCase().trim(),
        'stage': stage,
        'credit_hours': creditHours,
        'has_practical': hasPractical,
      },
    );
    return SubjectApiModel.fromJson(response.data!);
  }

  Future<SubjectApiModel> updateSubject({
    required int id,
    String? name,
    String? code,
    double? creditHours,
    bool? hasPractical,
    bool? isActive,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/subjects/$id',
      data: {
        if (name != null) 'name': name,
        if (code != null) 'code': code.toUpperCase().trim(),
        if (creditHours != null) 'credit_hours': creditHours,
        if (hasPractical != null) 'has_practical': hasPractical,
        if (isActive != null) 'is_active': isActive,
      },
    );
    return SubjectApiModel.fromJson(response.data!);
  }

  Future<void> deleteSubject(int id) async {
    await _dio.delete('/subjects/$id');
  }
}

