class UpdateProgramRequest {
  final String? name;
  final String? code;
  final String? programType;
  final int? duration;
  final int? totalStages;
  final String? award;
  final bool? isActive;

  UpdateProgramRequest({
    this.name,
    this.code,
    this.programType,
    this.duration,
    this.totalStages,
    this.award,
    this.isActive,
  });

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (code != null) 'code': code,
      if (programType != null)
        'program_type': programType,
      if (duration != null) 'duration': duration,
      if (totalStages != null)
        'total_stages': totalStages,
      if (award != null) 'award': award,
      if (isActive != null)
        'is_active': isActive,
    };
  }
}