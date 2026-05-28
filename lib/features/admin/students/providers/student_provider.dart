import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'package:cims/features/auth/providers/auth_provider.dart';
import 'package:cims/features/admin/students/models/student_api_model.dart';
import 'package:cims/features/admin/students/repository/student_repository.dart';

final studentRepositoryProvider =
    Provider<StudentRepository>((ref) {
  return StudentRepository();
});

final studentProgramFilterProvider = StateProvider<int?>((ref) => null);
final studentSessionFilterProvider = StateProvider<int?>((ref) => null);
final studentStatusFilterProvider = StateProvider<String?>((ref) => null);

final studentsListProvider =
    FutureProvider.autoDispose<List<StudentApiModel>>(
  (ref) async {
    final programId = ref.watch(studentProgramFilterProvider);
    final sessionId = ref.watch(studentSessionFilterProvider);
    final status = ref.watch(studentStatusFilterProvider);

    final repo = ref.read(studentRepositoryProvider);
    
    // If status is graduated, we must pass isActive: false to fetch inactive students
    final bool? isActive = (status == 'graduated') ? false : null;

    return repo.listStudents(
      programId: programId,
      sessionId: sessionId,
      status: status,
      isActive: isActive,
    );
  },
);

/// Logged-in student's record (`GET /students/{id}`), resolved after login.
final currentStudentProvider =
    FutureProvider.autoDispose<StudentApiModel?>(
  (ref) async {
    final user = await ref.watch(currentUserProvider.future);
    if (user == null || user.role != 'student') return null;

    final repo = ref.read(studentRepositoryProvider);
    return repo.resolveCurrentStudent(user.username);
  },
);
