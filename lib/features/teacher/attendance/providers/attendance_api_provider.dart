import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cims/features/teacher/attendance/repository/attendance_repository.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository();
});

class AttendanceSessionsArgs {
  final int? subjectId;
  final int? sessionId;

  const AttendanceSessionsArgs({this.subjectId, this.sessionId});
}

final attendanceSessionsListProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, AttendanceSessionsArgs>(
  (ref, args) async {
    final repo = ref.read(attendanceRepositoryProvider);
    return repo.listSessions(subjectId: args.subjectId, sessionId: args.sessionId);
  },
);

final attendanceSessionProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, int>((ref, id) async {
  final repo = ref.read(attendanceRepositoryProvider);
  return repo.getSession(id);
});

final teacherAttendanceStatusProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repo = ref.read(attendanceRepositoryProvider);
  return repo.getTeacherStatus();
});

final adminAttendanceRecordsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, dateVal) async {
  final repo = ref.read(attendanceRepositoryProvider);
  return repo.getAdminAttendanceRecords(dateVal: dateVal);
});
