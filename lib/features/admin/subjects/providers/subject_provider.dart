import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cims/features/admin/subjects/models/subject_api_model.dart';
import 'package:cims/features/admin/subjects/repository/subject_repository.dart';

final subjectRepositoryProvider =
    Provider<SubjectRepository>((ref) {
  return SubjectRepository();
});

final subjectsListProvider =
    FutureProvider.autoDispose<List<SubjectApiModel>>(
  (ref) async {
    final repo = ref.read(subjectRepositoryProvider);
    return repo.listSubjects(isActive: true);
  },
);

final subjectsByProgramAndStageProvider = FutureProvider.autoDispose
    .family<List<SubjectApiModel>, ({int? programId, int? stage})>(
  (ref, args) async {
    final repo = ref.read(subjectRepositoryProvider);
    return repo.listSubjects(
      programId: args.programId,
      stage: args.stage,
      isActive: true,
    );
  },
);
