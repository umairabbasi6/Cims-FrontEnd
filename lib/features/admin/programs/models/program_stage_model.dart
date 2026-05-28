class ProgramStage {
  final int stage;
  final String label;

  ProgramStage({
    required this.stage,
    required this.label,
  });

  factory ProgramStage.fromJson(
    Map<String, dynamic> json,
  ) {
    return ProgramStage(
      stage: json['stage'],
      label: json['label'],
    );
  }
}

class ProgramStagesResponse {
  final int programId;
  final String programName;
  final String programType;
  final List<ProgramStage> stages;

  ProgramStagesResponse({
    required this.programId,
    required this.programName,
    required this.programType,
    required this.stages,
  });

  factory ProgramStagesResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return ProgramStagesResponse(
      programId: json['program_id'],
      programName: json['program_name'],
      programType: json['program_type'],

      stages:
          (json['stages'] as List)
              .map(
                (e) => ProgramStage.fromJson(e),
              )
              .toList(),
    );
  }
}