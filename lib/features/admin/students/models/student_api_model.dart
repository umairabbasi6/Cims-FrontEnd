class StudentProgramRef {
  final int id;
  final String name;
  final String code;
  final String programType;
  final int totalStages;
  final String award;

  const StudentProgramRef({
    required this.id,
    required this.name,
    required this.code,
    required this.programType,
    required this.totalStages,
    required this.award,
  });

  factory StudentProgramRef.fromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return const StudentProgramRef(
        id: 0,
        name: '',
        code: '',
        programType: '',
        totalStages: 0,
        award: '',
      );
    }
    return StudentProgramRef(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      programType: json['program_type'] as String? ?? '',
      totalStages: json['total_stages'] as int? ?? 0,
      award: json['award'] as String? ?? '',
    );
  }
}

class StudentAdmissionSessionRef {
  final int id;
  final String name;

  const StudentAdmissionSessionRef({
    required this.id,
    required this.name,
  });

  factory StudentAdmissionSessionRef.fromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return const StudentAdmissionSessionRef(
        id: 0,
        name: '',
      );
    }
    return StudentAdmissionSessionRef(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
    );
  }
}

class StudentApiModel {
  final int id;
  final String registrationNumber;
  final String studentIdCode;
  final String fullName;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final String? address;
  final String? userId;
  final String? dateOfBirth;
  final String? guardianName;
  final String? guardianPhone;
  final int currentStage;
  final String status;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? graduationDate;
  final StudentProgramRef? program;
  final StudentAdmissionSessionRef? admissionSession;

  const StudentApiModel({
    required this.id,
    required this.registrationNumber,
    required this.studentIdCode,
    required this.fullName,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phone,
    this.address,
    this.userId,
    this.dateOfBirth,
    this.guardianName,
    this.guardianPhone,
    required this.currentStage,
    required this.status,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
    this.graduationDate,
    this.program,
    this.admissionSession,
  });

  factory StudentApiModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return StudentApiModel(
      id: json['id'] as int,
      registrationNumber:
        json['registration_number'] as String? ?? '',
      studentIdCode: json['student_id_code'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      userId: json['user_id'] as String?,
      dateOfBirth: json['date_of_birth'] as String?,
      guardianName: json['guardian_name'] as String?,
      guardianPhone: json['guardian_phone'] as String?,
      address: json['address'] as String?,
      currentStage: json['current_stage'] as int? ?? 0,
      status: json['status'] as String? ?? 'active',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(
        json['created_at'] as String,
      ),
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
      graduationDate: json['graduation_date'] as String?,
      program: json['program'] != null
          ? StudentProgramRef.fromJson(
              json['program'] as Map<String, dynamic>,
            )
          : null,
      admissionSession: json['admission_session'] != null
          ? StudentAdmissionSessionRef.fromJson(
              json['admission_session']
                  as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class StudentListResponse {
  final int total;
  final List<StudentApiModel> students;

  const StudentListResponse({
    required this.total,
    required this.students,
  });

  factory StudentListResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    final raw = json['students'] as List<dynamic>? ?? [];
    return StudentListResponse(
      total: json['total'] as int? ?? raw.length,
      students: raw
          .map(
            (e) => StudentApiModel.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}

class StudentHistorySessionRef {
  final int id;
  final String name;

  const StudentHistorySessionRef({
    required this.id,
    required this.name,
  });

  factory StudentHistorySessionRef.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const StudentHistorySessionRef(id: 0, name: '');
    }
    return StudentHistorySessionRef(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
    );
  }
}

class StudentHistoryItem {
  final int id;
  final int stage;
  final String status;
  final String remarks;
  final DateTime createdAt;
  final StudentHistorySessionRef? session;

  const StudentHistoryItem({
    required this.id,
    required this.stage,
    required this.status,
    required this.remarks,
    required this.createdAt,
    this.session,
  });

  factory StudentHistoryItem.fromJson(Map<String, dynamic> json) {
    return StudentHistoryItem(
      id: json['id'] as int,
      stage: json['stage'] as int? ?? 0,
      status: json['status'] as String? ?? '',
      remarks: json['remarks'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      session: json['session'] != null
          ? StudentHistorySessionRef.fromJson(json['session'] as Map<String, dynamic>)
          : null,
    );
  }
}

class StudentHistoryResponse {
  final String studentIdCode;
  final String fullName;
  final int total;
  final List<StudentHistoryItem> history;

  const StudentHistoryResponse({
    required this.studentIdCode,
    required this.fullName,
    required this.total,
    required this.history,
  });

  factory StudentHistoryResponse.fromJson(Map<String, dynamic> json) {
    final rawHistory = json['history'] as List<dynamic>? ?? [];
    return StudentHistoryResponse(
      studentIdCode: json['student_id_code'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      total: json['total'] as int? ?? rawHistory.length,
      history: rawHistory
          .map((e) => StudentHistoryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
