import 'package:dio/dio.dart';

import 'package:cims/core/network/dio_client.dart';

class ResultsApiService {
  final Dio _dio = DioClient.dio;

  Future<Map<String, dynamic>> saveMarks(
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/results/',
      data: body,
    );
    return response.data!;
  }

  Future<Map<String, dynamic>> updateMarks(
    int resultId,
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/results/$resultId',
      data: body,
    );
    return response.data!;
  }

  Future<Map<String, dynamic>> gradeCard(
    int studentId, {
    required int sessionId,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/results/grade-card/$studentId',
      queryParameters: {'session_id': sessionId},
    );
    return response.data!;
  }

  Future<List<Map<String, dynamic>>> classResultSheet(
    int subjectId, {
    required int sessionId,
  }) async {
    final response = await _dio.get<dynamic>(
      '/results/subject/$subjectId',
      queryParameters: {'session_id': sessionId},
    );
    final data = response.data;
    if (data is List) {
      return data
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    if (data is Map<String, dynamic>) {
      final inner = data['results'] ?? data['rows'];
      if (inner is List) {
        return inner
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> studentResults(
    int studentId, {
    int? sessionId,
  }) async {
    final response = await _dio.get<dynamic>(
      '/results/student/$studentId',
      queryParameters: {
        if (sessionId != null) 'session_id': sessionId,
      },
    );
    final data = response.data;
    if (data is List) {
      return data
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    if (data is Map<String, dynamic>) {
      final inner = data['results'] ?? data['items'];
      if (inner is List) {
        return inner
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
    }
    return [];
  }
}
