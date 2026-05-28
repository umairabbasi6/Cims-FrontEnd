import 'package:cims/features/teacher/results/services/results_api_service.dart';

class ResultsRepository {
  final ResultsApiService _service = ResultsApiService();

  Future<Map<String, dynamic>> saveMarks(
    Map<String, dynamic> body,
  ) {
    return _service.saveMarks(body);
  }

  Future<Map<String, dynamic>> updateMarks(
    int resultId,
    Map<String, dynamic> body,
  ) {
    return _service.updateMarks(resultId, body);
  }

  Future<Map<String, dynamic>> gradeCard(
    int studentId, {
    required int sessionId,
  }) {
    return _service.gradeCard(
      studentId,
      sessionId: sessionId,
    );
  }

  Future<List<Map<String, dynamic>>> classResultSheet(
    int subjectId, {
    required int sessionId,
  }) {
    return _service.classResultSheet(
      subjectId,
      sessionId: sessionId,
    );
  }

  Future<List<Map<String, dynamic>>> studentResults(
    int studentId, {
    int? sessionId,
  }) {
    return _service.studentResults(
      studentId,
      sessionId: sessionId,
    );
  }
}
