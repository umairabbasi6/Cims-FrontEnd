import 'package:flutter/material.dart';

import 'package:cims/core/session/route_guards.dart';

/// Bottom navigation item for mobile (max 5 per role).
class MobileNavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;

  const MobileNavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
  });
}

/// Primary mobile tabs (aligned with CIMS mobile UX spec).
const _adminNav = <MobileNavItem>[
  MobileNavItem(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    activeIcon: Icons.dashboard,
    route: '/dashboard',
  ),
  MobileNavItem(
    label: 'Students',
    icon: Icons.people_outline,
    activeIcon: Icons.people,
    route: '/students',
  ),
  MobileNavItem(
    label: 'Attendance',
    icon: Icons.fact_check_outlined,
    activeIcon: Icons.fact_check,
    route: '/attendance',
  ),
  MobileNavItem(
    label: 'Finance',
    icon: Icons.account_balance_wallet_outlined,
    activeIcon: Icons.account_balance_wallet,
    route: '/fees',
  ),
  MobileNavItem(
    label: 'More',
    icon: Icons.menu_rounded,
    activeIcon: Icons.menu_rounded,
    route: '/more',
  ),
];

const _teacherNav = <MobileNavItem>[
  MobileNavItem(
    label: 'Home',
    icon: Icons.home_outlined,
    activeIcon: Icons.home,
    route: '/dashboard',
  ),
  MobileNavItem(
    label: 'Schedule',
    icon: Icons.calendar_today_outlined,
    activeIcon: Icons.calendar_today,
    route: '/timetable',
  ),
  MobileNavItem(
    label: 'Attendance',
    icon: Icons.fact_check_outlined,
    activeIcon: Icons.fact_check,
    route: '/attendance',
  ),
  MobileNavItem(
    label: 'Students',
    icon: Icons.school_outlined,
    activeIcon: Icons.school,
    route: '/students',
  ),
  MobileNavItem(
    label: 'More',
    icon: Icons.menu_rounded,
    activeIcon: Icons.menu_rounded,
    route: '/more',
  ),
];

const _studentNav = <MobileNavItem>[
  MobileNavItem(
    label: 'Home',
    icon: Icons.home_outlined,
    activeIcon: Icons.home,
    route: '/dashboard',
  ),
  MobileNavItem(
    label: 'Schedule',
    icon: Icons.calendar_today_outlined,
    activeIcon: Icons.calendar_today,
    route: '/timetable',
  ),
  MobileNavItem(
    label: 'Results',
    icon: Icons.assessment_outlined,
    activeIcon: Icons.assessment,
    route: '/results',
  ),
  MobileNavItem(
    label: 'Fees',
    icon: Icons.receipt_long_outlined,
    activeIcon: Icons.receipt_long,
    route: '/fees',
  ),
  MobileNavItem(
    label: 'More',
    icon: Icons.menu_rounded,
    activeIcon: Icons.menu_rounded,
    route: '/more',
  ),
];

List<MobileNavItem> mobileBottomNavItemsForRole(String role) {
  switch (role.toLowerCase()) {
    case 'teacher':
      return _teacherNav;
    case 'student':
      return _studentNav;
    default:
      return _adminNav;
  }
}

/// Routes shown as primary bottom tabs (including [moreRoute]) for this role.
Set<String> mobilePrimaryRouteSet(String role) =>
    mobileBottomNavItemsForRole(role).map((e) => e.route).toSet();

String _normalizePath(String location) {
  if (location.isEmpty) return '/';
  final noQuery = location.split('?').first;
  if (noQuery.length > 1 && noQuery.endsWith('/')) {
    return noQuery.substring(0, noQuery.length - 1);
  }
  return noQuery;
}

/// Resolves bottom nav index; secondary routes highlight **More** when allowed.
int mobileBottomNavIndex(String currentRoute, String role) {
  final path = _normalizePath(currentRoute);
  final items = mobileBottomNavItemsForRole(role);
  for (var i = 0; i < items.length; i++) {
    if (path == items[i].route) return i;
  }
  const moreRoute = '/more';
  final moreIdx = items.indexWhere((e) => e.route == moreRoute);
  if (moreIdx >= 0 && RouteGuards.isAllowedForRole(role, path)) {
    final primary = mobilePrimaryRouteSet(role);
    if (!primary.contains(path)) return moreIdx;
  }
  return 0;
}
