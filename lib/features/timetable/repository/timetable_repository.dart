import 'dart:typed_data';
import 'package:cims/features/timetable/services/timetable_service.dart';

class TimetableRepository {
  final TimetableService _service = TimetableService();

  Future<TimetableWeeklyResponse> getWeekly({
    required int sessionId,
    required int stage,
    int? staffId,
  }) {
    return _service.getWeekly(
      sessionId: sessionId,
      stage: stage,
      staffId: staffId,
    );
  }

  Future<List<Map<String, dynamic>>> listSlots({
    required int sessionId,
    int? stage,
    int? staffId,
    String? day,
  }) {
    return _service.listSlots(
      sessionId: sessionId,
      stage: stage,
      staffId: staffId,
      day: day,
    );
  }

  Future<Map<String, dynamic>> createSlot({
    required int subjectId,
    required int staffId,
    required int sessionId,
    required int stage,
    required String dayOfWeek,
    required String startTime,
    required String endTime,
    required String room,
    required String classType,
  }) {
    return _service.createSlot(
      subjectId: subjectId,
      staffId: staffId,
      sessionId: sessionId,
      stage: stage,
      dayOfWeek: dayOfWeek,
      startTime: startTime,
      endTime: endTime,
      room: room,
      classType: classType,
    );
  }

  Future<void> deleteSlot(int slotId) {
    return _service.deleteSlot(slotId);
  }

  Future<Uint8List> getTimetablePdf({
    required int sessionId,
    int? stage,
    int? programId,
    int? staffId,
  }) {
    return _service.getTimetablePdf(
      sessionId: sessionId,
      stage: stage,
      programId: programId,
      staffId: staffId,
    );
  }
}
