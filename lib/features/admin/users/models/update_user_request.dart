class UpdateUserRequest {
  final String? role;
  final bool? isActive;
  final String? password;

  UpdateUserRequest({
    this.role,
    this.isActive,
    this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      if (role != null) 'role': role,
      if (isActive != null) 'is_active': isActive,
      if (password != null && password!.isNotEmpty) 'password': password,
    };
  }
}
