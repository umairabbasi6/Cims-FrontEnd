import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'package:cims/features/teacher/results/providers/results_api_provider.dart';

class StudentResultsArgs {
  final int studentId;
  final int sessionId;

  const StudentResultsArgs({required this.studentId, required this.sessionId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentResultsArgs &&
          runtimeType == other.runtimeType &&
          studentId == other.studentId &&
          sessionId == other.sessionId;

  @override
  int get hashCode => studentId.hashCode ^ sessionId.hashCode;
}

/// Dynamic grade card for a specific student and session.
final studentGradeCardProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, StudentResultsArgs>((ref, args) async {
  final repo = ref.read(resultsRepositoryProvider);
  return repo.gradeCard(args.studentId, sessionId: args.sessionId);
});

/// All lifetime results for a specific student.
final studentAllResultsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, int>((ref, studentId) async {
  final repo = ref.read(resultsRepositoryProvider);
  return repo.studentResults(studentId, sessionId: null);
});

/// The selected session ID for the results filter (null means current session).
final selectedResultsSessionProvider = StateProvider.autoDispose<int?>((ref) => null);
