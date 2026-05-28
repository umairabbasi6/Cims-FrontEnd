import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cims/features/teacher/attendance/providers/attendance_api_provider.dart';
import 'package:cims/features/admin/sessions/providers/session_provider.dart';
import 'package:cims/features/admin/subjects/providers/subject_provider.dart';
import 'package:cims/features/student/providers/student_program_provider.dart';

class StudentAttendanceSubjectRow {
  final String initials;
  final String name;
  final String code;
  final int held;
  final int present;
  final int absent;
  final int late;
  final double percentage;
  final String status;

  StudentAttendanceSubjectRow({
    required this.initials,
    required this.name,
    required this.code,
    required this.held,
    required this.present,
    required this.absent,
    required this.late,
    required this.percentage,
    required this.status,
  });
}

class StudentAttendanceData {
  final double overallPercentage;
  final int sessionsHeld;
  final int presentCount;
  final int absentCount;
  final List<StudentAttendanceSubjectRow> subjects;

  StudentAttendanceData({
    required this.overallPercentage,
    required this.sessionsHeld,
    required this.presentCount,
    required this.absentCount,
    required this.subjects,
  });
}

final studentAttendanceProvider = FutureProvider.autoDispose<StudentAttendanceData?>(
  (ref) async {
    final overview = await ref.watch(studentProgramOverviewProvider.future);
    if (overview == null) return null;

    final student = overview.student;
    final session = await ref.watch(currentAcademicSessionProvider.future);
    final sessionId = session?.id;

    if (sessionId == null) return null;

    final attendanceRepo = ref.read(attendanceRepositoryProvider);
    final report = await attendanceRepo.studentReport(
      student.id,
      sessionId: sessionId,
    );

    final subjectsList = await ref.read(subjectRepositoryProvider).listSubjects(programId: student.program?.id);

    final subjectsData = report['subjects'] as List<dynamic>? ?? [];
    final overallPct = (report['overall_percentage'] ?? report['percentage'] as num?)?.toDouble() ?? 0.0;
    
    int totalHeld = 0;
    int totalPresent = 0;
    int totalAbsent = 0;

    final mappedRows = <StudentAttendanceSubjectRow>[];

    for (final item in subjectsData) {
      final sub = item as Map<String, dynamic>;
      final subId = sub['subject_id'] as int?;
      final subName = sub['subject_name']?.toString() ?? 'Subject';
      final int held = ((sub['total_sessions'] ?? sub['held'] ?? 0) as num).toInt();
      final int present = ((sub['present'] ?? 0) as num).toInt();
      final int absent = ((sub['absent'] ?? 0) as num).toInt();
      final int lateCount = ((sub['late'] ?? 0) as num).toInt();
      final double pct = ((sub['percentage'] ?? 0.0) as num).toDouble();
      final isShortage = sub['shortage'] as bool? ?? (pct < 75.0);

      totalHeld += held;
      totalPresent += present;
      totalAbsent += absent;

      // Find the code
      String code = '';
      if (subId != null) {
        final matches = subjectsList.where((s) => s.id == subId).toList();
        if (matches.isNotEmpty) {
          code = matches.first.code;
        } else {
          final matchesByName = subjectsList.where((s) => s.name.toLowerCase() == subName.toLowerCase()).toList();
          if (matchesByName.isNotEmpty) {
            code = matchesByName.first.code;
          } else if (subjectsList.isNotEmpty) {
            code = subjectsList.first.code;
          }
        }
      }

      if (code.isEmpty) {
        // Generate an initials-based code fallback
        code = subName.split(' ').map((s) => s.isNotEmpty ? s[0] : '').join().toUpperCase();
      }

      final initials = subName.trim().isEmpty
          ? 'SUB'
          : subName.trim().split(' ').map((s) => s.isEmpty ? '' : s[0]).take(2).join().toUpperCase();

      mappedRows.add(
        StudentAttendanceSubjectRow(
          initials: initials,
          name: subName,
          code: code,
          held: held,
          present: present,
          absent: absent,
          late: lateCount,
          percentage: pct,
          status: isShortage ? 'Watch' : 'Good',
        ),
      );
    }

    // fallback overall metrics
    final sessionsHeld = (report['total_sessions'] ?? report['sessions_held'] as num?)?.toInt() ?? totalHeld;
    final presentCount = (report['total_present'] ?? report['present_count'] as num?)?.toInt() ?? totalPresent;
    final absentCount = (report['total_absent'] ?? report['absent_count'] as num?)?.toInt() ?? totalAbsent;

    return StudentAttendanceData(
      overallPercentage: overallPct,
      sessionsHeld: sessionsHeld,
      presentCount: presentCount,
      absentCount: absentCount,
      subjects: mappedRows,
    );
  },
);
