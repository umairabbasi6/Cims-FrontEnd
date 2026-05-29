import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import 'package:cims/core/constants/app_colors.dart';
import 'package:cims/core/constants/app_text_styles.dart';
import 'package:cims/core/utils/responsive.dart';
import 'package:cims/core/network/dio_error_message.dart';
import 'package:cims/features/admin/subjects/providers/subject_provider.dart';
import 'package:cims/features/admin/staff/providers/staff_provider.dart';
import 'package:cims/features/timetable/providers/timetable_provider.dart';
import 'package:cims/features/admin/programs/providers/program_provider.dart';

class AddSlotModal extends ConsumerStatefulWidget {
  final int programId;
  final int stage;
  final int sessionId;

  const AddSlotModal({
    super.key,
    required this.programId,
    required this.stage,
    required this.sessionId,
  });

  @override
  ConsumerState<AddSlotModal> createState() => _AddSlotModalState();
}

class _AddSlotModalState extends ConsumerState<AddSlotModal> {
  final _formKey = GlobalKey<FormState>();

  int? _selectedProgramId;
  int? _selectedStage;
  int? _selectedSubjectId;
  int? _selectedTeacherId;
  String _selectedDay = 'Monday';
  String _selectedClassType = 'Theory';

  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  final _roomCtrl = TextEditingController(text: '201');
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedProgramId = widget.programId;
    _selectedStage = widget.stage;
  }

  @override
  void dispose() {
    _roomCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectStartTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  Future<void> _submit() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    if (_selectedProgramId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a program')),
      );
      return;
    }

    if (_selectedStage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a stage')),
      );
      return;
    }

    if (_selectedSubjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a subject')),
      );
      return;
    }

    if (_selectedTeacherId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a teacher')),
      );
      return;
    }

    if (_startTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start time')),
      );
      return;
    }

    if (_endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select end time')),
      );
      return;
    }

    final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
    final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
    if (startMinutes >= endMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Start time must be before end time')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final repo = ref.read(timetableRepositoryProvider);

      String formatTime(TimeOfDay time) {
        final h = time.hour.toString().padLeft(2, '0');
        final m = time.minute.toString().padLeft(2, '0');
        return '$h:$m:00';
      }

      await repo.createSlot(
        subjectId: _selectedSubjectId!,
        staffId: _selectedTeacherId!,
        sessionId: widget.sessionId,
        stage: _selectedStage!,
        dayOfWeek: _selectedDay,
        startTime: formatTime(_startTime!),
        endTime: formatTime(_endTime!),
        room: _roomCtrl.text.trim(),
        classType: _selectedClassType.toUpperCase(),
      );

      ref.invalidate(timetableWeeklyProvider);

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Timetable slot added successfully')),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            dioErrorMessage(
              e,
              fallback: 'Could not add timetable slot. Double booking?',
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPhone = Responsive.isMobile(context);

    final programsAsync = ref.watch(programsProvider);
    final stagesAsync = _selectedProgramId != null
        ? ref.watch(programStagesProvider(_selectedProgramId!))
        : null;
    final subjectsAsync = (_selectedProgramId != null && _selectedStage != null)
        ? ref.watch(subjectsByProgramAndStageProvider((
            programId: _selectedProgramId,
            stage: _selectedStage,
          )))
        : null;
    final staffAsync = ref.watch(staffListProvider(null));

    // Program Dropdown Widget
    final programField = programsAsync.when(
      loading: () => _loadingDropdownField(label: 'PROGRAM'),
      error: (err, _) => _errorDropdownField(label: 'PROGRAM', error: err.toString()),
      data: (programs) {
        if (_selectedProgramId != null && !programs.any((p) => p.id == _selectedProgramId)) {
          _selectedProgramId = null;
        }
        return _customDropdownField<int>(
          label: 'PROGRAM',
          value: _selectedProgramId,
          items: programs.map((p) => p.id).toList(),
          itemLabel: (id) => programs.firstWhere((p) => p.id == id).name,
          onChanged: (v) {
            setState(() {
              _selectedProgramId = v;
              _selectedStage = null;
              _selectedSubjectId = null;
            });
          },
        );
      },
    );

    // Stage Dropdown Widget
    final stageField = _selectedProgramId == null
        ? _disabledDropdownField(label: 'STAGE', hint: 'Select Program first')
        : stagesAsync == null
            ? _disabledDropdownField(label: 'STAGE', hint: 'No stages available')
            : stagesAsync.when(
                loading: () => _loadingDropdownField(label: 'STAGE'),
                error: (err, _) => _errorDropdownField(label: 'STAGE', error: err.toString()),
                data: (stages) {
                  if (_selectedStage != null && !stages.any((s) => s.stage == _selectedStage)) {
                    _selectedStage = null;
                  }
                  return _customDropdownField<int>(
                    label: 'STAGE',
                    value: _selectedStage,
                    items: stages.map((s) => s.stage).toList(),
                    itemLabel: (stageVal) => stages.firstWhere((s) => s.stage == stageVal).label,
                    onChanged: (v) {
                      setState(() {
                        _selectedStage = v;
                        _selectedSubjectId = null;
                      });
                    },
                  );
                },
              );

    // Subject Dropdown Widget
    final subjectField = _selectedProgramId == null || _selectedStage == null
        ? _disabledDropdownField(label: 'SUBJECT', hint: 'Select Program & Stage')
        : subjectsAsync == null
            ? _disabledDropdownField(label: 'SUBJECT', hint: 'No subjects available')
            : subjectsAsync.when(
                loading: () => _loadingDropdownField(label: 'SUBJECT'),
                error: (err, _) => _errorDropdownField(label: 'SUBJECT', error: err.toString()),
                data: (subjects) {
                  if (_selectedSubjectId != null && !subjects.any((s) => s.id == _selectedSubjectId)) {
                    _selectedSubjectId = null;
                  }
                  if (_selectedSubjectId == null && subjects.isNotEmpty) {
                    _selectedSubjectId = subjects.first.id;
                  }
                  return _customDropdownField<int>(
                    label: 'SUBJECT',
                    value: _selectedSubjectId,
                    items: subjects.map((s) => s.id).toList(),
                    itemLabel: (id) => subjects.firstWhere((s) => s.id == id).name,
                    onChanged: (v) => setState(() => _selectedSubjectId = v),
                  );
                },
              );

    // Teacher Dropdown Widget
    final teacherField = staffAsync.when(
      loading: () => _loadingDropdownField(label: 'TEACHER'),
      error: (err, _) => _errorDropdownField(label: 'TEACHER', error: err.toString()),
      data: (staffList) {
        final teachers = staffList.where((s) =>
          s.isActive && ['MEDICAL', 'ACADEMIC', 'NURSING'].contains(s.category.toUpperCase())
        ).toList();

        if (_selectedTeacherId != null && !teachers.any((t) => t.id == _selectedTeacherId)) {
          _selectedTeacherId = null;
        }
        if (_selectedTeacherId == null && teachers.isNotEmpty) {
          _selectedTeacherId = teachers.first.id;
        }

        return _customDropdownField<int>(
          label: 'TEACHER',
          value: _selectedTeacherId,
          items: teachers.map((t) => t.id).toList(),
          itemLabel: (id) => teachers.firstWhere((t) => t.id == id).fullName,
          onChanged: (v) => setState(() => _selectedTeacherId = v),
        );
      },
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: Responsive.modalInsetPadding(context),
      child: Container(
        width: Responsive.modalWidth(context),
        constraints: BoxConstraints(
          maxWidth: isPhone ? double.infinity : 540,
          maxHeight: isPhone ? MediaQuery.of(context).size.height * 0.92 : 720,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: const Radius.circular(22),
            bottom: Radius.circular(isPhone ? 0 : 22),
          ),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Timetable Slot',
                          style: AppTextStyles.h2,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Fill the details below',
                          style: AppTextStyles.body.copyWith(
                            color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Divider(
              color: isDark ? AppColors.darkBorder : AppColors.border,
              height: 1,
            ),
            Flexible(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _responsiveRow(
                        context,
                        programField,
                        stageField,
                      ),
                      const SizedBox(height: 22),
                      _responsiveRow(
                        context,
                        subjectField,
                        teacherField,
                      ),
                      const SizedBox(height: 22),
                      _responsiveRow(
                        context,
                        _customDropdownField<String>(
                          label: 'DAY',
                          value: _selectedDay,
                          items: const [
                            'Monday',
                            'Tuesday',
                            'Wednesday',
                            'Thursday',
                            'Friday',
                            'Saturday',
                          ],
                          itemLabel: (v) => v,
                          onChanged: (v) => setState(() => _selectedDay = v!),
                        ),
                        _timeField('START TIME', _startTime, () => _selectStartTime(context)),
                      ),
                      const SizedBox(height: 22),
                      _responsiveRow(
                        context,
                        _timeField('END TIME', _endTime, () => _selectEndTime(context)),
                        _textField('ROOM', _roomCtrl),
                      ),
                      const SizedBox(height: 22),
                      _responsiveRow(
                        context,
                        _customDropdownField<String>(
                          label: 'CLASS TYPE',
                          value: _selectedClassType,
                          items: const [
                            'Theory',
                            'Lab',
                            'Both',
                            'Elective',
                          ],
                          itemLabel: (v) => v,
                          onChanged: (v) => setState(() => _selectedClassType = v!),
                        ),
                        const SizedBox.shrink(),
                        keepSecondOnDesktopOnly: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(isPhone ? 0 : 22),
                ),
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                ),
              ),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 12,
                runSpacing: 12,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _saving ? null : _submit,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.add_rounded),
                    label: Text(_saving ? 'Saving...' : 'Save'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _responsiveRow(
    BuildContext context,
    Widget first,
    Widget second, {
    bool keepSecondOnDesktopOnly = false,
  }) {
    if (Responsive.isMobile(context)) {
      return Column(
        children: [
          first,
          if (!keepSecondOnDesktopOnly) ...[
            const SizedBox(height: 18),
            second,
          ],
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: first),
        const SizedBox(width: 16),
        Expanded(
          child: keepSecondOnDesktopOnly ? const SizedBox() : second,
        ),
      ],
    );
  }

  Widget _customDropdownField<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T?) onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 10),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              dropdownColor: isDark ? AppColors.darkSurface : AppColors.surface,
              style: AppTextStyles.body.copyWith(
                color: isDark ? AppColors.darkText : AppColors.text,
              ),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
              onChanged: onChanged,
              items: items
                  .map(
                    (e) => DropdownMenuItem<T>(
                      value: e,
                      child: Text(
                        itemLabel(e),
                        style: TextStyle(
                          color: isDark ? AppColors.darkText : AppColors.text,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _disabledDropdownField({
    required String label,
    required String hint,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 10),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceAlt.withOpacity(0.5) : AppColors.surfaceAlt.withOpacity(0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.darkBorder.withOpacity(0.5) : AppColors.border.withOpacity(0.5),
            ),
          ),
          child: Text(
            hint,
            style: AppTextStyles.body.copyWith(
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _loadingDropdownField({
    required String label,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 10),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Loading...',
                style: AppTextStyles.body.copyWith(
                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                ),
              ),
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _errorDropdownField({
    required String label,
    required String error,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 10),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.red.withOpacity(0.8),
            ),
          ),
          child: Text(
            error,
            style: AppTextStyles.body.copyWith(
              color: Colors.redAccent,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _timeField(String label, TimeOfDay? value, VoidCallback onTap) {
    final text = value != null ? value.format(context) : '--:-- --';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 10),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.border,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  text,
                  style: AppTextStyles.body.copyWith(
                    color: value != null
                        ? (isDark ? AppColors.darkText : AppColors.text)
                        : (isDark ? AppColors.darkTextMuted : AppColors.textMuted),
                    fontWeight: value != null ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                Icon(
                  Icons.access_time_rounded,
                  size: 20,
                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _textField(
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
          decoration: const InputDecoration(
            isDense: true,
          ),
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
