/// Role-based path allow-lists (paths must match [AppRouter] constants).
abstract final class RouteGuards {
  static const _login = '/';
  static const _dashboard = '/dashboard';
  static const _departments = '/departments';
  static const _programs = '/programs';
  static const _sessions = '/sessions';
  static const _subjects = '/subjects';
  static const _timetable = '/timetable';
  static const _staff = '/staff';
  static const _students = '/students';
  static const _users = '/users';
  static const _attendance = '/attendance';
  static const _results = '/results';
  static const _fees = '/fees';
  static const _reports = '/reports';
  static const _settings = '/settings';
  static const _more = '/more';
  static const _search = '/search';

  static const _studentPaths = <String>{
    _dashboard,
    _programs,
    _subjects,
    _timetable,
    _attendance,
    _results,
    _fees,
    _settings,
    _more,
    _search,
  };

  static const _teacherPaths = <String>{
    _dashboard,
    _timetable,
    _attendance,
    _results,
    _students,
    _sessions,
    _subjects,
    _settings,
    _more,
    _search,
  };

  static const _allAuthenticatedPaths = <String>{
    _dashboard,
    _departments,
    _programs,
    _sessions,
    _subjects,
    _timetable,
    _staff,
    _students,
    _users,
    _attendance,
    _results,
    _fees,
    _reports,
    _settings,
    _more,
    _search,
  };

  static bool isAllowedForRole(
    String role,
    String location,
  ) {
    final path = _normalize(location);
    if (path == _login) {
      return true;
    }

    switch (role.toLowerCase()) {
      case 'student':
        return _studentPaths.contains(path);
      case 'teacher':
        return _teacherPaths.contains(path);
      case 'admin':
        return _allAuthenticatedPaths.contains(path);
      default:
        return _allAuthenticatedPaths.contains(path);
    }
  }

  static String _normalize(String location) {
    if (location.isEmpty) {
      return _login;
    }
    final noQuery = location.split('?').first;
    if (noQuery.length > 1 && noQuery.endsWith('/')) {
      return noQuery.substring(0, noQuery.length - 1);
    }
    return noQuery;
  }
}
