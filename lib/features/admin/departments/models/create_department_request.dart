class CreateDepartmentRequest {
  final String name;
  final String code;
  final String category;
  final String? description;

  CreateDepartmentRequest({
    required this.name,
    required this.code,
    required this.category,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'code': code,
      'category': category,
      'description': description,
    };
  }
}