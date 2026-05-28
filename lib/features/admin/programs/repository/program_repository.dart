import 'package:cims/features/admin/programs/models/create_program_request.dart';
import 'package:cims/features/admin/programs/models/update_program_request.dart';

import 'package:cims/features/admin/programs/services/program_service.dart';

class ProgramRepository {
  final ProgramService _service =
      ProgramService();

  Future getPrograms() {
    return _service.getPrograms();
  }

  Future getProgramStages(
    int id,
  ) {
    return _service.getProgramStages(id);
  }

  Future createProgram(
    CreateProgramRequest request,
  ) {
    return _service.createProgram(
      request,
    );
  }

  Future updateProgram({
    required int id,
    required UpdateProgramRequest request,
  }) {
    return _service.updateProgram(
      id: id,
      request: request,
    );
  }

  Future deleteProgram(
    int id,
  ) {
    return _service.deleteProgram(id);
  }
}