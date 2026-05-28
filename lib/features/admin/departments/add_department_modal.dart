import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cims/core/constants/app_colors.dart';
import 'package:cims/core/constants/app_text_styles.dart';
import 'package:cims/core/network/dio_error_message.dart';
import 'package:cims/core/utils/responsive.dart';
import 'package:cims/core/widgets/modal_sheet.dart';
import 'package:cims/features/admin/departments/models/create_department_request.dart';
import 'package:cims/features/admin/departments/models/department_category.dart';
import 'package:cims/features/admin/departments/models/department_model.dart';
import 'package:cims/features/admin/departments/models/update_department_request.dart';
import 'package:cims/features/admin/departments/providers/department_provider.dart';

class AddDepartmentModal extends ConsumerStatefulWidget {
  /// When set, modal edits via `PATCH /departments/{id}`.
  final DepartmentModel? department;

  const AddDepartmentModal({
    super.key,
    this.department,
  });

  @override
  ConsumerState<AddDepartmentModal> createState() =>
      _AddDepartmentModalState();
}

class _AddDepartmentModalState
    extends ConsumerState<AddDepartmentModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _codeCtrl;
  late final TextEditingController _descCtrl;

  late String _category;
  bool _saving = false;

  bool get _isEdit => widget.department != null;

  @override
  void initState() {
    super.initState();
    final d = widget.department;
    _nameCtrl = TextEditingController(text: d?.name ?? '');
    _codeCtrl = TextEditingController(text: d?.code ?? '');
    _descCtrl = TextEditingController(text: d?.description ?? '');
    _category =
        d != null && DepartmentCategory.apiValues.contains(d.category)
            ? d.category
            : DepartmentCategory.medical;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final name = _nameCtrl.text.trim();
    final code = _codeCtrl.text.trim().toUpperCase();
    final description = _descCtrl.text.trim();
    final descOrNull = description.isEmpty ? null : description;

    try {
      final repo = ref.read(departmentRepositoryProvider);

      if (_isEdit) {
        await repo.updateDepartment(
          id: widget.department!.id,
          request: UpdateDepartmentRequest(
            name: name,
            code: code,
            category: _category,
            description: descOrNull,
          ),
        );
      } else {
        await repo.createDepartment(
          CreateDepartmentRequest(
            name: name,
            code: code,
            category: _category,
            description: descOrNull,
          ),
        );
      }

      ref.invalidate(departmentsProvider);

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit
                ? 'Department updated'
                : 'Department created',
          ),
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            dioErrorMessage(
              e,
              fallback: 'Could not save department',
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
    Widget build(BuildContext context) {
      final screenWidth = MediaQuery.of(context).size.width;
      final bool isMobile = screenWidth < 600;
      final bool isTablet = screenWidth >= 600 && screenWidth < 1024;
      final bool isDesktop = screenWidth >= 1024;

      final isDark = Theme.of(context).brightness == Brightness.dark;

      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Container(
          width: Responsive.modalWidth(context),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 18, 18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isEdit ? 'Edit Department' : 'Add Department',
                              style: AppTextStyles.h2.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isEdit ? 'Update department details' : 'Create a new academic department',
                              style: AppTextStyles.body.copyWith(
                                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: _saving ? null : () => Navigator.pop(context),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.border,
                            ),
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 20,
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
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      CimsFormField(
                        label: 'Department Name',
                        controller: _nameCtrl,
                        hint: 'e.g. Medical Technology',
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 22),
                      Responsive.isMobile(context)
                          ? Column(
                              children: [
                                _codeField(),
                                const SizedBox(height: 18),
                                _categoryField(),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(child: _codeField()),
                                const SizedBox(width: 16),
                                Expanded(child: _categoryField()),
                              ],
                            ),
                      const SizedBox(height: 22),
                      CimsFormField(
                        label: 'Description',
                        controller: _descCtrl,
                        hint: "Brief description of the department's focus and offerings.",
                        maxLines: 4,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(22),
                      bottomRight: Radius.circular(22),
                    ),
                    border: Border(
                      top: BorderSide(
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _saving ? null : () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _saving ? null : _submit,
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(_isEdit ? Icons.save_outlined : Icons.add_rounded, size: 18),
                        label: Text(_isEdit ? 'Save Changes' : 'Create Department'),
                        style: ElevatedButton.styleFrom(minimumSize: const Size(180, 50)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

  Widget _codeField() {
    return CimsFormField(
      label: 'Code',
      controller: _codeCtrl,
      hint: 'MT',
      validator: (v) {
        if (v == null || v.trim().isEmpty) {
          return 'Code is required';
        }
        if (v.trim().length > 10) {
          return 'Code is too long';
        }
        return null;
      },
    );
  }

  Widget _categoryField() {
    return CimsDropdownField<String>(
      label: 'Category',
      value: _category,
      items: DepartmentCategory.apiValues,
      itemLabel: DepartmentCategory.label,
      onChanged: (v) {
        if (!_saving && v != null) {
          setState(() => _category = v);
        }
      },
    );
  }
}
