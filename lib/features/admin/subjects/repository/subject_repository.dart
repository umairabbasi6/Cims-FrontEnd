import 'package:cims/features/admin/subjects/models/subject_api_model.dart';
import 'package:cims/features/admin/subjects/services/subject_service.dart';

class SubjectRepository {
  final SubjectService _service = SubjectService();

  Future<List<SubjectApiModel>> listSubjects({
    int? programId,
    int? stage,
    bool? isActive,
    String? search,
  }) async {
    final res = await _service.getSubjects(
      programId: programId,
      stage: stage,
      isActive: isActive,
      search: search,
    );
    return res.subjects;
  }

  Future<SubjectApiModel> getSubject(int id) {
    return _service.getSubject(id);
  }

  Future<SubjectApiModel> createSubject({
    required int programId,
    required String name,
    required String code,
    required int stage,
    required double creditHours,
    required bool hasPractical,
  }) {
    return _service.createSubject(
      programId: programId,
      name: name,
      code: code,
      stage: stage,
      creditHours: creditHours,
      hasPractical: hasPractical,
    );
  }

  Future<SubjectApiModel> updateSubject({
    required int id,
    String? name,
    String? code,
    double? creditHours,
    bool? hasPractical,
    bool? isActive,
  }) {
    return _service.updateSubject(
      id: id,
      name: name,
      code: code,
      creditHours: creditHours,
      hasPractical: hasPractical,
      isActive: isActive,
    );
  }

  Future<void> deleteSubject(int id) {
    return _service.deleteSubject(id);
  }
}

