import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cims/features/admin/students/providers/student_provider.dart';
import 'package:cims/features/admin/staff/providers/staff_provider.dart';
import 'package:cims/features/admin/fees/providers/fees_api_provider.dart';
import 'package:cims/features/admin/sessions/providers/session_provider.dart';
import 'package:cims/features/admin/departments/providers/department_provider.dart';
import 'package:cims/features/teacher/attendance/providers/attendance_api_provider.dart';

class AdminDashboardData {
  final int totalStudents;
  final int totalStaff;
  final double totalFeeCollection;
  final double totalPendingDues;
  final List<Map<String, dynamic>> enrollmentTrend;
  final List<Map<String, dynamic>> departmentDistribution;
  final List<Map<String, dynamic>> feeByProgram;
  final String currentSessionName;
  final int feeDefaultersCount;
  final int attendanceShortageCount;
  final int resultSheetsAwaitingCount;

  AdminDashboardData({
    required this.totalStudents,
    required this.totalStaff,
    required this.totalFeeCollection,
    required this.totalPendingDues,
    required this.enrollmentTrend,
    required this.departmentDistribution,
    required this.feeByProgram,
    required this.currentSessionName,
    required this.feeDefaultersCount,
    required this.attendanceShortageCount,
    required this.resultSheetsAwaitingCount,
  });
}

final adminDashboardProvider = FutureProvider.autoDispose<AdminDashboardData>((ref) async {
  final students = await ref.watch(studentsListProvider.future);
  final staff = await ref.watch(staffListProvider(null).future);
  final session = await ref.watch(currentAcademicSessionProvider.future);
  await ref.watch(departmentsProvider.future);
  
  final sessionId = session?.id;
  double pendingDues = 0;
  int feeDefaultersCount = 0;
  int attendanceShortageCount = 0;
  
  if (sessionId != null) {
    try {
      final defaultersRes = await ref.read(feesRepositoryProvider).defaulters(sessionId: sessionId);
      final defaultersList = defaultersRes['defaulters'] as List? ?? [];
      feeDefaultersCount = defaultersList.length;
      for (var d in defaultersList) {
        pendingDues += (d['total_due'] as num?)?.toDouble() ?? 0;
      }
    } catch (_) {}

    try {
      final shortage = await ref.read(attendanceRepositoryProvider).shortageList(sessionId: sessionId);
      final shortageList = shortage['students'] as List? ?? shortage['defaulters'] as List? ?? [];
      attendanceShortageCount = shortageList.length;
    } catch (_) {}
  }

  // Calculate Department Distribution
  final deptCounts = <String, int>{};
  for (var s in students) {
    final deptName = s.program?.name ?? 'Other';
    deptCounts[deptName] = (deptCounts[deptName] ?? 0) + 1;
  }
  final departmentDistribution = deptCounts.entries.map((e) => {
    'name': e.key,
    'count': e.value,
  }).toList();

  // Calculate Fee by Program (Table data)
  final programFees = <String, Map<String, dynamic>>{};
  for (var s in students) {
     final progName = s.program?.name ?? 'Unknown';
     if (!programFees.containsKey(progName)) {
       programFees[progName] = {
         'program': progName,
         'students': 0,
         'collected': 0.0, // Mocked for now as we don't have per-program aggregate collection
         'pending': 0.0,
       };
     }
     programFees[progName]!['students']++;
  }
  
  // Refine pending by program if possible
  if (sessionId != null) {
     try {
       final defaultersRes = await ref.read(feesRepositoryProvider).defaulters(sessionId: sessionId);
       final defaultersList = defaultersRes['defaulters'] as List? ?? [];
       for (var d in defaultersList) {
         final progName = d['program_name']?.toString() ?? 'Unknown';
         if (programFees.containsKey(progName)) {
           programFees[progName]!['pending'] += (d['total_due'] as num?)?.toDouble() ?? 0;
         }
       }
     } catch (_) {}
  }

  // Fetch real fee summary from backend
  double totalFeeCollection = 0.0;
  try {
    final summary = await ref.read(feesRepositoryProvider).getSummary(sessionId: sessionId);
    totalFeeCollection = (summary['total_collected'] as num?)?.toDouble() ?? 0.0;
    final summaryPending = (summary['total_pending'] as num?)?.toDouble() ?? 0.0;
    if (pendingDues == 0 && summaryPending > 0) {
      pendingDues = summaryPending;
    }
    if (feeDefaultersCount == 0) {
      feeDefaultersCount = (summary['defaulters_count'] as num?)?.toInt() ?? 0;
    }
    final byProg = summary['by_program'] as Map<String, dynamic>? ?? {};
    byProg.forEach((prog, amount) {
      if (programFees.containsKey(prog)) {
        programFees[prog]!['collected'] = (amount as num).toDouble();
      }
    });
  } catch (_) {}

  // Dynamic enrollment trend from active academic sessions
  final sessionsList = await ref.watch(sessionsListProvider.future);
  final enrollmentTrend = <Map<String, dynamic>>[];
  for (final s in sessionsList.reversed) {
    enrollmentTrend.add({
      'month': s.name,
      'students': s.studentsCount,
      'fees': double.parse((s.studentsCount > 0 ? (totalFeeCollection / 1000.0) : 0.0).toStringAsFixed(1)),
    });
  }
  if (enrollmentTrend.isEmpty) {
    enrollmentTrend.add({
      'month': session?.name ?? 'Current',
      'students': students.length,
      'fees': double.parse((totalFeeCollection / 1000.0).toStringAsFixed(1)),
    });
  }

  return AdminDashboardData(
    totalStudents: students.length,
    totalStaff: staff.length,
    totalFeeCollection: totalFeeCollection,
    totalPendingDues: pendingDues,
    enrollmentTrend: enrollmentTrend,
    departmentDistribution: departmentDistribution,
    feeByProgram: programFees.values.toList(),
    currentSessionName: session?.name ?? 'Unknown Session',
    feeDefaultersCount: feeDefaultersCount,
    attendanceShortageCount: attendanceShortageCount,
    resultSheetsAwaitingCount: 0,
  );
});
