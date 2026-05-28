class AppConstants {
  AppConstants._();

  // Institute Info
  static const String instituteName = 'Capital Institute of Para Medical Sciences';
  static const String instituteCode = 'CIMS';
  static const String instituteEmail = 'name@cims.edu.pk';
  static const String currency = 'PKR';
  static const String timezone = 'Asia/Karachi (GMT+5)';

  // Roles
  static const String roleAdmin   = 'admin';
  static const String roleTeacher = 'teacher';
  static const String roleStudent = 'student';

  // Sidebar widths
  static const double sidebarWidth     = 264.0;
  static const double sidebarCollapsed = 76.0;
  static const double topbarHeight     = 70.0;

  // Breakpoints
  static const double breakpointPhone = 768.0;
  static const double breakpointDesktop = 768.0;

  // Border radius
  static const double radiusSm  = 6.0;
  static const double radius    = 10.0;
  static const double radiusMd  = 12.0;
  static const double radiusLg  = 16.0;
  static const double radiusXl  = 22.0;
  static const double radiusFull = 999.0;

  // Spacing
  static const double spacingXs  = 4.0;
  static const double spacingSm  = 8.0;
  static const double spacing    = 16.0;
  static const double spacingMd  = 20.0;
  static const double spacingLg  = 24.0;
  static const double spacingXl  = 32.0;
  static const double spacing2xl = 48.0;

  // Dropdown options
  static const List<String> departments = [
    'DPT', 'MLT', 'RIT', 'DT', 'NM', 'PT',
  ];
  static const List<String> categories = [
    'Para Medical', 'Diagnostic Sciences', 'Rehabilitation', 'Nursing',
    'Clinical Support', 'Pharmaceutical',
  ];
  static const List<String> programs = [
    'Doctor of Physical Therapy', 'BS Medical Lab Technology',
    'Diploma in Radiology', 'Dental Assistant Certificate',
    'BS Nursing', 'Pharm-D',
  ];
  static const List<String> levels = [
    'Undergraduate', 'Graduate', 'Diploma', 'Certificate', 'Doctoral',
  ];
  static const List<String> programTypes = ['Semester', 'Annual'];
  static const List<String> sessions = ['Spring 2026', 'Fall 2025', 'Spring 2025', 'Fall 2024'];
  static const List<String> days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  static const List<String> classTypes = ['Theory', 'Lab', 'Both', 'Elective'];
  static const List<String> feeTypes = ['Tuition Fee', 'Lab Fee', 'Exam Fee', 'Registration Fee', 'Late Fee'];
  static const List<String> paymentMethods = ['Bank Transfer', 'Cash', 'Cheque', 'Online'];
  static const List<String> staffCategories = ['Medical', 'Academic', 'Admin', 'Nursing'];
  static const List<String> roles = ['admin', 'teacher', 'student', 'accountant'];
  static const List<String> accessScopes = [
    'Full System', 'Academic Operations', 'Fee Management', 'View Only',
  ];
  static const List<String> stages = ['1st', '2nd', '3rd', '4th', '5th', '6th', '7th', '8th'];
}
