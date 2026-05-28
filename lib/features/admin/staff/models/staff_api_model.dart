class StaffDepartmentRef {
  final int id;
  final String name;
  final String code;

  const StaffDepartmentRef({
    required this.id,
    required this.name,
    required this.code,
  });

  factory StaffDepartmentRef.fromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return const StaffDepartmentRef(
        id: 0,
        name: '',
        code: '',
      );
    }
    return StaffDepartmentRef(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
    );
  }
}

class StaffApiModel {
  final int id;
  final String staffIdCode;
  final String fullName;
  final String firstName;
  final String lastName;
  final String category;
  final String designation;
  final String? qualification;
  final String? specialization;
  final String? email;
  final String? phone;
  final String? joiningDate;
  final bool isActive;
  final DateTime createdAt;
  final StaffDepartmentRef? department;

  const StaffApiModel({
    required this.id,
    required this.staffIdCode,
    required this.fullName,
    required this.firstName,
    required this.lastName,
    required this.category,
    required this.designation,
    this.qualification,
    this.specialization,
    this.email,
    this.phone,
    this.joiningDate,
    required this.isActive,
    required this.createdAt,
    this.department,
  });

  factory StaffApiModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return StaffApiModel(
      id: json['id'] as int,
      staffIdCode: json['staff_id_code'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      designation: json['designation'] as String? ?? '',
      qualification: json['qualification'] as String?,
      specialization: json['specialization'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      joiningDate: json['joining_date'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(
        json['created_at'] as String,
      ),
      department: json['department'] != null
          ? StaffDepartmentRef.fromJson(
              json['department'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class StaffListResponse {
  final int total;
  final List<StaffApiModel> staff;

  const StaffListResponse({
    required this.total,
    required this.staff,
  });

  factory StaffListResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    final raw = json['staff'] as List<dynamic>? ?? [];
    return StaffListResponse(
      total: json['total'] as int? ?? raw.length,
      staff: raw
          .map(
            (e) => StaffApiModel.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}
