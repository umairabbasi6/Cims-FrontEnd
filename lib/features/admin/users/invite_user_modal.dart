import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cims/core/constants/app_colors.dart';
import 'package:cims/core/constants/app_constants.dart';
import 'package:cims/core/constants/app_text_styles.dart';
import 'package:cims/core/utils/responsive.dart';
import 'package:cims/features/admin/users/models/invite_user_request.dart';
import 'package:cims/features/admin/users/providers/user_provider.dart';

class InviteUserModal extends ConsumerStatefulWidget {
  const InviteUserModal({super.key});

  @override
  ConsumerState<InviteUserModal> createState() => _InviteUserModalState();
}

class _InviteUserModalState extends ConsumerState<InviteUserModal> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String _selectedRole = 'teacher';
  String _selectedScope = 'Full System';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final name = _nameController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an email or username')),
      );
      return;
    }

    final username = email.contains('@')
        ? email.split('@').first.trim().toLowerCase()
        : email.toLowerCase();

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(userRepositoryProvider);
      await repo.inviteUser(
        InviteUserRequest(
          username: username,
          name: name.isNotEmpty ? name : null,
          email: email.contains('@') ? email : null,
          role: _selectedRole,
          scope: _selectedScope,
          password: password.isNotEmpty ? password : null,
        ),
      );

      ref.invalidate(usersListProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User $username invited successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to invite user: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPhone = Responsive.isMobile(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: Responsive.modalInsetPadding(context),
      child: Container(
        width: Responsive.modalWidth(context),
        constraints: BoxConstraints(
          maxHeight: isPhone ? MediaQuery.of(context).size.height * 0.92 : 720,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Invite User',
                          style: AppTextStyles.h2.copyWith(
                            color: isDark ? AppColors.darkText : AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Fill the details below to provision access',
                          style: AppTextStyles.body.copyWith(
                            color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.border,
                        ),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Divider(
              height: 1,
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),

            // BODY
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildInput(
                      context,
                      label: 'FULL NAME',
                      controller: _nameController,
                      hint: 'e.g. Dr. Muhammad Tariq',
                    ),
                    const SizedBox(height: 24),
                    if (isPhone) ...[
                      _buildInput(
                        context,
                        label: 'EMAIL / USERNAME',
                        controller: _emailController,
                        hint: 'name@cims.edu.pk',
                      ),
                      const SizedBox(height: 18),
                      _buildDropdown(
                        context,
                        label: 'ROLE',
                        value: _selectedRole,
                        items: const ['admin', 'teacher', 'accountant', 'student'],
                        onChanged: (v) {
                          if (v != null) setState(() => _selectedRole = v);
                        },
                      ),
                    ] else
                      Row(
                        children: [
                          Expanded(
                            child: _buildInput(
                              context,
                              label: 'EMAIL / USERNAME',
                              controller: _emailController,
                              hint: 'name@cims.edu.pk',
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: _buildDropdown(
                              context,
                              label: 'ROLE',
                              value: _selectedRole,
                              items: const ['admin', 'teacher', 'accountant', 'student'],
                              onChanged: (v) {
                                if (v != null) setState(() => _selectedRole = v);
                              },
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown(
                            context,
                            label: 'ACCESS SCOPE',
                            value: _selectedScope,
                            items: const [
                              'Full System',
                              'Academic Operations',
                              'Fee Management',
                              'View Only'
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _selectedScope = v);
                            },
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: _buildInput(
                            context,
                            label: 'TEMPORARY PASSWORD (OPTIONAL)',
                            controller: _passwordController,
                            hint: 'Leave blank for default',
                            isPassword: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            Divider(
              height: 1,
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),

            // FOOTER
            Padding(
              padding: const EdgeInsets.all(24),
              child: Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 12,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _submit,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.add_rounded, size: 18),
                      label: Text(_isLoading ? 'Saving...' : '+ Save'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required String hint,
    bool isPassword = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 54,
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            style: TextStyle(
              color: isDark ? AppColors.darkText : AppColors.text,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    BuildContext context, {
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 54,
          child: DropdownButtonFormField<String>(
            initialValue: value,
            onChanged: onChanged,
            dropdownColor: isDark ? AppColors.darkSurfaceAlt : AppColors.surface,
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
            ),
            decoration: const InputDecoration(),
            style: TextStyle(
              color: isDark ? AppColors.darkText : AppColors.text,
              fontWeight: FontWeight.w600,
            ),
            items: items.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text(item),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
