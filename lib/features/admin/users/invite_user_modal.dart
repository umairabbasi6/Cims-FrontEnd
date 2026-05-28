import 'package:flutter/material.dart';

import 'package:cims/core/constants/app_colors.dart';
import 'package:cims/core/constants/app_constants.dart';
import 'package:cims/core/constants/app_text_styles.dart';
import 'package:cims/core/utils/responsive.dart';

class InviteUserModal extends StatefulWidget {
  const InviteUserModal({super.key});

  @override
  State<InviteUserModal> createState() => _InviteUserModalState();
}

class _InviteUserModalState extends State<InviteUserModal> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  String _selectedRole = 'admin';
  String _selectedScope = 'Full System';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;
    final bool isTablet = screenWidth >= 600 && screenWidth < 1024;
    final bool isDesktop = screenWidth >= 1024;

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
          color: isDark
              ? AppColors.darkSurface
              : AppColors.surface,
          borderRadius: BorderRadius.circular(
            AppConstants.radiusLg,
          ),
          border: Border.all(
            color: isDark
                ? AppColors.darkBorder
                : AppColors.border,
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
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Invite User',
                          style: AppTextStyles.h2.copyWith(
                            color: isDark
                                ? AppColors.darkText
                                : AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Fill the details below',
                          style: AppTextStyles.body.copyWith(
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.textMuted,
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
                        borderRadius:
                            BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.border,
                        ),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Divider(
              height: 1,
              color: isDark
                  ? AppColors.darkBorder
                  : AppColors.border,
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
                      hint: '',
                    ),

                    const SizedBox(height: 24),

                    if (isPhone) ...[
                      _buildInput(
                        context,
                        label: 'EMAIL',
                        controller: _emailController,
                        hint: 'name@cims.edu.pk',
                      ),
                      const SizedBox(height: 18),
                      _buildDropdown(
                        context,
                        label: 'ROLE',
                        value: _selectedRole,
                        items: AppConstants.roles,
                        onChanged: (v) {
                          setState(() {
                            _selectedRole = v!;
                          });
                        },
                      ),
                    ] else
                      Row(
                        children: [
                          Expanded(
                            child: _buildInput(
                              context,
                              label: 'EMAIL',
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
                              items: AppConstants.roles,
                              onChanged: (v) {
                                setState(() {
                                  _selectedRole = v!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: isPhone ? double.infinity : 240,
                      child: _buildDropdown(
                        context,
                        label: 'ACCESS SCOPE',
                        value: _selectedScope,
                        items: AppConstants.accessScopes,
                        onChanged: (v) {
                          setState(() {
                            _selectedScope = v!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Divider(
              height: 1,
              color: isDark
                  ? AppColors.darkBorder
                  : AppColors.border,
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
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Cancel',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),

                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.add_rounded,
                        size: 18,
                      ),
                      label: const Text('+ Save'),
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

  // ======================================================
  // INPUT
  // ======================================================

  Widget _buildInput(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;
    final bool isTablet = screenWidth >= 600 && screenWidth < 1024;
    final bool isDesktop = screenWidth >= 1024;

    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary,
          ),
        ),

        const SizedBox(height: 10),

        SizedBox(
          height: 54,
          child: TextField(
            controller: controller,
            style: TextStyle(
              color: isDark
                  ? AppColors.darkText
                  : AppColors.text,
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

  // ======================================================
  // DROPDOWN
  // ======================================================

  Widget _buildDropdown(
    BuildContext context, {
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary,
          ),
        ),

        const SizedBox(height: 10),

        SizedBox(
          height: 54,
          child: DropdownButtonFormField<String>(
            initialValue: value,
            onChanged: onChanged,
            dropdownColor: isDark
                ? AppColors.darkSurfaceAlt
                : AppColors.surface,
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: isDark
                  ? AppColors.darkTextMuted
                  : AppColors.textMuted,
            ),
            decoration: const InputDecoration(),
            style: TextStyle(
              color: isDark
                  ? AppColors.darkText
                  : AppColors.text,
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
