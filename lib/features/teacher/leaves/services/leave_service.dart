import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import 'package:cims/core/network/dio_client.dart';
import 'package:cims/features/teacher/leaves/models/leave_model.dart';

class LeaveService {
  final Dio _dio = DioClient.dio;

  Future<LeaveRequestModel> requestLeave({
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
  }) async {
    final fmt = DateFormat('yyyy-MM-dd');
    final response = await _dio.post<Map<String, dynamic>>(
      '/leaves/request',
      data: {
        'start_date': fmt.format(startDate),
        'end_date': fmt.format(endDate),
        'reason': reason,
      },
    );
    return LeaveRequestModel.fromJson(response.data!);
  }

  Future<List<LeaveRequestModel>> listLeaves({String? statusFilter}) async {
    final response = await _dio.get<dynamic>(
      '/leaves/',
      queryParameters: {
        if (statusFilter != null && statusFilter.isNotEmpty) 'status': statusFilter,
      },
    );

    if (response.data is List) {
      return (response.data as List)
          .map((e) => LeaveRequestModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    return [];
  }

  Future<LeaveRequestModel> approveLeave(
    int leaveId, {
    required bool approved,
    String? notes,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/leaves/$leaveId/approve',
      data: {
        'approved': approved,
        if (notes != null) 'notes': notes,
      },
    );
    return LeaveRequestModel.fromJson(response.data!);
  }
}
