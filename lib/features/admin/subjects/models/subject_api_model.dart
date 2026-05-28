class SubjectProgramRef {
  final int id;
  final String name;
  final String code;

  const SubjectProgramRef({
    required this.id,
    required this.name,
    required this.code,
  });

  factory SubjectProgramRef.fromJson(
    Map<String, dynamic> json,
  ) {
    return SubjectProgramRef(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
    );
  }
}

class SubjectAssignedTeacherRef {
  final int id;
  final String fullName;
  final int assignmentId;
  final String role;
  final String? section;

  const SubjectAssignedTeacherRef({
    required this.id,
    required this.fullName,
    required this.assignmentId,
    required this.role,
    this.section,
  });

  factory SubjectAssignedTeacherRef.fromJson(
    Map<String, dynamic> json,
  ) {
    return SubjectAssignedTeacherRef(
      id: json['id'] as int? ?? 0,
      fullName: json['full_name'] as String? ?? '',
      assignmentId: json['assignment_id'] as int? ?? 0,
      role: json['role'] as String? ?? 'THEORY',
      section: json['section'] as String?,
    );
  }
}

class SubjectApiModel {
  final int id;
  final String name;
  final String code;
  final int stage;
  final double creditHours;
  final bool hasPractical;
  final bool isActive;
  final DateTime createdAt;
  final SubjectProgramRef? program;
  final SubjectAssignedTeacherRef? assignedTeacher;

  const SubjectApiModel({
    required this.id,
    required this.name,
    required this.code,
    required this.stage,
    required this.creditHours,
    required this.hasPractical,
    required this.isActive,
    required this.createdAt,
    this.program,
    this.assignedTeacher,
  });

  factory SubjectApiModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return SubjectApiModel(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String,
      stage: json['stage'] as int? ?? 0,
      creditHours:
          (json['credit_hours'] as num?)?.toDouble() ?? 0,
      hasPractical: json['has_practical'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(
        json['created_at'] as String,
      ),
      program: json['program'] != null
          ? SubjectProgramRef.fromJson(
              json['program'] as Map<String, dynamic>,
            )
          : null,
      assignedTeacher: json['assigned_teacher'] != null
          ? SubjectAssignedTeacherRef.fromJson(
              json['assigned_teacher'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class SubjectListResponse {
  final int total;
  final List<SubjectApiModel> subjects;

  const SubjectListResponse({
    required this.total,
    required this.subjects,
  });

  factory SubjectListResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    final raw = json['subjects'] as List<dynamic>? ?? [];
    return SubjectListResponse(
      total: json['total'] as int? ?? raw.length,
      subjects: raw
          .map(
            (e) => SubjectApiModel.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}
