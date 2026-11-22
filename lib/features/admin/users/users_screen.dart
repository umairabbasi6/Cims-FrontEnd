import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cims/core/constants/app_colors.dart';
import 'package:cims/core/constants/app_constants.dart';
import 'package:cims/core/constants/app_text_styles.dart';
import 'package:cims/core/utils/modal_helpers.dart';
import 'package:cims/core/utils/responsive.dart';
import 'package:cims/core/widgets/app_scaffold.dart';
import 'package:cims/core/widgets/badge_chip.dart';
import 'package:cims/core/session/app_session.dart';

import 'package:cims/features/admin/users/invite_user_modal.dart';
import 'package:cims/features/admin/users/models/update_user_request.dart';
import 'package:cims/features/admin/users/models/user_model.dart';
import 'package:cims/features/admin/users/providers/user_provider.dart';

class UsersScreen extends ConsumerStatefulWidget {
  final Function(String route) onNavigate;

  const UsersScreen({
    super.key,
    required this.onNavigate,
  });

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'All Status';
  String _selectedRole = 'All Roles';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilter() {
    bool? isActive;
    if (_selectedStatus == 'Active') isActive = true;
    if (_selectedStatus == 'Inactive') isActive = false;

    String? role;
    if (_selectedRole != 'All Roles') role = _selectedRole;

    ref.read(userFilterProvider.notifier).state = UserFilter(
      role: role,
      isActive: isActive,
      search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersListProvider);
    final isMobile = Responsive.isMobile(context);

    return AppScaffold(
      currentRoute: '/users',
      title: 'Users',
      subtitle: 'ADMIN PORTAL',
      role: AppSession.currentRole,
      onNavigate: widget.onNavigate,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 14 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildToolbar(context),
            const SizedBox(height: 18),
            _buildTable(context, usersAsync),
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
      child: Wrap(
        spacing: 14,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 280,
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _applyFilter(),
              decoration: const InputDecoration(
                hintText: 'Search username...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          SizedBox(
            width: 140,
            child: DropdownButtonFormField<String>(
              initialValue: _selectedStatus,
              decoration: const InputDecoration(),
              items: const [
                DropdownMenuItem(value: 'All Status', child: Text('All Status')),
                DropdownMenuItem(value: 'Active', child: Text('Active')),
                DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedStatus = val);
                  _applyFilter();
                }
              },
            ),
          ),
          SizedBox(
            width: 140,
            child: DropdownButtonFormField<String>(
              initialValue: _selectedRole,
              decoration: const InputDecoration(),
              items: const [
                DropdownMenuItem(value: 'All Roles', child: Text('All Roles')),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
                DropdownMenuItem(value: 'teacher', child: Text('Teacher')),
                DropdownMenuItem(value: 'accountant', child: Text('Accountant')),
                DropdownMenuItem(value: 'student', child: Text('Student')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedRole = val);
                  _applyFilter();
                }
              },
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(usersListProvider),
          ),
          ElevatedButton.icon(
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
        ],
      ),
    );
  }

  // =========================================================
  // TABLE
  // =========================================================

  Widget _buildTable(BuildContext context, AsyncValue<List<UserModel>> usersAsync) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 860),
          child: SizedBox(
            width: 860,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _tableHeader(context),
                usersAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, _) => Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Text('Failed to load users: $err', style: TextStyle(color: AppColors.error)),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () => ref.invalidate(usersListProvider),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                  data: (users) {
                    if (users.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: Text('No users found.')),
                      );
                    }
                    return Column(
                      children: users.map((u) => _userRow(context, u)).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
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
          Expanded(flex: 3, child: _headerText('CREATED AT')),
          Expanded(flex: 2, child: _headerText('STATUS')),
          Expanded(flex: 2, child: _headerText('ACTIONS')),
        ],
      ),
    );
  }

  Widget _headerText(String text) {
    return Text(text, style: AppTextStyles.label);
  }

  Widget _userRow(BuildContext context, UserModel user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final scope = user.role == 'admin'
        ? 'Full System'
        : user.role == 'teacher'
            ? 'Academic Operations'
            : user.role == 'accountant'
                ? 'Fee Management'
                : 'View Only';

    final createdStr = user.createdAt != null
        ? '${user.createdAt!.day.toString().padLeft(2, '0')}/${user.createdAt!.month.toString().padLeft(2, '0')}/${user.createdAt!.year}'
        : '-';

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
                    user.username.isNotEmpty ? user.username[0].toUpperCase() : 'U',
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
                        user.username,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkText : AppColors.text,
                        ),
                      ),
                      Text(
                        user.role.toUpperCase(),
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
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
              label: user.role,
              tone: user.role == 'admin'
                  ? BadgeTone.purple
                  : user.role == 'teacher'
                      ? BadgeTone.primary
                      : user.role == 'accountant'
                          ? BadgeTone.warning
                          : BadgeTone.muted,
            ),
          ),

          // ACCESS SCOPE
          Expanded(
            flex: 3,
            child: Text(
              scope,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // CREATED AT
          Expanded(
            flex: 3,
            child: Text(
              createdStr,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // STATUS
          Expanded(
            flex: 2,
            child: BadgeChip.status(user.isActive ? 'Active' : 'Inactive'),
          ),

          // ACTIONS
          Expanded(
            flex: 2,
            child: Row(
              children: [
                InkWell(
                  onTap: () => _showEditUserDialog(user),
                  child: _actionButton(context, Icons.edit_outlined),
                ),
                InkWell(
                  onTap: () => _confirmDeactivateUser(user),
                  child: _actionButton(context, Icons.delete_outline),
                ),
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
        width: 32,
        height: 32,
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

  void _showEditUserDialog(UserModel user) {
    String selectedRole = user.role;
    bool isActive = user.isActive;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Edit User: ${user.username}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(labelText: 'Role'),
                items: const [
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'teacher', child: Text('Teacher')),
                  DropdownMenuItem(value: 'accountant', child: Text('Accountant')),
                  DropdownMenuItem(value: 'student', child: Text('Student')),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedRole = val);
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Account Active'),
                value: isActive,
                onChanged: (val) => setDialogState(() => isActive = val),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ref.read(userRepositoryProvider).updateUser(
                    id: user.id,
                    request: UpdateUserRequest(
                      role: selectedRole,
                      isActive: isActive,
                    ),
                  );
                  ref.invalidate(usersListProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User updated successfully')),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('Failed to update: $e')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeactivateUser(UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate User?'),
        content: Text('Are you sure you want to deactivate account "${user.username}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              try {
                await ref.read(userRepositoryProvider).deleteUser(user.id);
                ref.invalidate(usersListProvider);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('User ${user.username} deactivated')),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Failed: $e')),
                  );
                }
              }
            },
            child: const Text('Deactivate', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
