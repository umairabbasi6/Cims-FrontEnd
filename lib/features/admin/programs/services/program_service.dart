import 'package:dio/dio.dart';

import 'package:cims/core/network/dio_client.dart';

import 'package:cims/features/admin/programs/models/program_model.dart';
import 'package:cims/features/admin/programs/models/program_response.dart';
import 'package:cims/features/admin/programs/models/program_stage_model.dart';

import 'package:cims/features/admin/programs/models/create_program_request.dart';
import 'package:cims/features/admin/programs/models/update_program_request.dart';

class ProgramService {
  final Dio _dio = DioClient.dio;

  // =====================================================
  // GET PROGRAMS
  // =====================================================

  Future<ProgramListResponse>
  getPrograms({
    int skip = 0,
    int limit = 100,
    String? search,
    int? departmentId,
    String? programType,
  }) async {
    final response = await _dio.get(
      '/programs/',

      queryParameters: {
        'skip': skip,
        'limit': limit,

        if (search != null)
          'search': search,

        if (departmentId != null)
          'department_id': departmentId,

        if (programType != null)
          'program_type': programType,
      },
    );

    return ProgramListResponse.fromJson(
      response.data,
    );
  }

  // =====================================================
  // GET SINGLE
  // =====================================================

  Future<ProgramModel> getProgram(
    int id,
  ) async {
    final response = await _dio.get(
      '/programs/$id',
    );

    return ProgramModel.fromJson(
      response.data,
    );
  }

  // =====================================================
  // GET STAGES
  // =====================================================

  Future<ProgramStagesResponse>
  getProgramStages(
    int id,
  ) async {
    final response = await _dio.get(
      '/programs/$id/stages',
    );

    return ProgramStagesResponse.fromJson(
      response.data,
    );
  }

  // =====================================================
  // CREATE
  // =====================================================

  Future<ProgramModel> createProgram(
    CreateProgramRequest request,
  ) async {
    final response = await _dio.post(
      '/programs/',

      data: request.toJson(),
    );

    return ProgramModel.fromJson(
      response.data,
    );
  }

  // =====================================================
  // UPDATE
  // =====================================================

  Future<ProgramModel> updateProgram({
    required int id,
    required UpdateProgramRequest request,
  }) async {
    final response = await _dio.patch(
      '/programs/$id',

      data: request.toJson(),
    );

    return ProgramModel.fromJson(
      response.data,
    );
  }

  // =====================================================
  // DELETE
  // =====================================================

  Future<void> deleteProgram(
    int id,
  ) async {
    await _dio.delete(
      '/programs/$id',
    );
  }
}