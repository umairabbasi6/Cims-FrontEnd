import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cims/features/teacher/attendance/providers/attendance_api_provider.dart';
import 'package:cims/features/admin/fees/providers/fees_api_provider.dart';
import 'package:cims/features/admin/sessions/providers/session_provider.dart';
import 'package:cims/features/timetable/providers/timetable_provider.dart';
import 'package:cims/features/student/providers/student_program_provider.dart';
import 'package:cims/features/teacher/results/providers/results_api_provider.dart';

class SubjectPerformanceData {
  final String subjectName;
  final String attendance;
  final String grade;

  SubjectPerformanceData(this.subjectName, this.attendance, this.grade);
}

class DashboardUpcomingClass {
  final String code;
  final String subject;
  final String courseCode;
  final String teacher;
  final String day;
  final String time;
  final String room;
  final String type;

  DashboardUpcomingClass(
    this.code,
    this.subject,
    this.courseCode,
    this.teacher,
    this.day,
    this.time,
    this.room,
    this.type,
  );
}

class StudentDashboardData {
  final StudentProgramOverview overview;
  final double attendancePercentage;
  final int totalAttended;
  final int totalSessions;
  final int feeBalance;
  final String feeDueDate;
  final int feePaid;
  final int feeTotal;
  final List<SubjectPerformanceData> subjectPerformance;
  final List<DashboardUpcomingClass> upcomingClasses;

  StudentDashboardData({
    required this.overview,
    required this.attendancePercentage,
    required this.totalAttended,
    required this.totalSessions,
    required this.feeBalance,
    required this.feeDueDate,
    required this.feePaid,
    required this.feeTotal,
    required this.subjectPerformance,
    required this.upcomingClasses,
  });
}

final studentDashboardProvider = FutureProvider.autoDispose<StudentDashboardData?>(
  (ref) async {
    final overview = await ref.watch(studentProgramOverviewProvider.future);
    if (overview == null) return null;

    final student = overview.student;
    final session = await ref.watch(currentAcademicSessionProvider.future);
    final sessionId = session?.id;

    double attendancePct = 0.0;
    int totalAttended = 0;
    int totalSessions = 0;
    
    int feeBalance = 0;
    String feeDueDate = 'N/A';
    int feePaid = 0;
    int feeTotal = 0;

    final subjectPerformance = <SubjectPerformanceData>[];
    final upcomingClasses = <DashboardUpcomingClass>[];

    if (sessionId != null) {
      // 1. Fetch Attendance
      try {
        final attendanceRepo = ref.read(attendanceRepositoryProvider);
        final report = await attendanceRepo.studentReport(
          student.id,
          sessionId: sessionId,
        );
        attendancePct = (report['percentage'] as num?)?.toDouble() ?? 0.0;
        totalAttended = (report['total_present'] as num?)?.toInt() ?? 0;
        totalSessions = (report['total_sessions'] as num?)?.toInt() ?? 0;

        List<Map<String, dynamic>> results = [];
        try {
          final resultsRepo = ref.read(resultsRepositoryProvider);
          results = await resultsRepo.studentResults(
            student.id,
            sessionId: sessionId,
          );
        } catch (_) {}

        final subjectsData = report['subjects'] as List<dynamic>? ?? [];
        for (var i = 0; i < subjectsData.length && i < 4; i++) {
          final sub = subjectsData[i] as Map<String, dynamic>;
          final name = sub['subject_name']?.toString() ?? 'Subject';
          final attPct = (sub['percentage'] as num?)?.toDouble() ?? 0.0;
          
          String gradeVal = '—';
          if (results.isNotEmpty) {
            final matches = results.where((res) {
              final enroll = res['enrollment'] as Map<String, dynamic>?;
              final subject = enroll?['subject'] as Map<String, dynamic>?;
              final resSubName = subject?['name']?.toString() ?? '';
              return resSubName.toLowerCase() == name.toLowerCase();
            });
            if (matches.isNotEmpty) {
              gradeVal = matches.first['grade_letter']?.toString() ?? '—';
            }
          }

          subjectPerformance.add(
            SubjectPerformanceData(name, '${attPct.toStringAsFixed(0)}% attendance', gradeVal),
          );
        }
      } catch (_) {}

      // 2. Fetch Fees
      try {
        final feesRepo = ref.read(feesRepositoryProvider);
        final dues = await feesRepo.studentDues(
          student.id,
          sessionId: sessionId,
        );
        feeBalance = (dues['balance'] as num?)?.toInt() ?? 0;
        feePaid = (dues['paid'] as num?)?.toInt() ?? 0;
        feeTotal = (dues['total'] as num?)?.toInt() ?? feePaid + feeBalance;
        feeDueDate = dues['due_date']?.toString() ?? 'N/A';
      } catch (_) {}

      // 3. Fetch Timetable
      try {
        final timetableRepo = ref.read(timetableRepositoryProvider);
        final timetable = await timetableRepo.getWeekly(
          sessionId: sessionId,
          stage: student.currentStage,
        );
        
        final slots = timetable.days.expand((d) => d.slots).toList();
        // Just take the first few slots as upcoming classes
        for (var i = 0; i < slots.length && i < 4; i++) {
          final slot = slots[i];
          upcomingClasses.add(
            DashboardUpcomingClass(
              slot.subjectName.isNotEmpty ? slot.subjectName.substring(0, 2).toUpperCase() : 'CC',
              slot.subjectName,
              '${overview.programCode}-${slot.id}',
              slot.staffName,
              slot.dayOfWeek,
              '${slot.startTime} - ${slot.endTime}',
              slot.room ?? 'TBA',
              slot.classType,
            ),
          );
        }
      } catch (_) {}
    }

    // Fallback if no subject performance
    if (subjectPerformance.isEmpty) {
      for (var stage in overview.stages) {
         if (stage.stage == student.currentStage) {
           final subjs = stage.subjectsLabel.split(', ');
           for (var s in subjs) {
             if (s.trim().isEmpty || s == '—') continue;
             subjectPerformance.add(SubjectPerformanceData(s.trim(), 'N/A attendance', '-'));
           }
           break;
         }
      }
    }

    return StudentDashboardData(
      overview: overview,
      attendancePercentage: attendancePct,
      totalAttended: totalAttended,
      totalSessions: totalSessions,
      feeBalance: feeBalance,
      feeDueDate: feeDueDate,
      feePaid: feePaid,
      feeTotal: feeTotal,
      subjectPerformance: subjectPerformance,
      upcomingClasses: upcomingClasses,
    );
  },
);
