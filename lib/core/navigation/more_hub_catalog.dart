import 'package:flutter/material.dart';

import 'package:cims/core/session/route_guards.dart';
import 'package:cims/core/navigation/mobile_bottom_nav.dart';

/// Secondary destination shown on the full-screen **More** hub.
class MoreHubEntry {
  final String label;
  final IconData icon;
  final String route;

  const MoreHubEntry({
    required this.label,
    required this.icon,
    required this.route,
  });
}

/// Ordered catalog; visibility = allowed by [RouteGuards] and not a primary tab.
const kMoreHubCatalog = <MoreHubEntry>[
  MoreHubEntry(
    label: 'Results',
    icon: Icons.assessment_outlined,
    route: '/results',
  ),
  MoreHubEntry(
    label: 'Reports',
    icon: Icons.bar_chart_outlined,
    route: '/reports',
  ),
  MoreHubEntry(
    label: 'Departments',
    icon: Icons.account_balance_outlined,
    route: '/departments',
  ),
  MoreHubEntry(
    label: 'Programs',
    icon: Icons.school_outlined,
    route: '/programs',
  ),
  MoreHubEntry(
    label: 'Sessions',
    icon: Icons.event_outlined,
    route: '/sessions',
  ),
  MoreHubEntry(
    label: 'Subjects',
    icon: Icons.menu_book_outlined,
    route: '/subjects',
  ),
  MoreHubEntry(
    label: 'Timetable',
    icon: Icons.calendar_month_outlined,
    route: '/timetable',
  ),
  MoreHubEntry(
    label: 'Staff',
    icon: Icons.badge_outlined,
    route: '/staff',
  ),
  MoreHubEntry(
    label: 'User Management',
    icon: Icons.manage_accounts_outlined,
    route: '/users',
  ),
  MoreHubEntry(
    label: 'Fees',
    icon: Icons.receipt_long_outlined,
    route: '/fees',
  ),
  MoreHubEntry(
    label: 'Attendance',
    icon: Icons.fact_check_outlined,
    route: '/attendance',
  ),
  MoreHubEntry(
    label: 'Students',
    icon: Icons.people_outline,
    route: '/students',
  ),
  MoreHubEntry(
    label: 'Settings',
    icon: Icons.settings_outlined,
    route: '/settings',
  ),
];

List<MoreHubEntry> visibleMoreHubEntries(String role) {
  final primary = mobilePrimaryRouteSet(role);
  return kMoreHubCatalog.where((e) {
    if (primary.contains(e.route)) return false;
    return RouteGuards.isAllowedForRole(role, e.route);
  }).toList();
}
