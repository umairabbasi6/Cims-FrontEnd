import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cims/core/constants/app_colors.dart';
import 'package:cims/core/constants/app_text_styles.dart';
import 'package:cims/features/admin/departments/providers/department_provider.dart';
import 'package:cims/features/admin/staff/providers/staff_provider.dart';

import 'package:cims/features/admin/staff/models/staff_api_model.dart';

class AddStaffModal extends ConsumerStatefulWidget {
  final StaffApiModel? staff;
  final bool isViewOnly;

  const AddStaffModal({
    super.key,
    this.staff,
    this.isViewOnly = false,
  });

  @override
  ConsumerState<AddStaffModal> createState() =>
      _AddStaffModalState();
}

class _AddStaffModalState
    extends ConsumerState<AddStaffModal> {
  String category = 'Medical';
  int? selectedDepartmentId;
  bool isActive = true;

  late final TextEditingController firstCtrl;
  late final TextEditingController lastCtrl;
  late final TextEditingController emailCtrl;
  late final TextEditingController phoneCtrl;
  late final TextEditingController designationCtrl;
  late final TextEditingController qualificationCtrl;
  late final TextEditingController joiningDateCtrl;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.staff != null) {
      firstCtrl = TextEditingController(text: widget.staff!.firstName);
      lastCtrl = TextEditingController(text: widget.staff!.lastName);
      emailCtrl = TextEditingController(text: widget.staff!.email ?? '');
      phoneCtrl = TextEditingController(text: widget.staff!.phone ?? '');
      designationCtrl = TextEditingController(text: widget.staff!.designation);
      qualificationCtrl = TextEditingController(text: widget.staff!.qualification ?? '');
      joiningDateCtrl = TextEditingController(text: widget.staff!.joiningDate ?? '');

      final apiCat = widget.staff!.category.toLowerCase();
      if (apiCat == 'medical') category = 'Medical';
      else if (apiCat == 'academic') category = 'Academic';
      else if (apiCat == 'admin') category = 'Admin';
      else if (apiCat == 'nursing') category = 'Nursing';

      selectedDepartmentId = widget.staff!.department?.id;
      isActive = widget.staff!.isActive;
    } else {
      firstCtrl = TextEditingController();
      lastCtrl = TextEditingController();
      emailCtrl = TextEditingController(text: 'name@cims.edu.pk');
      phoneCtrl = TextEditingController();
      designationCtrl = TextEditingController(text: 'Senior Lecturer');
      qualificationCtrl = TextEditingController(text: 'MPhil Physiotherapy');
      joiningDateCtrl = TextEditingController(
        text: '${DateTime.now().year.toString().padLeft(4, '0')}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}'
      );
      isActive = true;
    }
  }

  @override
  void dispose() {
    firstCtrl.dispose();
    lastCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    designationCtrl.dispose();
    qualificationCtrl.dispose();
    joiningDateCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final firstName = firstCtrl.text.trim();
    final lastName = lastCtrl.text.trim();
    final email = emailCtrl.text.trim();
    final phone = phoneCtrl.text.trim();
    final designation = designationCtrl.text.trim();
    final qualification = qualificationCtrl.text.trim();
    final joiningDate = joiningDateCtrl.text.trim();

    if (firstName.isEmpty || lastName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('First name and Last name are required.')),
      );
      return;
    }

    if (selectedDepartmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a department.')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final repository = ref.read(staffRepositoryProvider);
      
      final categoryEnum = category.toUpperCase(); // MEDICAL, ACADEMIC, ADMIN

      final data = {
        'first_name': firstName,
        'last_name': lastName,
        'email': email.isEmpty ? null : email,
        'phone': phone.isEmpty ? null : phone,
        'category': categoryEnum,
        'department_id': selectedDepartmentId,
        'designation': designation,
        'qualification': qualification.isEmpty ? null : qualification,
        'joining_date': joiningDate.isEmpty ? null : joiningDate,
        if (widget.staff != null) 'is_active': isActive,
      };

      if (widget.staff != null) {
        await repository.updateStaff(widget.staff!.id, data);
      } else {
        await repository.createStaff(data);
      }

      ref.invalidate(staffListProvider(null));
      ref.invalidate(staffListProvider(categoryEnum));
      ref.invalidate(allStaffListProvider(null));
      ref.invalidate(allStaffListProvider(categoryEnum));
      if (widget.staff != null && widget.staff!.category.toUpperCase() != categoryEnum) {
        ref.invalidate(staffListProvider(widget.staff!.category.toUpperCase()));
        ref.invalidate(allStaffListProvider(widget.staff!.category.toUpperCase()));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.staff != null ? 'Staff member updated successfully.' : 'Staff member added successfully.')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save staff: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final deptsAsync = ref.watch(departmentsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 560,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppColors.darkBorder,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isViewOnly
                              ? 'Staff Details'
                              : (widget.staff != null ? 'Edit Staff' : 'Add Staff'),
                          style: AppTextStyles.h2,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.isViewOnly ? 'View staff member profiles' : 'Fill the details below',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.darkTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: AppColors.darkBorder,
            ),
            // FORM
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _field('FIRST NAME', firstCtrl),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _field('LAST NAME', lastCtrl),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: _field('EMAIL', emailCtrl),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _field('PHONE', phoneCtrl),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: _dropdown(
                            'CATEGORY',
                            category,
                            ['Medical', 'Academic', 'Admin', 'Nursing'],
                            (v) => setState(() => category = v!),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: deptsAsync.when(
                            data: (list) {
                              // Auto-select first department if none selected and list is not empty
                              if (selectedDepartmentId == null && list.isNotEmpty) {
                                selectedDepartmentId = list.first.id;
                              }
                              return _deptDropdown(
                                'DEPARTMENT',
                                selectedDepartmentId,
                                list,
                                (v) => setState(() => selectedDepartmentId = v),
                              );
                            },
                            loading: () => const Padding(
                              padding: EdgeInsets.only(top: 24),
                              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            ),
                            error: (err, _) => Padding(
                              padding: const EdgeInsets.only(top: 24),
                              child: Text('Error loading departments', style: TextStyle(color: AppColors.danger)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: _field('DESIGNATION', designationCtrl),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _dateField('JOINING DATE', joiningDateCtrl),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    _field('QUALIFICATION', qualificationCtrl),
                    if (widget.staff != null) ...[
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Text(
                            'STAFF STATUS',
                            style: AppTextStyles.label,
                          ),
                          const Spacer(),
                          Switch(
                            value: isActive,
                            onChanged: widget.isViewOnly
                                ? null
                                : (v) => setState(() => isActive = v),
                            activeColor: AppColors.success,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isActive ? 'Active' : 'Inactive',
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isActive ? AppColors.success : AppColors.danger,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // FOOTER
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.darkSurfaceAlt,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(22),
                  bottomRight: Radius.circular(22),
                ),
                border: Border(
                  top: BorderSide(
                    color: AppColors.darkBorder,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: widget.isViewOnly
                    ? [
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ]
                    : [
                        TextButton(
                          onPressed: _saving ? null : () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: _saving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.add_rounded),
                          label: const Text('Save'),
                        ),
                      ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 10),
        TextField(
          controller: ctrl,
          enabled: !widget.isViewOnly,
        ),
      ],
    );
  }

  Widget _dropdown(
    String label,
    String value,
    List<String> items,
    void Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: value,
          decoration: const InputDecoration(),
          dropdownColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : AppColors.surface,
          isExpanded: true,
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    e,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              )
              .toList(),
          onChanged: widget.isViewOnly ? null : onChanged,
        ),
      ],
    );
  }

  Widget _deptDropdown(
    String label,
    int? value,
    List<dynamic> items,
    void Function(int?) onChanged,
  ) {
    // Ensure the current value is present in items list to avoid crashes
    final hasValue = value != null && items.any((e) => e.id == value);
    final initial = hasValue ? value : (items.isNotEmpty ? items.first.id : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 10),
        DropdownButtonFormField<int>(
          initialValue: initial,
          decoration: const InputDecoration(),
          dropdownColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : AppColors.surface,
          isExpanded: true,
          items: items
              .map(
                (e) => DropdownMenuItem<int>(
                  value: e.id as int,
                  child: Text(
                    e.name as String,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              )
              .toList(),
          onChanged: widget.isViewOnly ? null : onChanged,
        ),
      ],
    );
  }

  Widget _dateField(
    String label,
    TextEditingController ctrl,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 10),
        TextField(
          controller: ctrl,
          readOnly: true,
          decoration: InputDecoration(
            hintText: 'yyyy-mm-dd',
            suffixIcon: widget.isViewOnly ? null : const Icon(
              Icons.calendar_today_rounded,
            ),
          ),
          onTap: widget.isViewOnly ? null : () async {
            DateTime initial = DateTime.now();
            try {
              if (ctrl.text.isNotEmpty) {
                initial = DateTime.parse(ctrl.text);
              }
            } catch (_) {}
            
            final picked = await showDatePicker(
              context: context,
              initialDate: initial,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              setState(() {
                ctrl.text = '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
              });
            }
          },
        ),
      ],
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: AppTextStyles.label,
    );
  }
}