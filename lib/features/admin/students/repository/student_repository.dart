import 'package:flutter/foundation.dart';
import 'package:cims/core/services/student_session_storage.dart';
import 'package:cims/features/admin/students/models/student_api_model.dart';
import 'package:cims/features/admin/students/services/student_service.dart';

class StudentRepository {
  final StudentService _service = StudentService();

  Future<List<StudentApiModel>> listStudents({
    int? programId,
    int? sessionId,
    int? stage,
    String? status,
    bool? isActive,
    String? search,
  }) async {
    final res = await _service.listStudents(
      programId: programId,
      sessionId: sessionId,
      stage: stage,
      status: status,
      isActive: isActive,
      search: search,
    );
    return res.students;
  }

  Future<StudentApiModel> getStudent(int id) {
    return _service.getStudent(id);
  }

  Future<List<StudentApiModel>> listAlumni({
    required String sessionsCsv,
    int? programId,
  }) async {
    final res = await _service.listAlumni(
      sessionsCsv: sessionsCsv,
      programId: programId,
    );
    return res.students;
  }

  /// Resolves the student row for the signed-in account.
  /// Uses the new /students/me endpoint available for student roles.
  Future<StudentApiModel?> resolveCurrentStudent(
    String username,
  ) async {
    try {
      final student = await _service.getMe();
      await StudentSessionStorage.saveId(student.id);
      return student;
    } catch (e) {
      debugPrint(
          '[StudentRepository] Failed to resolve student via /me: $e');
      return null;
    }
  }

  Future<StudentApiModel> updateStudent(
    int id,
    Map<String, dynamic> data,
  ) {
    return _service.updateStudent(id, data);
  }

  Future<void> deleteStudent(int id) async {
    return _service.deleteStudent(id);
  }

  Future<StudentApiModel> createStudent(
    Map<String, dynamic> data,
  ) {
    return _service.createStudent(data);
  }

  Future<StudentApiModel> updateMe(
    Map<String, dynamic> data,
  ) {
    return _service.updateMe(data);
  }

  Future<StudentApiModel> promoteStudent(
    int studentId, {
    required int sessionId,
    required String remarks,
  }) {
    return _service.promoteStudent(
      studentId,
      sessionId: sessionId,
      remarks: remarks,
    );
  }

  Future<StudentApiModel> graduateStudent(
    int studentId, {
    required int sessionId,
    required String graduationDate,
    required String remarks,
  }) {
    return _service.graduateStudent(
      studentId,
      sessionId: sessionId,
      graduationDate: graduationDate,
      remarks: remarks,
    );
  }

  Future<StudentApiModel> freezeStudent(
    int studentId, {
    required int sessionId,
    required String remarks,
  }) {
    return _service.freezeStudent(
      studentId,
      sessionId: sessionId,
      remarks: remarks,
    );
  }

  Future<StudentApiModel> strikeOffStudent(
    int studentId, {
    required int sessionId,
    required String remarks,
  }) {
    return _service.strikeOffStudent(
      studentId,
      sessionId: sessionId,
      remarks: remarks,
    );
  }

  Future<StudentApiModel> restoreStudent(
    int studentId, {
    required int sessionId,
    required String remarks,
  }) {
    return _service.restoreStudent(
      studentId,
      sessionId: sessionId,
      remarks: remarks,
    );
  }

  Future<StudentHistoryResponse> getStudentHistory(int studentId) {
    return _service.getStudentHistory(studentId);
  }

  Future<StudentApiModel> getStudentByRegistration(String registrationNumber) {
    return _service.getStudentByRegistration(registrationNumber);
  }
}

