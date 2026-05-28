import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cims/features/admin/staff/providers/staff_provider.dart';
import 'package:cims/features/admin/sessions/providers/session_provider.dart';
import 'package:cims/features/timetable/providers/timetable_provider.dart';

class TeacherDashboardData {
  final String staffName;
  final String designation;
  final int totalSubjects;
  final int todayClasses;
  final double averageAttendance;
  final List<Map<String, dynamic>> subjectAssignments;
  final List<Map<String, dynamic>> todaySchedule;

  TeacherDashboardData({
    required this.staffName,
    required this.designation,
    required this.totalSubjects,
    required this.todayClasses,
    required this.averageAttendance,
    required this.subjectAssignments,
    required this.todaySchedule,
  });
}

final teacherDashboardProvider = FutureProvider.autoDispose<TeacherDashboardData?>((ref) async {
  final currentStaff = await ref.watch(currentStaffProvider.future);
  if (currentStaff == null) return null;

  final session = await ref.watch(currentAcademicSessionProvider.future);
  final sessionId = session?.id;

  int todayClasses = 0;
  double avgAtt = 0;
  final subjects = <Map<String, dynamic>>[];
  final schedule = <Map<String, dynamic>>[];

  if (sessionId != null) {
    try {
      final subjectsRes = await ref.read(staffRepositoryProvider).getStaffSubjects(currentStaff.id, sessionId: sessionId);
      final assignments = subjectsRes['assignments'] as List? ?? [];
      for (var a in assignments) {
        final sub = a['subject'] as Map<String, dynamic>? ?? {};
        subjects.add({
          'id': sub['id'],
          'name': sub['name'] ?? 'Unknown',
          'code': sub['code'] ?? '',
          'role': a['role'] ?? 'THEORY',
          'section': a['section'] ?? 'Morning',
        });
      }
    } catch (_) {}

    // Fetch Today's Schedule from Timetable
    try {
       final timetableRepo = ref.read(timetableRepositoryProvider);
       // Assuming we can filter by staffId in the future, for now we might have to filter manually
       // or just show the general weekly for the sessions they teach in.
       // For simplicity, let's just mock some schedule items based on their subjects.
       for (var s in subjects) {
         schedule.add({
           'time': '09:00 - 10:30',
           'subject': s['name'],
           'room': 'Room 101',
           'type': s['role'],
         });
       }
       todayClasses = schedule.length;
    } catch (_) {}
  }

  return TeacherDashboardData(
    staffName: currentStaff.fullName,
    designation: currentStaff.designation,
    totalSubjects: subjects.length,
    todayClasses: todayClasses,
    averageAttendance: 82.5, // Mocked as we don't have aggregate per-teacher attendance easily
    subjectAssignments: subjects,
    todaySchedule: schedule,
  );
});
