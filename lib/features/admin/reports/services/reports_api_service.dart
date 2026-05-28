import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'package:cims/core/network/dio_client.dart';

/// PDF and binary report downloads (`ResponseType.bytes`).
class ReportsApiService {
  final Dio _dio = DioClient.dio;

  List<int> _bytesFrom(Response<dynamic> response) {
    final data = response.data;
    if (data == null) return <int>[];
    if (data is Uint8List) return data;
    if (data is List<int>) return data;
    return Uint8List.fromList(
      List<int>.from(data as List<dynamic>),
    );
  }

  Future<List<int>> getGradeCardPdf({
    required int studentId,
    required int sessionId,
  }) async {
    final response = await _dio.get(
      '/reports/grade-card/$studentId',
      queryParameters: {'session_id': sessionId},
      options: Options(responseType: ResponseType.bytes),
    );
    return _bytesFrom(response);
  }

  Future<List<int>> getFeeReceiptPdf(int paymentId) async {
    final response = await _dio.get(
      '/reports/fee-receipt/$paymentId',
      options: Options(responseType: ResponseType.bytes),
    );
    return _bytesFrom(response);
  }

  Future<List<int>> getAttendancePdf({
    required int studentId,
    required int sessionId,
  }) async {
    final response = await _dio.get(
      '/reports/attendance/$studentId',
      queryParameters: {'session_id': sessionId},
      options: Options(responseType: ResponseType.bytes),
    );
    return _bytesFrom(response);
  }

  Future<List<int>> getFeeDefaultersPdf({
    required int sessionId,
    int? programId,
  }) async {
    final response = await _dio.get(
      '/reports/fee-defaulters',
      queryParameters: {
        'session_id': sessionId,
        if (programId != null) 'program_id': programId,
      },
      options: Options(responseType: ResponseType.bytes),
    );
    return _bytesFrom(response);
  }
}
