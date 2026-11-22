import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cims/features/admin/enrollments/models/enrollment_model.dart';
import 'package:cims/features/admin/enrollments/repository/enrollment_repository.dart';

final enrollmentRepositoryProvider =
    Provider<EnrollmentRepository>((ref) {
  return EnrollmentRepository();
});

class EnrollmentFilterArgs {
  final int? sessionId;
  final int? stage;
  final String? status;
  final String? search;

  const EnrollmentFilterArgs({
    this.sessionId,
    this.stage,
    this.status,
    this.search,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EnrollmentFilterArgs &&
          runtimeType == other.runtimeType &&
          sessionId == other.sessionId &&
          stage == other.stage &&
          status == other.status &&
          search == other.search;

  @override
  int get hashCode =>
      sessionId.hashCode ^ stage.hashCode ^ status.hashCode ^ search.hashCode;
}

final enrollmentsTypedListProvider = FutureProvider.autoDispose
    .family<List<EnrollmentModel>, EnrollmentFilterArgs>(
  (ref, args) async {
    final repo = ref.read(enrollmentRepositoryProvider);
    final list = await repo.listEnrollmentsTyped(
      sessionId: args.sessionId,
      stage: args.stage,
      status: args.status,
    );
    if (args.search != null && args.search!.trim().isNotEmpty) {
      final q = args.search!.trim().toLowerCase();
      return list.where((e) {
        return e.student.fullName.toLowerCase().contains(q) ||
            e.student.studentIdCode.toLowerCase().contains(q) ||
            e.subject.name.toLowerCase().contains(q) ||
            e.subject.code.toLowerCase().contains(q);
      }).toList();
    }
    return list;
  },
);


final enrollmentsListProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, int?>(
  (ref, sessionId) async {
    final repo = ref.read(enrollmentRepositoryProvider);
    return repo.listEnrollments(sessionId: sessionId);
  },
);

final subjectEnrollmentsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, SubjectEnrollmentsArgs>(
  (ref, args) async {
    final repo = ref.read(enrollmentRepositoryProvider);
    return repo.subjectEnrollments(args.subjectId, sessionId: args.sessionId);
  },
);

class SubjectEnrollmentsArgs {
  final int subjectId;
  final int? sessionId;

  const SubjectEnrollmentsArgs({required this.subjectId, this.sessionId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubjectEnrollmentsArgs &&
          runtimeType == other.runtimeType &&
          subjectId == other.subjectId &&
          sessionId == other.sessionId;

  @override
  int get hashCode => subjectId.hashCode ^ sessionId.hashCode;
}

class StudentEnrollmentsArgs {
  final int studentId;
  final int? sessionId;

  const StudentEnrollmentsArgs({required this.studentId, this.sessionId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentEnrollmentsArgs &&
          runtimeType == other.runtimeType &&
          studentId == other.studentId &&
          sessionId == other.sessionId;

  @override
  int get hashCode => studentId.hashCode ^ sessionId.hashCode;
}

final studentEnrollmentsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, StudentEnrollmentsArgs>(
  (ref, args) async {
    final repo = ref.read(enrollmentRepositoryProvider);
    return repo.studentEnrollments(args.studentId, sessionId: args.sessionId);
  },
);

final enrollmentStatusOptionsProvider = FutureProvider.autoDispose<List<String>>(
  (ref) async {
    final repo = ref.read(enrollmentRepositoryProvider);
    return repo.getStatusOptions();
  },
);
