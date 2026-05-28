import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cims/features/admin/fees/repository/fees_repository.dart';
import 'package:cims/features/admin/sessions/providers/session_provider.dart';

class DateFilterState {
  final DateTime? startDate;
  final DateTime? endDate;

  const DateFilterState({this.startDate, this.endDate});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateFilterState &&
          runtimeType == other.runtimeType &&
          startDate == other.startDate &&
          endDate == other.endDate;

  @override
  int get hashCode => startDate.hashCode ^ endDate.hashCode;
}

class PaginationState {
  final int page;
  final int limit;

  const PaginationState({this.page = 1, this.limit = 15});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaginationState &&
          runtimeType == other.runtimeType &&
          page == other.page &&
          limit == other.limit;

  @override
  int get hashCode => page.hashCode ^ limit.hashCode;
}

final feesRepositoryProvider = Provider<FeesRepository>((ref) {
  return FeesRepository();
});

final feesDashboardProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repo = ref.read(feesRepositoryProvider);
  return repo.getAdminDashboard();
});

final recentTransactionsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, (DateFilterState, PaginationState)>((ref, params) async {
  final (filter, pagination) = params;
  final repo = ref.read(feesRepositoryProvider);
  
  String? startStr;
  String? endStr;
  if (filter.startDate != null) {
    startStr = "${filter.startDate!.year}-${filter.startDate!.month.toString().padLeft(2, '0')}-${filter.startDate!.day.toString().padLeft(2, '0')}";
  }
  if (filter.endDate != null) {
    endStr = "${filter.endDate!.year}-${filter.endDate!.month.toString().padLeft(2, '0')}-${filter.endDate!.day.toString().padLeft(2, '0')}";
  }

  return repo.listPayments(
    startDate: startStr, 
    endDate: endStr,
    page: pagination.page,
    limit: pagination.limit,
  );
});

final pendingAssignmentsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.read(feesRepositoryProvider);
  return repo.listAssignments(statusIn: 'PENDING,PARTIAL,OVERDUE');
});

final feesTopDefaultersProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final session = await ref.watch(currentAcademicSessionProvider.future);
  final sessionId = session?.id;
  if (sessionId == null) {
    return {'total': 0, 'defaulters': []};
  }
  final repo = ref.read(feesRepositoryProvider);
  return repo.defaulters(sessionId: sessionId);
});

class StudentFeeDashboardParam {
  final int studentId;
  final int? sessionId;

  const StudentFeeDashboardParam({
    required this.studentId,
    this.sessionId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentFeeDashboardParam &&
          runtimeType == other.runtimeType &&
          studentId == other.studentId &&
          sessionId == other.sessionId;

  @override
  int get hashCode => studentId.hashCode ^ sessionId.hashCode;
}

final studentFeeDashboardProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, StudentFeeDashboardParam>((ref, param) async {
  final repo = ref.read(feesRepositoryProvider);
  return repo.getStudentFeeDashboard(param.studentId, sessionId: param.sessionId);
});

final studentPaymentsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, StudentFeeDashboardParam>((ref, param) async {
  final repo = ref.read(feesRepositoryProvider);
  return repo.studentPayments(param.studentId, sessionId: param.sessionId);
});
