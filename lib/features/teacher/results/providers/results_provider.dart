import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cims/features/teacher/results/providers/results_api_provider.dart';

/// Simple query object for fetching results.
class ResultsQuery {
  final int subjectId;
  final int sessionId;

  const ResultsQuery({required this.subjectId, required this.sessionId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResultsQuery &&
          runtimeType == other.runtimeType &&
          subjectId == other.subjectId &&
          sessionId == other.sessionId;

  @override
  int get hashCode => subjectId.hashCode ^ sessionId.hashCode;
}

final classResultsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, ResultsQuery>(
  (ref, query) async {
    final repo = ref.read(resultsRepositoryProvider);
    return repo.classResultSheet(query.subjectId, sessionId: query.sessionId);
  },
);
