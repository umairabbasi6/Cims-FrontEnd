import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cims/features/teacher/leaves/models/leave_model.dart';
import 'package:cims/features/teacher/leaves/services/leave_service.dart';

final leaveServiceProvider = Provider<LeaveService>((ref) {
  return LeaveService();
});

/// Fetches leaves for the current logged-in user (Teacher sees their own)
final teacherLeavesProvider = FutureProvider.autoDispose<List<LeaveRequestModel>>((ref) async {
  final service = ref.read(leaveServiceProvider);
  return service.listLeaves();
});

/// Fetches leaves for Admin review (optionally filtered by status, e.g., 'PENDING')
final adminLeavesProvider = FutureProvider.autoDispose.family<List<LeaveRequestModel>, String?>((ref, statusFilter) async {
  final service = ref.read(leaveServiceProvider);
  return service.listLeaves(statusFilter: statusFilter);
});
