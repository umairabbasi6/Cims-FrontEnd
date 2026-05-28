import 'package:cims/features/admin/programs/models/program_model.dart';

class ProgramListResponse {
  final int total;
  final List<ProgramModel> programs;

  ProgramListResponse({
    required this.total,
    required this.programs,
  });

  factory ProgramListResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return ProgramListResponse(
      total: json['total'],

      programs:
          (json['programs'] as List)
              .map(
                (e) => ProgramModel.fromJson(e),
              )
              .toList(),
    );
  }
}