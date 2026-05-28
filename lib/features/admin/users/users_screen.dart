import 'package:flutter/material.dart';

import 'package:cims/core/constants/app_colors.dart';
import 'package:cims/core/constants/app_constants.dart';
import 'package:cims/core/constants/app_text_styles.dart';
import 'package:cims/core/utils/modal_helpers.dart';
import 'package:cims/core/widgets/app_scaffold.dart';
import 'package:cims/core/widgets/badge_chip.dart';
import 'package:cims/core/session/app_session.dart';

import 'package:cims/features/admin/users/invite_user_modal.dart';

class UsersScreen extends StatelessWidget {
  final Function(String route) onNavigate;

  const UsersScreen({
    super.key,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentRoute: '/users',
      title: 'Users',
      subtitle: 'ADMIN PORTAL',
      role: AppSession.currentRole,
      onNavigate: onNavigate,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildToolbar(context),
            SizedBox(height: 18),
            _buildTable(context),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // TOOLBAR
  // =========================================================

  Widget _buildToolbar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 320,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search records',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                ),
              ),
            ),
          ),
          SizedBox(width: 14),
          SizedBox(
            width: 140,
            child: DropdownButtonFormField<String>(
              initialValue: 'All Status',
              decoration: const InputDecoration(),
              items: const [
                DropdownMenuItem(
                  value: 'All Status',
                  child: Text('All Status'),
                ),
              ],
              onChanged: (_) {},
            ),
          ),
          SizedBox(width: 18),
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.filter_alt_outlined),
            label: const Text('Filters'),
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.download_rounded),
            label: const Text('Export'),
          ),
          SizedBox(width: 12),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                showResponsiveModal(
                  context: context,
                  barrierColor: Colors.black.withValues(alpha: 0.7),
                  child: const InviteUserModal(),
                );
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Invite User'),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // TABLE
  // =========================================================

  Widget _buildTable(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final users = [
      {
        'name': 'Admin User',
        'sub': 'Full System',
        'role': 'admin',
        'scope': 'Full System',
        'login': 'Today, 09:40 AM',
        'status': 'Active',
      },
      {
        'name': 'Teacher User',
        'sub': 'Academic Operations',
        'role': 'teacher',
        'scope': 'Academic Operations',
        'login': 'Today, 08:15 AM',
        'status': 'Active',
      },
      {
        'name': 'Student User',
        'sub': 'View Only',
        'role': 'student',
        'scope': 'View Only',
        'login': 'Yesterday, 07:22 PM',
        'status': 'Active',
      },
      {
        'name': 'Accounts User',
        'sub': 'Fee Management',
        'role': 'accountant',
        'scope': 'Fee Management',
        'login': 'Apr 29, 2026',
        'status': 'Active',
      },
      {
        'name': 'Teacher User 2',
        'sub': 'Academic Operations',
        'role': 'teacher',
        'scope': 'Academic Operations',
        'login': 'Today, 11:02 AM',
        'status': 'Active',
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          _tableHeader(context),
          ...users.map(
            (u) => _userRow(context, u),
          ),
        ],
      ),
    );
  }

  Widget _tableHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(flex: 4, child: _headerText('USER')),
          Expanded(flex: 3, child: _headerText('ROLE')),
          Expanded(flex: 3, child: _headerText('ACCESS SCOPE')),
          Expanded(flex: 3, child: _headerText('LAST LOGIN')),
          Expanded(flex: 2, child: _headerText('STATUS')),
          Expanded(flex: 2, child: _headerText('ACTIONS')),
        ],
      ),
    );
  }

  // Simple header text helper for flexible columns
  Widget _headerText(String text) {
    return Text(text, style: AppTextStyles.label);
  }

  Widget _userRow(BuildContext context, Map<String, String> user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? AppColors.darkBorder.withValues(alpha: .4)
                : AppColors.border.withValues(alpha: .5),
          ),
        ),
      ),
      child: Row(
        children: [
          // USER
          Expanded(
            flex: 4,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    user['name']!.split(' ').map((e) => e[0]).take(2).join(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['name']!,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkText : AppColors.text,
                        ),
                      ),
                      Text(
                        user['sub']!,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ROLE
          Expanded(
            flex: 3,
            child: BadgeChip(
              label: user['role']!,
              tone: user['role'] == 'admin'
                  ? BadgeTone.purple
                  : user['role'] == 'teacher'
                      ? BadgeTone.primary
                      : user['role'] == 'accountant'
                          ? BadgeTone.warning
                          : BadgeTone.muted,
            ),
          ),

          // ACCESS SCOPE
          Expanded(
            flex: 3,
            child: Text(
              user['scope']!,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // LAST LOGIN
          Expanded(
            flex: 3,
            child: Text(
              user['login']!,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // STATUS
          Expanded(
            flex: 2,
            child: BadgeChip.status(user['status']!),
          ),

          // ACTIONS
          Expanded(
            flex: 2,
            child: Row(
              children: [
                _actionButton(context, Icons.visibility_outlined),
                _actionButton(context, Icons.edit_outlined),
                _actionButton(context, Icons.delete_outline),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(BuildContext context, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        ),
      ),
    );
  }
}