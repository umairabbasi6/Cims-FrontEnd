class ProgramDepartment {
  final int id;
  final String name;
  final String code;
  final String category;

  ProgramDepartment({
    required this.id,
    required this.name,
    required this.code,
    required this.category,
  });

  factory ProgramDepartment.fromJson(
    Map<String, dynamic> json,
  ) {
    return ProgramDepartment(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      category: json['category'],
    );
  }
}

class ProgramModel {
  final int id;
  final String name;
  final String code;
  final String programType;
  final int totalStages;
  final String? award;
  final bool isActive;
  final DateTime createdAt;
  final ProgramDepartment department;

  ProgramModel({
    required this.id,
    required this.name,
    required this.code,
    required this.programType,
    required this.totalStages,
    required this.award,
    required this.isActive,
    required this.createdAt,
    required this.department,
  });

  factory ProgramModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return ProgramModel(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      programType: json['program_type'],
      totalStages: json['total_stages'],
      award: json['award'],
      isActive: json['is_active'],

      createdAt: DateTime.parse(
        json['created_at'],
      ),

      department: ProgramDepartment.fromJson(
        json['department'],
      ),
    );
  }
}