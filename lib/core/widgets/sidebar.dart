import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cims/features/auth/providers/auth_provider.dart';
import 'package:cims/features/admin/students/providers/student_provider.dart';
import 'package:cims/features/admin/staff/providers/staff_provider.dart';
import 'package:cims/core/constants/app_colors.dart';
import 'package:cims/core/constants/app_constants.dart';
import 'package:cims/core/constants/role_profile.dart';
import 'package:cims/core/constants/app_text_styles.dart';

class AppSidebar extends ConsumerWidget {
  final String currentRoute;
  final String role;
  final bool collapsed;

  final void Function(String route) onNavigate;

  const AppSidebar({
    super.key,
    required this.currentRoute,
    required this.role,
    required this.onNavigate,
    this.collapsed = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? AppColors.darkSidebarBg : AppColors.sidebarBg;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final items = _navItemsForRole(role);

    // Build profile: use real student/teacher data if available
    final RoleProfile profile;
    final currentUser = ref.watch(currentUserProvider).whenOrNull(data: (data) => data);
    if (role == 'student') {
      final studentAsync = ref.watch(currentStudentProvider);
      final student = studentAsync.whenOrNull(data: (data) => data);
      if (student != null) {
        final parts = student.fullName.trim().split(' ').where((p) => p.isNotEmpty).toList();
        final initials = parts.length >= 2
            ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
            : (parts.isNotEmpty ? parts[0][0].toUpperCase() : 'ST');
        profile = RoleProfile(
          initials: initials,
          name: student.fullName,
          subtitle: 'Student',
          email: student.email ?? '',
        );
      } else if (currentUser != null && currentUser.username.isNotEmpty) {
        profile = RoleProfile(
          initials: _initialsFrom(currentUser.username, fallback: 'ST'),
          name: currentUser.username,
          subtitle: 'Student',
          email: '',
        );
      } else {
        profile = roleProfileFor(role);
      }
    } else if (role == 'teacher') {
      final staffAsync = ref.watch(currentStaffProvider);
      final staff = staffAsync.whenOrNull(data: (data) => data);
      if (staff != null) {
        final parts = staff.fullName.trim().split(' ').where((p) => p.isNotEmpty).toList();
        final initials = parts.length >= 2
            ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
            : (parts.isNotEmpty ? parts[0][0].toUpperCase() : 'TE');
        profile = RoleProfile(
          initials: initials,
          name: staff.fullName,
          subtitle: staff.designation.isNotEmpty ? staff.designation : 'Teacher',
          email: staff.email ?? '',
        );
      } else if (currentUser != null && currentUser.username.isNotEmpty) {
        profile = RoleProfile(
          initials: _initialsFrom(currentUser.username, fallback: 'TE'),
          name: currentUser.username,
          subtitle: 'Teacher',
          email: '',
        );
      } else {
        profile = roleProfileFor(role);
      }
    } else {
      if (currentUser != null && currentUser.username.isNotEmpty) {
        profile = RoleProfile(
          initials: _initialsFrom(currentUser.username, fallback: 'US'),
          name: currentUser.username,
          subtitle: role == 'admin'
              ? 'Administrator'
              : role == 'accountant'
                  ? 'Accountant'
                  : 'User',
          email: '',
        );
      } else {
        profile = roleProfileFor(role);
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: collapsed ? AppConstants.sidebarCollapsed : AppConstants.sidebarWidth,
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          right: BorderSide(color: border),
        ),
      ),
      child: Column(
        children: [
          // =====================================================
          // BRAND
          // =====================================================

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
            constraints: const BoxConstraints(minHeight: 70),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.darkBorderSoft : AppColors.borderSoft,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientPrimary,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.28),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'CI',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                if (!collapsed) ...[
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CIMS',
                          style: AppTextStyles.h4.copyWith(
                            color: isDark ? AppColors.darkText : AppColors.text,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Capital Institute',
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 11,
                            color: isDark ? AppColors.darkSidebarMuted : AppColors.sidebarMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // =====================================================
          // ROLE
          // =====================================================

          if (!collapsed)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: _RoleBadge(role: role),
            ),

          SizedBox(height: 8),

          // =====================================================
          // NAVIGATION
          // =====================================================

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              children: [
                for (final section in items) ...[
                  if (section.label != null && !collapsed) ...[
                    SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 12,
                        right: 12,
                        top: 14,
                        bottom: 6,
                      ),
                      child: Text(
                        section.label!.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: isDark ? AppColors.darkSidebarMuted : AppColors.sidebarMuted,
                        ),
                      ),
                    ),
                  ],
                  for (final item in section.items)
                    _SidebarItem(
                      collapsed: collapsed,
                      icon: item.icon,
                      label: item.label,
                      route: item.route,
                      badge: item.badge,
                      isActive: currentRoute == item.route,
                      onTap: () => onNavigate(item.route),
                      isDark: isDark,
                    ),
                ],
              ],
            ),
          ),

          // =====================================================
          // FOOTER
          // =====================================================

          Container(
            margin: collapsed
                ? const EdgeInsets.all(10)
                : const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientPrimary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      profile.initials,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                if (!collapsed) ...[
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.name,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySm.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          profile.email,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 11,
                            color: isDark ? AppColors.darkSidebarMuted : AppColors.sidebarMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<_NavSection> _navItemsForRole(String role) {
    if (role == 'admin') {
      return [
        _NavSection('Overview', [
          _NavItem(Icons.dashboard_rounded, 'Dashboard', '/dashboard'),
          _NavItem(Icons.bar_chart_rounded, 'Reports', '/reports'),
        ]),
        _NavSection('Academics', [
          _NavItem(Icons.account_balance_rounded, 'Departments', '/departments'),
          _NavItem(Icons.school_rounded, 'Programs', '/programs'),
          _NavItem(Icons.event_rounded, 'Sessions', '/sessions', badge: 'New'),
          _NavItem(Icons.book_rounded, 'Subjects', '/subjects'),
          _NavItem(Icons.calendar_month_rounded, 'Timetable', '/timetable'),
        ]),
        _NavSection('People', [
          _NavItem(Icons.badge_rounded, 'Staff', '/staff'),
          _NavItem(Icons.people_rounded, 'Students', '/students'),
          _NavItem(Icons.manage_accounts_rounded, 'User Management', '/users'),
        ]),
        _NavSection('Operations', [
          _NavItem(Icons.check_box_outlined, 'Attendance', '/attendance'),
          _NavItem(Icons.assignment_outlined, 'Results', '/results'),
          _NavItem(Icons.account_balance_wallet_rounded, 'Fees', '/fees', badge: '14'),
        ]),
        _NavSection('System', [
          _NavItem(Icons.settings_rounded, 'Settings', '/settings'),
        ]),
      ];
    }

    if (role == 'teacher') {
      return [
        _NavSection('Overview', [
          _NavItem(Icons.dashboard_rounded, 'Dashboard', '/dashboard'),
        ]),
        _NavSection('Teaching', [
          _NavItem(Icons.menu_book_outlined, 'My Subjects', '/subjects'),
          _NavItem(Icons.business_outlined, 'My Classes', '/sessions'),
          _NavItem(Icons.calendar_month_rounded, 'Timetable', '/timetable'),
        ]),
        _NavSection('Daily', [
          _NavItem(Icons.check_box_outlined, 'Attendance', '/attendance', badge: '!'),
          _NavItem(Icons.assignment_outlined, 'Marks Entry', '/results'),
        ]),
        _NavSection('Roster', [
          _NavItem(Icons.people_outline_rounded, 'Students', '/students'),
        ]),
        _NavSection('Account', [
          _NavItem(Icons.person_outline_rounded, 'Profile', '/settings'),
        ]),
      ];
    }

    return [
      _NavSection('Overview', [
        _NavItem(Icons.dashboard_rounded, 'Dashboard', '/dashboard'),
      ]),
      _NavSection('Academics', [
        _NavItem(Icons.school_outlined, 'My Program', '/programs'),
        _NavItem(Icons.menu_book_outlined, 'Subjects', '/subjects'),
        _NavItem(Icons.calendar_month_rounded, 'Timetable', '/timetable'),
      ]),
      _NavSection('Records', [
        _NavItem(Icons.check_box_outlined, 'Attendance', '/attendance'),
        _NavItem(Icons.assignment_outlined, 'Results', '/results'),
        _NavItem(Icons.account_balance_wallet_outlined, 'Fee Status', '/fees', badge: 'Due'),
      ]),
      _NavSection('Account', [
        _NavItem(Icons.person_outline_rounded, 'Profile', '/settings'),
      ]),
    ];
  }
}

// =====================================================
// NAV SECTION
// =====================================================

class _NavSection {
  final String? label;
  final List<_NavItem> items;

  _NavSection(this.label, this.items);
}

// =====================================================
// NAV ITEM
// =====================================================

class _NavItem {
  final IconData icon;
  final String label;
  final String route;
  final String? badge;

  _NavItem(this.icon, this.label, this.route, {this.badge});
}

// =====================================================
// SIDEBAR ITEM
// =====================================================

class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final String route;
  final String? badge;
  final bool isActive;
  final bool isDark;
  final bool collapsed;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.badge,
    required this.isActive,
    required this.onTap,
    required this.isDark,
    required this.collapsed,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    final fg = widget.isActive
        ? AppColors.primary
        : (widget.isDark ? AppColors.darkSidebarFg : AppColors.sidebarFg);

    final bg = widget.isActive
        ? (widget.isDark
            ? AppColors.primary.withValues(alpha: 0.14)
            : AppColors.primarySoft)
        : hovered
            ? (widget.isDark ? AppColors.darkSurfaceHover : AppColors.surfaceHover)
            : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(AppConstants.radius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // ACTIVE INDICATOR
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: widget.isActive ? 3 : 0,
                height: 18,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),

              // ICON
              Icon(widget.icon, size: 18, color: fg),

              // LABEL
              if (!widget.collapsed) ...[
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.label,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                      color: fg,
                      fontSize: 13.5,
                      fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),

                // BADGE
                if (widget.badge != null)
                  Container(
                    constraints: const BoxConstraints(minWidth: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: widget.badge == 'New'
                          ? AppColors.primary
                          : (widget.badge == 'Due' || widget.badge == '!' || widget.badge == '3' || widget.badge == '14')
                              ? AppColors.warning
                              : AppColors.danger,
                      borderRadius: BorderRadius.circular(AppConstants.radiusFull),
                    ),
                    child: Text(
                      widget.badge!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: (widget.badge == 'Due' || widget.badge == '!' || widget.badge == '3' || widget.badge == '14')
                            ? const Color(0xFF783C00)
                            : Colors.white,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================
// ROLE BADGE
// =====================================================

class _RoleBadge extends StatelessWidget {
  final String role;

  const _RoleBadge({required this.role});

  String get _label {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Admin';
      case 'teacher':
        return 'Teacher';
      case 'student':
        return 'Student';
      case 'accountant':
        return 'Accountant';
      default:
        return roleProfileFor(role).subtitle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        _label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

String _initialsFrom(String value, {required String fallback}) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return fallback;
  if (parts.length >= 2) {
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
  return parts.first[0].toUpperCase();
}