import 'package:dio/dio.dart';

/// Parses FastAPI-style `{ "detail": ... }` and common [DioException] cases.
String dioErrorMessage(
  DioException e, {
  String fallback = 'Something went wrong',
}) {
  final data = e.response?.data;
  if (data is Map) {
    final detail = data['detail'];
    if (detail is String && detail.trim().isNotEmpty) {
      return detail.trim();
    }
    if (detail is List && detail.isNotEmpty) {
      final first = detail.first;
      if (first is Map) {
        final msg = first['msg'];
        if (msg is String && msg.trim().isNotEmpty) {
          return msg.trim();
        }
      }
    }
  }

  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'Request timed out';
    case DioExceptionType.connectionError:
      return 'Cannot connect to server';
    default:
      break;
  }

  if (e.response?.statusCode == 401) {
    return 'Not authenticated';
  }
  if (e.response?.statusCode == 403) {
    return 'Permission denied';
  }

  return fallback;
}
