import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cims/features/admin/enrollments/repository/enrollment_repository.dart';

final enrollmentRepositoryProvider =
    Provider<EnrollmentRepository>((ref) {
  return EnrollmentRepository();
});

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
