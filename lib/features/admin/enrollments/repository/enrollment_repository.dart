import 'package:cims/features/admin/enrollments/services/enrollment_service.dart';

class EnrollmentRepository {
  final EnrollmentService _service = EnrollmentService();

  Future<List<Map<String, dynamic>>> listEnrollments({
    int? sessionId,
    int? stage,
    String? status,
  }) {
    return _service.listEnrollments(
      sessionId: sessionId,
      stage: stage,
      status: status,
    );
  }

  Future<List<Map<String, dynamic>>> studentEnrollments(
    int studentId, {
    int? sessionId,
  }) {
    return _service.studentEnrollments(
      studentId,
      sessionId: sessionId,
    );
  }

  Future<List<Map<String, dynamic>>> subjectEnrollments(
    int subjectId, {
    int? sessionId,
  }) {
    return _service.subjectEnrollments(
      subjectId,
      sessionId: sessionId,
    );
  }

  Future<Map<String, dynamic>> enrollSingle(
    Map<String, dynamic> body,
  ) {
    return _service.enrollSingle(body);
  }

  Future<Map<String, dynamic>> bulkEnroll(
    Map<String, dynamic> body,
  ) {
    return _service.bulkEnroll(body);
  }

  Future<Map<String, dynamic>> repeatEnrollment(
    Map<String, dynamic> body,
  ) {
    return _service.repeatEnrollment(body);
  }

  Future<void> dropEnrollment(int enrollmentId) {
    return _service.dropEnrollment(enrollmentId);
  }

  Future<Map<String, dynamic>> updateEnrollmentStatus(
    int enrollmentId, {
    required String status,
    required String remarks,
  }) {
    return _service.updateEnrollmentStatus(
      enrollmentId,
      status: status,
      remarks: remarks,
    );
  }

  Future<List<String>> getStatusOptions() {
    return _service.getStatusOptions();
  }

  Future<void> deleteEnrollment(int enrollmentId) {
    return _service.deleteEnrollment(enrollmentId);
  }
}
