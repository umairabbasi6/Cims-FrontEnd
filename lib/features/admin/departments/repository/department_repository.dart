import 'package:cims/features/admin/departments/models/create_department_request.dart';
import 'package:cims/features/admin/departments/models/department_response.dart';
import 'package:cims/features/admin/departments/models/update_department_request.dart';

import 'package:cims/features/admin/departments/services/department_service.dart';

class DepartmentRepository {
  final DepartmentService _service =
      DepartmentService();

  Future<DepartmentListResponse> getDepartments({
    String? search,
    String? category,
    bool? isActive,
  }) {
    return _service.getDepartments(
      search: search,
      category: category,
      isActive: isActive,
      limit: 200,
    );
  }

  Future createDepartment(
    CreateDepartmentRequest request,
  ) {
    return _service.createDepartment(
      request,
    );
  }

  Future updateDepartment({
    required int id,
    required UpdateDepartmentRequest request,
  }) {
    return _service.updateDepartment(
      id: id,
      request: request,
    );
  }

  Future deleteDepartment(
    int id,
  ) {
    return _service.deleteDepartment(id);
  }
}