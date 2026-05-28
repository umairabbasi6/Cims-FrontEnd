import 'package:dio/dio.dart';

import 'package:cims/core/network/dio_client.dart';

import 'package:cims/features/admin/departments/models/create_department_request.dart';
import 'package:cims/features/admin/departments/models/update_department_request.dart';
import 'package:cims/features/admin/departments/models/department_model.dart';
import 'package:cims/features/admin/departments/models/department_response.dart';

class DepartmentService {
  final Dio _dio = DioClient.dio;

  // =====================================================
  // GET ALL
  // =====================================================

  Future<DepartmentListResponse>
  getDepartments({
    int skip = 0,
    int limit = 100,
    String? search,
    String? category,
    bool? isActive,
  }) async {
    final response = await _dio.get(
      '/departments/',

      queryParameters: {
        'skip': skip,
        'limit': limit,

        if (search != null)
          'search': search,

        if (category != null)
          'category': category,

        if (isActive != null) 'is_active': isActive,
      },
    );

    return DepartmentListResponse.fromJson(
      response.data,
    );
  }

  // =====================================================
  // GET SINGLE
  // =====================================================

  Future<DepartmentModel> getDepartment(
    int id,
  ) async {
    final response = await _dio.get(
      '/departments/$id',
    );

    return DepartmentModel.fromJson(
      response.data,
    );
  }

  // =====================================================
  // CREATE
  // =====================================================

  Future<DepartmentModel>
  createDepartment(
    CreateDepartmentRequest request,
  ) async {
    final response = await _dio.post(
      '/departments/',

      data: request.toJson(),
    );

    return DepartmentModel.fromJson(
      response.data,
    );
  }

  // =====================================================
  // UPDATE
  // =====================================================

  Future<DepartmentModel>
  updateDepartment({
    required int id,
    required UpdateDepartmentRequest request,
  }) async {
    final response = await _dio.patch(
      '/departments/$id',

      data: request.toJson(),
    );

    return DepartmentModel.fromJson(
      response.data,
    );
  }

  // =====================================================
  // DELETE
  // =====================================================

  Future<void> deleteDepartment(
    int id,
  ) async {
    await _dio.delete(
      '/departments/$id',
    );
  }
}