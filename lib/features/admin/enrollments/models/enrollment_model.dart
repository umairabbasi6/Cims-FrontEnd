import 'package:intl/intl.dart';

class StudentMinimalModel {
  final int id;
  final String studentIdCode;
  final String fullName;

  const StudentMinimalModel({
    required this.id,
    required this.studentIdCode,
    required this.fullName,
  });

  factory StudentMinimalModel.fromJson(Map<String, dynamic> json) {
    return StudentMinimalModel(
      id: json['id'] as int? ?? 0,
      studentIdCode: json['student_id_code'] as String? ?? '—',
      fullName: json['full_name'] as String? ?? '—',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'student_id_code': studentIdCode,
    'full_name': fullName,
  };
}

class SubjectMinimalModel {
  final int id;
  final String name;
  final String code;
  final int stage;
  final bool hasPractical;

  const SubjectMinimalModel({
    required this.id,
    required this.name,
    required this.code,
    required this.stage,
    required this.hasPractical,
  });

  factory SubjectMinimalModel.fromJson(Map<String, dynamic> json) {
    return SubjectMinimalModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '—',
      code: json['code'] as String? ?? '—',
      stage: json['stage'] as int? ?? 1,
      hasPractical: json['has_practical'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'code': code,
    'stage': stage,
    'has_practical': hasPractical,
  };
}

class SessionMinimalModel {
  final int id;
  final String name;

  const SessionMinimalModel({
    required this.id,
    required this.name,
  });

  factory SessionMinimalModel.fromJson(Map<String, dynamic> json) {
    return SessionMinimalModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '—',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
  };
}

class EnrollmentModel {
  final int id;
  final int attemptNumber;
  final String status; // ongoing | completed | dropped | absent | suspended | canceled
  final DateTime? createdAt;
  final StudentMinimalModel student;
  final SubjectMinimalModel subject;
  final SessionMinimalModel session;

  const EnrollmentModel({
    required this.id,
    required this.attemptNumber,
    required this.status,
    this.createdAt,
    required this.student,
    required this.subject,
    required this.session,
  });

  factory EnrollmentModel.fromJson(Map<String, dynamic> json) {
    DateTime? dt;
    if (json['created_at'] != null) {
      dt = DateTime.tryParse(json['created_at'].toString());
    }

    return EnrollmentModel(
      id: json['id'] as int? ?? 0,
      attemptNumber: json['attempt_number'] as int? ?? 1,
      status: json['status'] as String? ?? 'ongoing',
      createdAt: dt,
      student: StudentMinimalModel.fromJson(
        json['student'] is Map<String, dynamic>
            ? json['student'] as Map<String, dynamic>
            : (json['student'] as Map?)?.cast<String, dynamic>() ?? {},
      ),
      subject: SubjectMinimalModel.fromJson(
        json['subject'] is Map<String, dynamic>
            ? json['subject'] as Map<String, dynamic>
            : (json['subject'] as Map?)?.cast<String, dynamic>() ?? {},
      ),
      session: SessionMinimalModel.fromJson(
        json['session'] is Map<String, dynamic>
            ? json['session'] as Map<String, dynamic>
            : (json['session'] as Map?)?.cast<String, dynamic>() ?? {},
      ),
    );
  }

  String get formattedDate {
    if (createdAt == null) return '—';
    return DateFormat('dd MMM yyyy').format(createdAt!);
  }

  bool get isOngoing => status.toLowerCase() == 'ongoing';
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isDropped => status.toLowerCase() == 'dropped';
  bool get isAbsent => status.toLowerCase() == 'absent';
}

class BulkEnrollResultModel {
  final String message;
  final int enrolled;
  final int skipped;
  final int totalStudents;
  final int totalSubjects;

  const BulkEnrollResultModel({
    required this.message,
    required this.enrolled,
    required this.skipped,
    required this.totalStudents,
    required this.totalSubjects,
  });

  factory BulkEnrollResultModel.fromJson(Map<String, dynamic> json) {
    return BulkEnrollResultModel(
      message: json['message'] as String? ?? 'Bulk enrollment completed',
      enrolled: json['enrolled'] as int? ?? 0,
      skipped: json['skipped'] as int? ?? 0,
      totalStudents: json['total_students'] as int? ?? 0,
      totalSubjects: json['total_subjects'] as int? ?? 0,
    );
  }
}
