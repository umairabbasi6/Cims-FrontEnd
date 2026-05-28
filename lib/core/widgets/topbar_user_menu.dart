import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cims/features/auth/providers/auth_provider.dart';
import 'package:cims/features/admin/sessions/providers/session_provider.dart';
import 'package:cims/features/admin/students/providers/student_provider.dart';
import 'package:cims/features/admin/staff/providers/staff_provider.dart';
import 'package:cims/features/admin/subjects/providers/subject_provider.dart';
import 'package:cims/core/network/app_router.dart';
import 'package:cims/core/constants/app_colors.dart';
import 'package:cims/core/constants/app_constants.dart';
import 'package:cims/core/constants/app_text_styles.dart';
import 'package:cims/core/constants/role_profile.dart';
import 'package:cims/core/theme/theme_mode_provider.dart';

class TopbarUserMenu extends ConsumerWidget {
  final bool isDark;
  final String role;

  const TopbarUserMenu({
    super.key,
    required this.isDark,
    required this.role,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    return PopupMenuButton<String>(
      offset: const Offset(0, 58),
      color: isDark ? AppColors.darkSurface : AppColors.surface,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      onSelected: (value) async {
        switch (value) {
          case 'profile':
          case 'password':
            context.go(AppRouter.settings);
            break;
          case 'theme':
            ref.read(themeModeProvider.notifier).state =
                isDark ? ThemeMode.light : ThemeMode.dark;
            break;
          case 'help':
            if (context.mounted) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                  ),
                  title: const Text('Help & Support'),
                  content: const Text(
                    'For support, please contact the IT helpdesk at support@cims.edu or call extension 1234.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            }
            break;
          case 'logout':
            await ref.read(authRepositoryProvider).logout();
            ref.invalidate(currentUserProvider);
            ref.invalidate(sessionsListProvider);
            ref.invalidate(currentAcademicSessionProvider);
            ref.invalidate(subjectsListProvider);
            ref.invalidate(studentsListProvider);
            if (context.mounted) {
              context.go(AppRouter.login);
            }
            break;
          default:
            break;
        }
      },
      itemBuilder: (context) => [
        _menuItem(
          value: 'profile',
          icon: Icons.person_outline_rounded,
          label: 'View profile',
        ),
        _menuItem(
          value: 'password',
          icon: Icons.lock_outline_rounded,
          label: 'Change password',
        ),
        _menuItem(
          value: 'theme',
          icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          label: isDark ? 'Switch to light mode' : 'Switch to dark mode',
        ),
        _menuItem(
          value: 'help',
          icon: Icons.help_outline_rounded,
          label: 'Help & support',
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              const Icon(
                Icons.logout_rounded,
                size: 18,
                color: AppColors.danger,
              ),
              SizedBox(width: 12),
              Text(
                'Sign out',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                gradient: AppColors.gradientPrimary,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                profile.initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                ),
              ),
            ),
            SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name.split(' ').first,
                  style: AppTextStyles.bodySm.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: isDark ? AppColors.darkText : AppColors.text,
                    height: 1.1,
                  ),
                ),
                Text(
                  profile.subtitle,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 10,
                    color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                    height: 1.1,
                  ),
                ),
              ],
            ),
            SizedBox(width: 6),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem({
    required String value,
    required IconData icon,
    required String label,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
          SizedBox(width: 12),
          Text(
            label,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
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
}