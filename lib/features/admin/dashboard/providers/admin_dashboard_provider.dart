import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cims/features/admin/students/providers/student_provider.dart';
import 'package:cims/features/admin/staff/providers/staff_provider.dart';
import 'package:cims/features/admin/fees/providers/fees_api_provider.dart';
import 'package:cims/features/admin/sessions/providers/session_provider.dart';
import 'package:cims/features/admin/departments/providers/department_provider.dart';

class AdminDashboardData {
  final int totalStudents;
  final int totalStaff;
  final double totalFeeCollection;
  final double totalPendingDues;
  final List<Map<String, dynamic>> enrollmentTrend;
  final List<Map<String, dynamic>> departmentDistribution;
  final List<Map<String, dynamic>> feeByProgram;
  final String currentSessionName;

  AdminDashboardData({
    required this.totalStudents,
    required this.totalStaff,
    required this.totalFeeCollection,
    required this.totalPendingDues,
    required this.enrollmentTrend,
    required this.departmentDistribution,
    required this.feeByProgram,
    required this.currentSessionName,
  });
}

final adminDashboardProvider = FutureProvider.autoDispose<AdminDashboardData>((ref) async {
  final students = await ref.watch(studentsListProvider.future);
  final staff = await ref.watch(staffListProvider(null).future);
  final session = await ref.watch(currentAcademicSessionProvider.future);
  final departments = await ref.watch(departmentsProvider.future);
  
  final sessionId = session?.id;
  double pendingDues = 0;
  
  if (sessionId != null) {
    try {
      final defaultersRes = await ref.read(feesRepositoryProvider).defaulters(sessionId: sessionId);
      final defaultersList = defaultersRes['defaulters'] as List? ?? [];
      for (var d in defaultersList) {
        pendingDues += (d['total_due'] as num?)?.toDouble() ?? 0;
      }
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

  // Mocked trend data (as API doesn't provide historical snapshots easily)
  final enrollmentTrend = [
    {'month': 'Sep', 'students': 850, 'fees': 4.2},
    {'month': 'Oct', 'students': 920, 'fees': 4.8},
    {'month': 'Nov', 'students': 980, 'fees': 5.5},
    {'month': 'Dec', 'students': 1050, 'fees': 6.2},
    {'month': 'Jan', 'students': 1100, 'fees': 7.1},
    {'month': 'Feb', 'students': 1140, 'fees': 7.8},
    {'month': 'Mar', 'students': 1184, 'fees': 8.4},
  ];

  return AdminDashboardData(
    totalStudents: students.length,
    totalStaff: staff.length,
    totalFeeCollection: 8.4 * 1000000, // Still mocked as no aggregate collection endpoint
    totalPendingDues: pendingDues,
    enrollmentTrend: enrollmentTrend,
    departmentDistribution: departmentDistribution,
    feeByProgram: programFees.values.toList(),
    currentSessionName: session?.name ?? 'Unknown Session',
  );
});
