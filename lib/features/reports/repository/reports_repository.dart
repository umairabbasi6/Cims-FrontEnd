import 'dart:typed_data';
import 'package:cims/features/reports/services/reports_api_service.dart';

class ReportsRepository {
  final ReportsApiService _apiService;

  ReportsRepository({ReportsApiService? apiService})
      : _apiService = apiService ?? ReportsApiService();

  Future<Uint8List> getGradeCard(int studentId) {
    return _apiService.getGradeCard(studentId);
  }

  Future<Uint8List> getFeeReceipt(int paymentId) {
    return _apiService.getFeeReceipt(paymentId);
  }

  Future<Uint8List> getAttendanceReport(int studentId) {
    return _apiService.getAttendanceReport(studentId);
  }

  Future<Uint8List> getFeeDefaulters({int? sessionId}) {
    return _apiService.getFeeDefaulters(sessionId: sessionId);
  }
}
