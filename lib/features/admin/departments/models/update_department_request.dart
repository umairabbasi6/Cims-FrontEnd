class UpdateDepartmentRequest {
  final String? name;
  final String? code;
  final String? category;
  final String? description;
  final bool? isActive;

  UpdateDepartmentRequest({
    this.name,
    this.code,
    this.category,
    this.description,
    this.isActive,
  });

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (code != null) 'code': code,
      if (category != null) 'category': category,
      if (description != null)
        'description': description,
      if (isActive != null)
        'is_active': isActive,
    };
  }
}