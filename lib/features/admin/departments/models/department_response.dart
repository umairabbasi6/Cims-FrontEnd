import 'package:cims/features/admin/departments/models/department_model.dart';

class DepartmentListResponse {
  final int total;
  final List<DepartmentModel> departments;

  DepartmentListResponse({
    required this.total,
    required this.departments,
  });

  factory DepartmentListResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return DepartmentListResponse(
      total: json['total'],

      departments:
          (json['departments'] as List)
              .map(
                (e) =>
                    DepartmentModel.fromJson(e),
              )
              .toList(),
    );
  }
}