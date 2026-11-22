import 'package:flutter_test/flutter_test.dart';
import 'package:cims/core/session/route_guards.dart';

void main() {
  group('RouteGuards Authentication & Role Access Tests', () {
    test('Login route is always accessible to everyone', () {
      expect(RouteGuards.isAllowedForRole('admin', '/'), isTrue);
      expect(RouteGuards.isAllowedForRole('teacher', '/'), isTrue);
      expect(RouteGuards.isAllowedForRole('student', '/'), isTrue);
      expect(RouteGuards.isAllowedForRole('unknown', '/'), isTrue);
      expect(RouteGuards.isAllowedForRole('', ''), isTrue);
    });

    test('Admin role has access to all operational routes', () {
      const allPaths = [
        '/dashboard',
        '/departments',
        '/programs',
        '/sessions',
        '/subjects',
        '/enrollments',
        '/timetable',
        '/staff',
        '/students',
        '/users',
        '/attendance',
        '/results',
        '/fees',
        '/reports',
        '/settings',
        '/more',
        '/search',
      ];

      for (final path in allPaths) {
        expect(
          RouteGuards.isAllowedForRole('admin', path),
          isTrue,
          reason: 'Admin should have access to $path',
        );
      }
    });

    test('Teacher role permissions and boundaries', () {
      final allowedTeacherPaths = [
        '/dashboard',
        '/timetable',
        '/attendance',
        '/results',
        '/students',
        '/sessions',
        '/subjects',
        '/settings',
        '/more',
        '/search',
      ];

      final forbiddenTeacherPaths = [
        '/departments',
        '/enrollments',
        '/staff',
        '/users',
        '/fees',
        '/reports',
      ];

      for (final path in allowedTeacherPaths) {
        expect(
          RouteGuards.isAllowedForRole('teacher', path),
          isTrue,
          reason: 'Teacher should access $path',
        );
      }

      for (final path in forbiddenTeacherPaths) {
        expect(
          RouteGuards.isAllowedForRole('teacher', path),
          isFalse,
          reason: 'Teacher must not access $path',
        );
      }
    });

    test('Student role permissions and boundaries', () {
      final allowedStudentPaths = [
        '/dashboard',
        '/programs',
        '/subjects',
        '/timetable',
        '/attendance',
        '/results',
        '/fees',
        '/settings',
        '/more',
        '/search',
      ];

      final forbiddenStudentPaths = [
        '/departments',
        '/enrollments',
        '/staff',
        '/users',
        '/reports',
      ];

      for (final path in allowedStudentPaths) {
        expect(
          RouteGuards.isAllowedForRole('student', path),
          isTrue,
          reason: 'Student should access $path',
        );
      }

      for (final path in forbiddenStudentPaths) {
        expect(
          RouteGuards.isAllowedForRole('student', path),
          isFalse,
          reason: 'Student must not access $path',
        );
      }
    });

    test('Route path normalization strips query strings and trailing slashes', () {
      // Query parameters
      expect(
        RouteGuards.isAllowedForRole('teacher', '/attendance?date=2026-11-21'),
        isTrue,
      );
      expect(
        RouteGuards.isAllowedForRole('teacher', '/reports?type=financial'),
        isFalse,
      );

      // Trailing slash
      expect(
        RouteGuards.isAllowedForRole('student', '/fees/'),
        isTrue,
      );
      expect(
        RouteGuards.isAllowedForRole('student', '/staff/'),
        isFalse,
      );
    });
  });
}
