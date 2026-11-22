class InviteUserRequest {
  final String username;
  final String? name;
  final String? email;
  final String role;
  final String? scope;
  final String? password;

  InviteUserRequest({
    required this.username,
    this.name,
    this.email,
    required this.role,
    this.scope,
    this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      'role': role,
      if (scope != null) 'scope': scope,
      if (password != null && password!.isNotEmpty) 'password': password,
    };
  }
}
