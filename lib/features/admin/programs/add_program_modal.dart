import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cims/core/constants/app_colors.dart';
import 'package:cims/core/constants/app_text_styles.dart';
import 'package:cims/core/network/dio_error_message.dart';
import 'package:cims/core/utils/responsive.dart';
import 'package:cims/core/widgets/modal_sheet.dart';
import 'package:cims/features/admin/departments/models/department_model.dart';
import 'package:cims/features/admin/departments/providers/department_provider.dart';
import 'package:cims/features/admin/programs/models/create_program_request.dart';
import 'package:cims/features/admin/programs/models/program_model.dart';
import 'package:cims/features/admin/programs/models/update_program_request.dart';
import 'package:cims/features/admin/programs/providers/program_provider.dart';

const _programTypes = ['Semester', 'Annual', 'Diploma'];

const _levels = [
  'Intermediate',
  'Diploma',
  'Undergraduate',
  'Graduate',
];

class AddProgramModal extends ConsumerStatefulWidget {
  final ProgramModel? program;

  const AddProgramModal({super.key, this.program});

  @override
  ConsumerState<AddProgramModal> createState() =>
      _AddProgramModalState();
}

class _AddProgramModalState extends ConsumerState<AddProgramModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _codeCtrl;
  late final TextEditingController _stagesCtrl;
  late final TextEditingController _awardCtrl;

  DepartmentModel? _department;
  String _level = 'Undergraduate';
  String _programType = 'Semester';
  int _duration = 4;
  bool _saving = false;

  bool get _isEdit => widget.program != null;

  @override
  void initState() {
    super.initState();
    final p = widget.program;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _codeCtrl = TextEditingController(text: p?.code ?? '');
    _awardCtrl = TextEditingController(text: p?.award ?? '');
    _programType =
        p != null && _programTypes.contains(p.programType)
            ? p.programType
            : 'Semester';

    if (p != null) {
      if (p.programType == 'Semester') {
        _duration = (p.totalStages / 2).ceil();
      } else {
        _duration = p.totalStages;
      }
      if (![1, 2, 4, 5].contains(_duration)) {
        _duration = 4;
      }
    }

    _stagesCtrl = TextEditingController(
      text: '${_calculateStages()}',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _stagesCtrl.dispose();
    _awardCtrl.dispose();
    super.dispose();
  }

  int _calculateStages() {
    if (_programType == 'Semester') {
      return _duration * 2;
    }
    // For Annual or Diploma, it's 1 stage per year
    return _duration;
  }

  void _updateStages() {
    _stagesCtrl.text = _calculateStages().toString();
  }

  Future<void> _submit() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    final dept = _department;
    if (!_isEdit && dept == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a department')),
      );
      return;
    }

    final stages = int.tryParse(_stagesCtrl.text.trim());
    if (stages == null || stages < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid total stages')),
      );
      return;
    }

    setState(() => _saving = true);

    final name = _nameCtrl.text.trim();
    final code = _codeCtrl.text.trim();
    final award = _awardCtrl.text.trim();
    final awardOrNull = award.isEmpty ? null : award;

    try {
      final repo = ref.read(programRepositoryProvider);

      if (_isEdit) {
        await repo.updateProgram(
          id: widget.program!.id,
          request: UpdateProgramRequest(
            name: name,
            code: code.isEmpty ? null : code,
            programType: _programType,
            duration: _duration,
            totalStages: _calculateStages(),
            award: awardOrNull,
          ),
        );
      } else {
        await repo.createProgram(
          CreateProgramRequest(
            departmentId: dept!.id,
            name: name,
            code: code.isEmpty ? name.substring(0, name.length.clamp(0, 4)).toUpperCase() : code,
            programType: _programType,
            duration: _duration,
            totalStages: _calculateStages(),
            award: awardOrNull,
          ),
        );
      }

      ref.invalidate(programsProvider);

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit ? 'Program updated' : 'Program created',
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
              fallback: 'Could not save program',
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


    final isDark =
        Theme.of(context).brightness == Brightness.dark;
    final departmentsAsync = ref.watch(departmentsProvider);

    return Dialog(
      backgroundColor : Colors.transparent,
      insetPadding : const EdgeInsets.all(24),
      child : Container(
        width: Responsive.modalWidth(context),
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color:
              isDark ? AppColors.darkSurface : AppColors.surface,
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
                            _isEdit ? 'Edit Program' : 'Add Program',
                            style: AppTextStyles.h2.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Configure academic program details',
                            style: AppTextStyles.body.copyWith(
                              color:
                                  isDark
                                      ? AppColors.darkTextMuted
                                      : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap:
                          _saving
                              ? null
                              : () => Navigator.pop(context),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color:
                                isDark
                                    ? AppColors.darkBorder
                                    : AppColors.border,
                          ),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 20,
                          color:
                              isDark
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
                color: isDark ? AppColors.darkBorder : AppColors.border,
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: departmentsAsync.when(
                    loading:
                        () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                    error:
                        (e, _) => Text('Could not load departments: $e'),
                    data: (departments) {
                      if (_department == null && departments.isNotEmpty) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          setState(() => _ensureDepartmentSelected(departments));
                        });
                      }

                      return Column(
                        children: [
                          CimsFormField(
                            label: 'Program Name',
                            controller: _nameCtrl,
                            hint: 'e.g. BS Medical Lab Technology',
                            validator:
                                (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Program name is required'
                                        : null,
                          ),
                          const SizedBox(height: 18),
                          CimsFormField(
                            label: 'Program Code',
                            controller: _codeCtrl,
                            hint: 'e.g. BS-MLT',
                            validator:
                                (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Program code is required'
                                        : null,
                          ),
                          const SizedBox(height: 18),
                          Responsive.isMobile(context)
                              ? Column(
                                children: [
                                  _departmentField(departments),
                                  const SizedBox(height: 18),
                                  _typeField(),
                                ],
                              )
                              : Row(
                                children: [
                                  Expanded(
                                    child: _departmentField(
                                      departments,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(child: _typeField()),
                                ],
                              ),
                          const SizedBox(height: 18),
                          Responsive.isMobile(context)
                              ? Column(
                                children: [
                                  _durationDropdown(),
                                  const SizedBox(height: 18),
                                  _stagesField(),
                                ],
                              )
                              : Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _durationDropdown()),
                                  const SizedBox(width: 16),
                                  Expanded(child: _stagesField()),
                                ],
                              ),
                          const SizedBox(height: 18),
                          _levelField(),
                          const SizedBox(height: 18),
                          _awardField(),
                        ],
                      );
                    },
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? AppColors.darkSurfaceAlt
                          : AppColors.surfaceAlt,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(22),
                    bottomRight: Radius.circular(22),
                  ),
                  border: Border(
                    top: BorderSide(
                      color:
                          isDark
                              ? AppColors.darkBorder
                              : AppColors.border,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          _saving
                              ? null
                              : () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _saving ? null : _submit,
                      icon:
                          _saving
                              ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Icon(
                                Icons.add_rounded,
                                size: 18,
                              ),
                      label: Text(_isEdit ? 'Save Program' : 'Save Program'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(120, 50),
                      ),
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

  void _ensureDepartmentSelected(List<DepartmentModel> departments) {
    if (_department != null || departments.isEmpty) return;
    final existing = widget.program;
    if (existing != null) {
      _department = departments
          .where((d) => d.id == existing.department.id)
          .firstOrNull;
    }
    _department ??= departments.firstWhere(
      (d) => d.isActive,
      orElse: () => departments.first,
    );
  }

  Widget _departmentField(List<DepartmentModel> departments) {
    if (_isEdit && widget.program != null) {
      return CimsFormField(
        label: 'Department',
        controller: TextEditingController(
          text: widget.program!.department.code,
        ),
        hint: widget.program!.department.name,
      );
    }

    return CimsDropdownField<DepartmentModel>(
      label: 'Department',
      value: _department,
      items: departments.where((d) => d.isActive).toList(),
      itemLabel: (d) => d.code,
      onChanged:
          _saving
              ? (_) {}
              : (v) {
                if (v != null) setState(() => _department = v);
              },
    );
  }

Widget _durationDropdown() {
  return CimsDropdownField<int>(
    label: 'Duration',
    value: _duration,
    items: const [1, 2, 4, 5],
    itemLabel: (v) => '$v Year${v > 1 ? 's' : ''}',
    onChanged: (v) {
      if (_saving || v == null) return;

      setState(() {
        _duration = v;
        _updateStages();
      });
    },
  );
}
  Widget _levelField() {
    return CimsDropdownField<String>(
      label: 'Program Level',
      value: _level,
      items: _levels,
      itemLabel: (e) => e,
      onChanged: (v) {
        if (_saving || v == null) return;
        setState(() => _level = v);
      },
    );
  }

  Widget _typeField() {
    return CimsDropdownField<String>(
      label: 'Academic System',
      value: _programType,
      items: const ['Semester', 'Annual'],
      itemLabel: (e) => e,
      onChanged: (v) {
        if (_saving || v == null) return;
        setState(() {
          _programType = v;
          _updateStages();
        });
      },
    );
  }

  Widget _stagesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CimsFormField(
          label: _programType == 'Semester'
              ? 'Total Semesters'
              : 'Total Years',
          controller: _stagesCtrl,
          readOnly: true,
          prefixIcon: const Icon(
            Icons.calculate,
            size: 18,
          ),
        ),
        const SizedBox(height: 6),
        Text(_programType == 'Semester'
              ? 'Auto calculated as semesters'
              : _programType == 'Diploma'
                  ? 'Auto calculated as terms'
                  : 'Auto calculated as years',
          style: AppTextStyles.caption.copyWith(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkTextMuted
                : AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _awardField() {
    return CimsFormField(
      label: 'Award',
      controller: _awardCtrl,
      hint: 'e.g. BS, FSc, Diploma',
    );
  }
}
