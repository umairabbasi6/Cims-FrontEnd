import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cims/features/teacher/results/repository/results_repository.dart';

final resultsRepositoryProvider =
    Provider<ResultsRepository>((ref) {
  return ResultsRepository();
});
