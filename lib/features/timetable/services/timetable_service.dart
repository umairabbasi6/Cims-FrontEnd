import 'dart:typed_data';
import 'package:dio/dio.dart';

import 'package:cims/core/network/dio_client.dart';

class TimetableSlot {
  final int id;
  final int stage;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final String? room;
  final String classType;
  final int subjectId;
  final String subjectName;
  final String subjectCode;
  final String staffName;

  const TimetableSlot({
    required this.id,
    required this.stage,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.room,
    required this.classType,
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
    required this.staffName,
  });

  factory TimetableSlot.fromJson(
    Map<String, dynamic> json,
  ) {
    final sub = json['subject'] as Map<String, dynamic>?;
    final stf = json['staff'] as Map<String, dynamic>?;
    return TimetableSlot(
      id: json['id'] as int,
      stage: json['stage'] as int? ?? 0,
      dayOfWeek: json['day_of_week'] as String? ?? '',
      startTime: json['start_time'] as String? ?? '',
      endTime: json['end_time'] as String? ?? '',
      room: json['room'] as String?,
      classType: json['class_type'] as String? ?? '',
      subjectId: sub?['id'] as int? ?? 0,
      subjectName: sub?['name'] as String? ?? '',
      subjectCode: sub?['code'] as String? ?? '',
      staffName: stf?['full_name'] as String? ?? '',
    );
  }
}

class TimetableDay {
  final String day;
  final List<TimetableSlot> slots;

  const TimetableDay({
    required this.day,
    required this.slots,
  });

  factory TimetableDay.fromJson(
    Map<String, dynamic> json,
  ) {
    final raw = json['slots'] as List<dynamic>? ?? [];
    return TimetableDay(
      day: json['day'] as String? ?? '',
      slots: raw
          .map(
            (e) => TimetableSlot.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}

class TimetableWeeklyResponse {
  final int sessionId;
  final int stage;
  final int total;
  final List<TimetableDay> days;

  const TimetableWeeklyResponse({
    required this.sessionId,
    required this.stage,
    required this.total,
    required this.days,
  });

  factory TimetableWeeklyResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    final raw = json['days'] as List<dynamic>? ?? [];
    return TimetableWeeklyResponse(
      sessionId: json['session_id'] as int? ?? 0,
      stage: json['stage'] as int? ?? 0,
      total: json['total'] as int? ?? 0,
      days: raw
          .map(
            (e) => TimetableDay.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}

class TimetableService {
  final Dio _dio = DioClient.dio;

  Future<TimetableWeeklyResponse> getWeekly({
    required int sessionId,
    required int stage,
    int? staffId,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/timetable/weekly',
      queryParameters: {
        'session_id': sessionId,
        'stage': stage,
        if (staffId != null) 'staff_id': staffId,
      },
    );
    return TimetableWeeklyResponse.fromJson(
      response.data!,
    );
  }

  Future<List<Map<String, dynamic>>> listSlots({
    required int sessionId,
    int? stage,
    int? staffId,
    String? day,
  }) async {
    final response = await _dio.get<dynamic>(
      '/timetable/',
      queryParameters: {
        'session_id': sessionId,
        if (stage != null) 'stage': stage,
        if (staffId != null) 'staff_id': staffId,
        if (day != null) 'day': day,
      },
    );
    final data = response.data;
    if (data is List) {
      return data
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    if (data is Map<String, dynamic>) {
      final inner = data['slots'] ?? data['items'];
      if (inner is List) {
        return inner
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
    }
    return [];
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
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/timetable/',
      data: {
        'subject_id': subjectId,
        'staff_id': staffId,
        'session_id': sessionId,
        'stage': stage,
        'day_of_week': dayOfWeek,
        'start_time': startTime,
        'end_time': endTime,
        'room': room.trim(),
        'class_type': classType.toUpperCase().trim(),
      },
    );
    return response.data!;
  }

  Future<void> deleteSlot(int slotId) async {
    await _dio.delete('/timetable/$slotId');
  }

  Future<Uint8List> getTimetablePdf({
    required int sessionId,
    required int stage,
    int? programId,
    int? staffId,
  }) async {
    final response = await _dio.get<List<int>>(
      '/reports/timetable',
      queryParameters: {
        'session_id': sessionId,
        'stage': stage,
        if (programId != null) 'program_id': programId,
        if (staffId != null) 'staff_id': staffId,
      },
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data!);
  }
}
