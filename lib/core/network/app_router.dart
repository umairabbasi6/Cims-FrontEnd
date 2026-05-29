// Per-screen AppScaffold: each route builds a full page with shell inside the
// feature (no top-level ShellRoute). Role guards and auth refresh use GoRouter.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:cims/core/session/app_session.dart';
import 'package:cims/core/session/auth_session_controller.dart';
import 'package:cims/core/session/route_guards.dart';
import 'package:cims/features/auth/login_screen.dart';

import 'package:cims/features/admin/dashboard/admin_dashboard.dart';
import 'package:cims/features/teacher/dashboard/teacher_dashboard.dart';
import 'package:cims/features/student/student_dashboard_screen.dart';
import 'package:cims/features/student/student_program_screen.dart';
import 'package:cims/features/student/student_subjects_screen.dart';
import 'package:cims/features/student/student_attendance_screen.dart';
import 'package:cims/features/student/student_results_screen.dart';
import 'package:cims/features/student/student_fee_status_screen.dart';
import 'package:cims/features/student/student_profile_screen.dart';
import 'package:cims/features/teacher/teacher_profile_screen.dart';
import 'package:cims/features/teacher/teacher_classes_screen.dart';

import 'package:cims/features/admin/departments/departments_screen.dart';
import 'package:cims/features/admin/programs/programs_screen.dart';
import 'package:cims/features/admin/sessions/sessions_screen.dart';
import 'package:cims/features/admin/subjects/subjects_screen.dart';

import 'package:cims/features/timetable/timetable_screen.dart';

import 'package:cims/features/admin/staff/staff_screen.dart';
import 'package:cims/features/admin/students/students_screen.dart';

import 'package:cims/features/admin/users/users_screen.dart';

import 'package:cims/features/teacher/attendance/attendance_screen.dart';
import 'package:cims/features/teacher/results/results_screen.dart';

import 'package:cims/features/admin/fees/fees_screen.dart';

import 'package:cims/features/settings/settings_screen.dart';

import 'package:cims/features/admin/reports/reports_screen.dart';
import 'package:cims/features/more/more_screen.dart';
import 'package:cims/features/search/search_overlay_screen.dart';

class AppRouter {
  AppRouter._();

  // =====================================================
  // ROUTE PATHS
  // =====================================================

  static const login = '/';

  static const dashboard = '/dashboard';

  static const departments = '/departments';
  static const programs = '/programs';
  static const sessions = '/sessions';
  static const subjects = '/subjects';

  static const timetable = '/timetable';

  static const staff = '/staff';
  static const students = '/students';

  static const users = '/users';

  static const attendance = '/attendance';
  static const results = '/results';

  static const fees = '/fees';

  static const reports = '/reports';

  static const settings = '/settings';

  static const more = '/more';

  static const search = '/search';

  // =====================================================
  // GO ROUTER
  // =====================================================

