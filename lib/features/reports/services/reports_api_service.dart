import 'package:dio/dio.dart';
import 'package:cims/core/network/dio_client.dart';
import 'dart:typed_data';

class ReportsApiService {
  final Dio _dio = DioClient.dio;

  /// Grade Card PDF
  Future<Uint8List> getGradeCard(int studentId) async {
    try {
      final response = await _dio.get(
        '/reports/grade-card/$studentId',
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Fee Receipt PDF
  Future<Uint8List> getFeeReceipt(int paymentId) async {
    try {
      final response = await _dio.get(
        '/reports/fee-receipt/$paymentId',
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Attendance Report PDF
  Future<Uint8List> getAttendanceReport(int studentId) async {
    try {
      final response = await _dio.get(
        '/reports/attendance/$studentId',
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Fee Defaulters PDF
  Future<Uint8List> getFeeDefaulters({int? sessionId}) async {
    try {
      final response = await _dio.get(
        '/reports/fee-defaulters',
        queryParameters: sessionId != null ? {'session_id': sessionId} : null,
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}
