class RoleProfile {
  final String initials;
  final String name;
  final String subtitle;
  final String email;

  const RoleProfile({
    required this.initials,
    required this.name,
    required this.subtitle,
    required this.email,
  });
}

/// Default (fallback) profiles — used when real data isn't available yet.
RoleProfile roleProfileFor(String role) {
  switch (role.toLowerCase()) {
    case 'admin':
      return const RoleProfile(
        initials: 'AD',
        name: 'Admin User',
        subtitle: 'Administrator',
        email: '',
      );
    case 'teacher':
      return const RoleProfile(
        initials: 'TE',
        name: 'Teacher User',
        subtitle: 'Teacher',
        email: '',
      );
    case 'accountant':
      return const RoleProfile(
        initials: 'AC',
        name: 'Accounts User',
        subtitle: 'Accountant',
        email: '',
      );
    case 'student':
      return const RoleProfile(
        initials: 'ST',
        name: 'Student',
        subtitle: 'Student',
        email: '',
      );
    default:
      return const RoleProfile(
        initials: 'US',
        name: 'User',
        subtitle: 'User',
        email: '',
      );
  }
}