  static final GoRouter router = GoRouter(
    initialLocation: login,
    refreshListenable:
        AuthSessionController.instance,

    redirect: (context, state) {
      final auth =
          AuthSessionController.instance;
      final loggedIn = auth.isAuthenticated;
      final loc =
          state.uri.path.isEmpty
              ? login
              : state.uri.path;

      if (!loggedIn) {
        if (loc == login) {
          return null;
        }
        return login;
      }

      if (loc == login) {
        return dashboard;
      }

      if (!RouteGuards.isAllowedForRole(
        auth.role,
        loc,
      )) {
        return dashboard;
      }

      return null;
    },

    debugLogDiagnostics: true,

    routes: [
      // =================================================
      // LOGIN
      // =================================================

      GoRoute(
        path: login,
        name: 'login',

        pageBuilder: (context, state) {
          return _fadeTransition(
            state,

            LoginScreen(
              onLogin: (role) {
                context.go(dashboard);
              },
            ),
          );
        },
      ),

      // =================================================
      // DASHBOARD
      // =================================================

      GoRoute(
        path: dashboard,
        name: 'dashboard',

        pageBuilder: (context, state) {
          final role = AppSession.currentRole;
          return _fadeTransition(
            state,

            role == 'student'
                ? StudentDashboardScreen(
                    onNavigate: (route) => context.go(route),
                  )
                : role == 'teacher'
                    ? TeacherDashboard(
                        onNavigate: (route) => context.go(route),
                      )
                    : AdminDashboard(
                        onNavigate: (route) => context.go(route),
                      ),
          );
        },
      ),

      // =================================================
      // MORE (mobile hub)
      // =================================================

      GoRoute(
        path: more,
        name: 'more',

        pageBuilder: (context, state) {
          return _fadeTransition(
            state,

            MoreScreen(
              onNavigate: (route) {
                context.go(route);
              },
            ),
          );
        },
      ),

      GoRoute(
        path: search,
        name: 'search',

        pageBuilder: (context, state) {
          return _fadeTransition(
            state,

            SearchOverlayScreen(
              onNavigate: (route) {
                context.go(route);
              },
            ),
          );
        },
      ),

      // =================================================
      // DEPARTMENTS
      // =================================================

      GoRoute(
        path: departments,
        name: 'departments',

        pageBuilder: (context, state) {
          return _fadeTransition(
            state,

            DepartmentsScreen(
              onNavigate: (route) {
                context.go(route);
              },
            ),
          );
        },
      ),

      // =================================================
      // PROGRAMS
      // =================================================

      GoRoute(
        path: programs,
        name: 'programs',

        pageBuilder: (context, state) {
          return _fadeTransition(
            state,

            AppSession.currentRole == 'student'
                ? StudentProgramScreen(
                    onNavigate: (route) {
                      context.go(route);
                    },
                  )
                : ProgramsScreen(
                    onNavigate: (route) {
                      context.go(route);
                    },
                  ),
          );
        },
      ),

      // =================================================
      // SESSIONS
      // =================================================

      GoRoute(
        path: sessions,
        name: 'sessions',

        pageBuilder: (context, state) {
          return _fadeTransition(
            state,

            AppSession.currentRole == 'teacher'
                ? TeacherClassesScreen(
                    onNavigate: (route) {
                      context.go(route);
                    },
                  )
                : SessionsScreen(
                    onNavigate: (route) {
                      context.go(route);
                    },
                  ),
          );
        },
      ),

      // =================================================
      // SUBJECTS
      // =================================================

      GoRoute(
        path: subjects,
        name: 'subjects',

        pageBuilder: (context, state) {
          return _fadeTransition(
            state,

            AppSession.currentRole == 'student'
                ? StudentSubjectsScreen(
                    onNavigate: (route) {
                      context.go(route);
                    },
                  )
                : SubjectsScreen(
                    onNavigate: (route) {
                      context.go(route);
                    },
                  ),
          );
        },
      ),

      // =================================================
      // TIMETABLE
      // =================================================

      GoRoute(
        path: timetable,
        name: 'timetable',

        pageBuilder: (context, state) {
          return _fadeTransition(
            state,

            TimetableScreen(
              onNavigate: (route) {
                context.go(route);
              },
            ),
          );
        },
      ),

      // =================================================
      // STAFF
      // =================================================

      GoRoute(
        path: staff,
        name: 'staff',

        pageBuilder: (context, state) {
          return _fadeTransition(
            state,

            StaffScreen(
              onNavigate: (route) {
                context.go(route);
              },
            ),
          );
        },
      ),

      // =================================================
      // STUDENTS
      // =================================================

      GoRoute(
        path: students,
        name: 'students',

        pageBuilder: (context, state) {
          return _fadeTransition(
            state,

            StudentsScreen(
              onNavigate: (route) {
                context.go(route);
              },
            ),
          );
        },
      ),

      // =================================================
      // USERS
      // =================================================

      GoRoute(
        path: users,
        name: 'users',

        pageBuilder: (context, state) {
          return _fadeTransition(
            state,

            UsersScreen(
              onNavigate: (route) {
                context.go(route);
              },
            ),
          );
        },
      ),

      // =================================================
      // ATTENDANCE
      // =================================================

      GoRoute(
        path: attendance,
        name: 'attendance',

        pageBuilder: (context, state) {
          return _fadeTransition(
            state,

            AppSession.currentRole == 'student'
                ? StudentAttendanceScreen(
                    onNavigate: (route) {
                      context.go(route);
                    },
                  )
                : AttendanceScreen(
                    onNavigate: (route) {
                      context.go(route);
                    },
                  ),
          );
        },
      ),

      // =================================================
      // RESULTS
      // =================================================

      GoRoute(
        path: results,
        name: 'results',

        pageBuilder: (context, state) {
          return _fadeTransition(
            state,

            AppSession.currentRole == 'student'
                ? StudentResultsScreen(
                    onNavigate: (route) {
                      context.go(route);
                    },
                  )
                : ResultsScreen(
                    onNavigate: (route) {
                      context.go(route);
                    },
                  ),
          );
        },
      ),

      // =================================================
      // FEES
      // =================================================

      GoRoute(
        path: fees,
        name: 'fees',

        pageBuilder: (context, state) {
          return _fadeTransition(
            state,

            AppSession.currentRole == 'student'
                ? StudentFeeStatusScreen(
                    onNavigate: (route) {
                      context.go(route);
                    },
                  )
                : FeesScreen(
                    onNavigate: (route) {
                      context.go(route);
                    },
                  ),
          );
        },
      ),

      // =================================================
      // REPORTS
      // =================================================

      GoRoute(
        path: reports,
        name: 'reports',

        pageBuilder: (context, state) {
          return _fadeTransition(
            state,

            ReportsScreen(
              onNavigate: (route) {
                context.go(route);
              },
            ),
          );
        },
      ),

      // =================================================
      // SETTINGS
      // =================================================

      GoRoute(
        path: settings,
        name: 'settings',

        pageBuilder: (context, state) {
          return _fadeTransition(
            state,

            AppSession.currentRole == 'student'
                ? StudentProfileScreen(
                    onNavigate: (route) {
                      context.go(route);
                    },
                  )
                : AppSession.currentRole == 'teacher'
                    ? TeacherProfileScreen(
                        onNavigate: (route) {
                          context.go(route);
                        },
                      )
                    : SettingsScreen(
                        onNavigate: (route) {
                          context.go(route);
                        },
                      ),
          );
        },
      ),
    ],

    // =====================================================
    // ERROR SCREEN
    // =====================================================

    errorPageBuilder: (context, state) {
      return MaterialPage(
        child: Scaffold(
          backgroundColor: const Color(0xFF06080F),

          body: Center(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,

              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.white,
                  size: 72,
                ),

                const SizedBox(height: 20),

                const Text(
                  'Page Not Found',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 10),

                Text(state.error.toString(),

                  style: const TextStyle(
                    color: Colors.white70,
                  ),

                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                ElevatedButton.icon(
                  onPressed: () {
                    context.go(dashboard);
                  },

                  icon: const Icon(
                    Icons.home_rounded,
                  ),

                  label: const Text(
                    'Back to Dashboard',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  // =====================================================
  // SHARED PAGE TRANSITION
  // =====================================================

  static CustomTransitionPage _fadeTransition(
    GoRouterState state,
    Widget child,
  ) {
    return CustomTransitionPage(
      key: state.pageKey,

      transitionDuration:
          const Duration(milliseconds: 220),

      child: child,

      transitionsBuilder:
          (
            context,
            animation,
            secondaryAnimation,
            child,
          ) {
            return FadeTransition(
              opacity: animation,

              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0.02, 0),
                      end: Offset.zero,
                     ).animate(animation),

                child: child,
              ),
            );
          },
    );
  }
}
