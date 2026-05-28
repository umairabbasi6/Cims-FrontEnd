class CreateProgramRequest {
  final int departmentId;
  final String name;
  final String code;
  final String programType;
  final int duration;
  final int totalStages;
  final String? award;

  CreateProgramRequest({
    required this.departmentId,
    required this.name,
    required this.code,
    required this.programType,
    required this.duration,
    required this.totalStages,
    this.award,
  });

  Map<String, dynamic> toJson() {
    return {
      'department_id': departmentId,
      'name': name,
      'code': code,
      'program_type': programType,
      'duration': duration,
      'total_stages': totalStages,
      'award': award,
    };
  }
}