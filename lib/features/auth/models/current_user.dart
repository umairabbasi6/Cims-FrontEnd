class CurrentUser {
  final String id;
  final String username;
  final String role;
  final bool isActive;

  const CurrentUser({
    required this.id,
    required this.username,
    required this.role,
    required this.isActive,
  });

  factory CurrentUser.fromJson(Map<String, dynamic> json) {
    return CurrentUser(
      id: json['id']?.toString() ?? '',
      username: json['username'] as String? ?? '',
      role: json['role'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'role': role,
        'is_active': isActive,
      };
}
