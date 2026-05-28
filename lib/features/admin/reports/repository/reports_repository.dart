import 'package:cims/features/admin/reports/services/reports_api_service.dart';

class ReportsRepository {
  final ReportsApiService _service = ReportsApiService();

  Future<List<int>> getGradeCardPdf({
    required int studentId,
    required int sessionId,
  }) {
    return _service.getGradeCardPdf(
      studentId: studentId,
      sessionId: sessionId,
    );
  }

  Future<List<int>> getFeeReceiptPdf(int paymentId) {
    return _service.getFeeReceiptPdf(paymentId);
  }

  Future<List<int>> getAttendancePdf({
    required int studentId,
    required int sessionId,
  }) {
    return _service.getAttendancePdf(
      studentId: studentId,
      sessionId: sessionId,
    );
  }

  Future<List<int>> getFeeDefaultersPdf({
    required int sessionId,
    int? programId,
  }) {
    return _service.getFeeDefaultersPdf(sessionId: sessionId, programId: programId);
  }
}
