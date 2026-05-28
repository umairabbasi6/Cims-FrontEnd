/// Backend `category` values for `POST /departments/` (see API doc §2.3).
abstract final class DepartmentCategory {
  static const String medical = 'medical';
  static const String academic = 'academic';
  static const String nursing = 'nursing';
  static const String admin = 'admin';
  static const String finance = 'finance';

  static const List<String> apiValues = [
    medical,
    academic,
    nursing,
    admin,
    finance,
  ];

  static String label(String apiValue) {
    switch (apiValue.toLowerCase()) {
      case medical:
        return 'Medical';
      case academic:
        return 'Academic';
      case nursing:
        return 'Nursing';
      case admin:
        return 'Administration';
      case finance:
        return 'Finance';
      default:
        if (apiValue.isEmpty) return '—';
        return apiValue[0].toUpperCase() + apiValue.substring(1);
    }
  }

  /// Tab label → API category filter.
  static String? apiFromTab(String tab) {
    switch (tab) {
      case 'Medical':
        return medical;
      case 'Academic':
        return academic;
      case 'Nursing':
        return nursing;
      case 'Admin':
        return admin;
      case 'Finance':
        return finance;
      default:
        return null;
    }
  }
}
