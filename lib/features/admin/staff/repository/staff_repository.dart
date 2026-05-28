import 'package:cims/features/admin/staff/models/staff_api_model.dart';
import 'package:cims/features/admin/staff/services/staff_service.dart';

class StaffRepository {
  final StaffService _service = StaffService();

  Future<List<StaffApiModel>> listStaff({
    String? category,
    int? departmentId,
    bool? isActive,
    String? search,
  }) async {
    final res = await _service.listStaff(
      category: category,
      departmentId: departmentId,
      isActive: isActive,
      search: search,
    );
    return res.staff;
  }

  Future<StaffApiModel> getStaff(int id) {
    return _service.getStaff(id);
  }

  Future<Map<String, dynamic>> getStaffSubjects(int staffId, {int? sessionId}) {
    return _service.getStaffSubjects(staffId, sessionId: sessionId);
  }

  Future<Map<String, dynamic>> assignSubject({
    required int staffId,
    required int subjectId,
    required int sessionId,
    required String role,
    String? section,
  }) {
    return _service.assignSubject(
      staffId: staffId,
      subjectId: subjectId,
      sessionId: sessionId,
      role: role,
      section: section,
    );
  }

  Future<Map<String, dynamic>> removeSubjectAssignment({
    required int staffId,
    required int assignmentId,
  }) {
    return _service.removeSubjectAssignment(
      staffId: staffId,
      assignmentId: assignmentId,
    );
  }

  Future<StaffApiModel> updateStaff(
    int id,
    Map<String, dynamic> data,
  ) {
    return _service.updateStaff(id, data);
  }

  Future<StaffApiModel> createStaff(
    Map<String, dynamic> data,
  ) {
    return _service.createStaff(data);
  }

  Future<void> deleteStaff(int id) {
    return _service.deleteStaff(id);
  }
}

