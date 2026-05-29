import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'package:cims/core/session/app_session.dart';
import 'package:cims/features/auth/providers/auth_provider.dart';
import 'package:cims/features/admin/students/models/student_api_model.dart';
import 'package:cims/features/admin/students/repository/student_repository.dart';
import 'package:cims/features/admin/staff/providers/staff_provider.dart';
import 'package:cims/features/admin/sessions/providers/session_provider.dart';
import 'package:cims/features/admin/enrollments/providers/enrollment_provider.dart';

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

    final isTeacher = AppSession.currentRole == 'teacher';
    if (isTeacher) {
      final staff = await ref.watch(currentStaffProvider.future);
      final session = await ref.watch(currentAcademicSessionProvider.future);
      if (staff != null && session != null) {
        try {
          final subjectsRes = await ref.read(staffRepositoryProvider).getStaffSubjects(staff.id, sessionId: session.id);
          final assignments = subjectsRes['assignments'] as List? ?? [];
          final subjectIds = assignments.map((a) => (a['subject'] as Map)['id'] as int).toList();
          
          if (subjectIds.isEmpty) {
            return <StudentApiModel>[];
          }

          final List<StudentApiModel> teacherStudents = [];
          final Set<int> studentIds = {};
          
          final enrollmentsRepo = ref.read(enrollmentRepositoryProvider);
          for (final subId in subjectIds) {
            final enrollments = await enrollmentsRepo.subjectEnrollments(subId, sessionId: session.id);
            for (final e in enrollments) {
              final studJson = e['student'];
              if (studJson != null) {
                final student = StudentApiModel.fromJson(studJson as Map<String, dynamic>);
                if (studentIds.add(student.id)) {
                  teacherStudents.add(student);
                }
              }
            }
          }

          return teacherStudents.where((s) {
            if (programId != null && s.program?.id != programId) return false;
            if (sessionId != null && s.admissionSession?.id != sessionId) return false;
            if (status != null && s.status != status) return false;
            return true;
          }).toList();
        } catch (e) {
          return <StudentApiModel>[];
        }
      }
    }

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
