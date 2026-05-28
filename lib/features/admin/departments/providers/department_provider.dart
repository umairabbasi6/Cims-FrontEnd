import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cims/features/admin/departments/models/department_model.dart';

import 'package:cims/features/admin/departments/repository/department_repository.dart';

final departmentRepositoryProvider =
    Provider<DepartmentRepository>((ref) {
  return DepartmentRepository();
});

final departmentsProvider =
    FutureProvider<List<DepartmentModel>>(
  (ref) async {
    final repo = ref.read(
      departmentRepositoryProvider,
    );

    final response = await repo.getDepartments(
      isActive: null,
    );

    return response.departments;
  },
);