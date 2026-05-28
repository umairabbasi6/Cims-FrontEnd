class DepartmentModel {
  final int id;
  final String name;
  final String code;
  final String category;
  final String? description;
  final bool isActive;
  final DateTime createdAt;

  DepartmentModel({
    required this.id,
    required this.name,
    required this.code,
    required this.category,
    required this.description,
    required this.isActive,
    required this.createdAt,
  });

  factory DepartmentModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return DepartmentModel(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      category: json['category'],
      description: json['description'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(
        json['created_at'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'category': category,
      'description': description,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }
}