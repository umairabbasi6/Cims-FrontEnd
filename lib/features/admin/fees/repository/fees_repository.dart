import 'package:cims/features/admin/fees/services/fees_api_service.dart';

class FeesRepository {
  final FeesApiService _service = FeesApiService();

  Future<Map<String, dynamic>> listStructures({
    int? programId,
    int? sessionId,
    int? stage,
    bool? isActive,
  }) {
    return _service.listStructures(
      programId: programId,
      sessionId: sessionId,
      stage: stage,
      isActive: isActive,
    );
  }

  Future<Map<String, dynamic>> createStructure(
    Map<String, dynamic> body,
  ) {
    return _service.createStructure(body);
  }

  Future<Map<String, dynamic>> recordPayment(
    Map<String, dynamic> body,
  ) {
    return _service.recordPayment(body);
  }

  Future<Map<String, dynamic>> getPayment(int id) {
    return _service.getPayment(id);
  }

  Future<List<Map<String, dynamic>>> studentPayments(
    int studentId, {
    int? sessionId,
  }) {
    return _service.studentPayments(
      studentId,
      sessionId: sessionId,
    );
  }

  Future<Map<String, dynamic>> studentDues(
    int studentId, {
    required int sessionId,
  }) {
    return _service.studentDues(
      studentId,
      sessionId: sessionId,
    );
  }

  Future<Map<String, dynamic>> defaulters({
    required int sessionId,
    int? programId,
  }) {
    return _service.defaulters(
      sessionId: sessionId,
      programId: programId,
    );
  }

  Future<Map<String, dynamic>> getAdminDashboard() {
    return _service.getAdminDashboard();
  }

  Future<Map<String, dynamic>> createAssignment(
    Map<String, dynamic> body,
  ) {
    return _service.createAssignment(body);
  }

  Future<List<Map<String, dynamic>>> listAssignments({
    int? studentId,
    String? statusIn,
  }) {
    return _service.listAssignments(
      studentId: studentId,
      statusIn: statusIn,
    );
  }

  Future<Map<String, dynamic>> updateAssignmentStatus(
    int assignmentId,
    String status,
  ) {
    return _service.updateAssignmentStatus(assignmentId, status);
  }

  Future<void> deleteAssignment(int assignmentId) {
    return _service.deleteAssignment(assignmentId);
  }

  Future<List<Map<String, dynamic>>> listPayments({
    String? startDate,
    String? endDate,
    int? page,
    int? limit,
    int? sessionId,
    int? studentId,
  }) {
    return _service.listPayments(
      startDate: startDate,
      endDate: endDate,
      page: page,
      limit: limit,
      sessionId: sessionId,
      studentId: studentId,
    );
  }

  Future<Map<String, dynamic>> getStudentFeeDashboard(
    int studentId, {
    int? sessionId,
  }) {
    return _service.getStudentFeeDashboard(
      studentId,
      sessionId: sessionId,
    );
  }

  Future<Map<String, dynamic>> updateStructure(
    int id,
    Map<String, dynamic> body,
  ) {
    return _service.updateStructure(id, body);
  }

  Future<Map<String, dynamic>> studentDuesTotal(
    int studentId, {
    int? sessionId,
  }) {
    return _service.studentDuesTotal(studentId, sessionId: sessionId);
  }
}
