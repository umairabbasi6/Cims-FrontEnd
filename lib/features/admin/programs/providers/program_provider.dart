import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cims/features/admin/programs/models/program_model.dart';
import 'package:cims/features/admin/programs/models/program_stage_model.dart';

import 'package:cims/features/admin/programs/repository/program_repository.dart';

final programRepositoryProvider =
    Provider<ProgramRepository>((ref) {
  return ProgramRepository();
});

final programsProvider =
    FutureProvider<List<ProgramModel>>(
  (ref) async {
    final repo = ref.read(
      programRepositoryProvider,
    );

    final response =
        await repo.getPrograms();

    return response.programs;
  },
);

final programStagesProvider =
    FutureProvider.family<List<ProgramStage>, int>(
  (ref, programId) async {
    final repo = ref.read(programRepositoryProvider);
    final response = await repo.getProgramStages(programId);
    return response.stages;
  },
);