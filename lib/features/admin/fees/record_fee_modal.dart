import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:cims/core/constants/app_colors.dart';
import 'package:cims/core/constants/app_text_styles.dart';
import 'package:cims/features/admin/fees/providers/fees_api_provider.dart';
import 'package:cims/features/admin/students/providers/student_provider.dart';
import 'package:cims/features/admin/students/models/student_api_model.dart';
import 'package:cims/features/admin/sessions/providers/session_provider.dart';
import 'package:cims/features/admin/programs/providers/program_provider.dart';
import 'package:cims/features/admin/programs/models/program_model.dart';

class RecordFeeModal extends ConsumerStatefulWidget {
  const RecordFeeModal({
    super.key,
  });

  @override
  ConsumerState<RecordFeeModal> createState() => _RecordFeeModalState();
}

class _RecordFeeModalState extends ConsumerState<RecordFeeModal> {
  final _amountCtrl = TextEditingController();

  StudentApiModel? _selectedStudent;
  int? _selectedProgramId;
  String _feeType = 'Tuition Fee';
  DateTime? _dueDate;
  int? _selectedSessionId;

  bool _saving = false;

  final List<String> _feeTypes = [
    'Tuition Fee',
    'Examination',
    'Library',
    'Registration',
    'Other',
  ];

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.darkSurface,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }

    if (_dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a due date')),
      );
      return;
    }

    if (_selectedSessionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a term (session)')),
      );
      return;
    }

    if (_selectedProgramId == null && _selectedStudent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a program or a student')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final feesRepo = ref.read(feesRepositoryProvider);

      final feeTypeStr = _feeType == 'Tuition Fee' ? 'Tuition' : _feeType;

      await feesRepo.createStructure({
        if (_selectedStudent != null) 'student_id': _selectedStudent!.id,
        'program_id': _selectedProgramId ?? _selectedStudent?.program?.id ?? 0,
        'session_id': _selectedSessionId,
        'fee_type': feeTypeStr,
        'amount': amount,
        'due_date': DateFormat('yyyy-MM-dd').format(_dueDate!),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fee recorded successfully')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to record fee: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentsListProvider);
    final sessionsAsync = ref.watch(sessionsListProvider);
    final programsAsync = ref.watch(programsProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 560,
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CrAssign Fee', style: AppTextStyles.h2),
                        const SizedBox(height: 4),
                        Text('Fill the details below',
                            style: AppTextStyles.body.copyWith(
                                color: AppColors.darkTextMuted)),
                      ],
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.darkBorder),
                      ),
                      child: Icon(Icons.close_rounded,
                          color: AppColors.darkTextMuted),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: AppColors.darkBorder),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('STUDENT',
                      style: AppTextStyles.label.copyWith(
                          color: AppColors.darkTextMuted, letterSpacing: 1.0)),
                  const SizedBox(height: 8),
                  studentsAsync.when(
                    data: (students) {
                      return Autocomplete<StudentApiModel>(
                        displayStringForOption: (s) =>
                            "${s.fullName} - ${s.studentIdCode ?? s.registrationNumber ?? ''}",
                        optionsBuilder: (textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return const Iterable<StudentApiModel>.empty();
                          }
                          final query = textEditingValue.text.toLowerCase();
                          return students.where((s) {
                            final nameMatch =
                                s.fullName.toLowerCase().contains(query);
                            final codeMatch = (s.studentIdCode ??
                                    s.registrationNumber ??
                                    '')
                                .toLowerCase()
                                .contains(query);
                            return nameMatch || codeMatch;
                          });
                        },
                        onSelected: (option) =>
                            setState(() => _selectedStudent = option),
                        fieldViewBuilder: (context, controller, focusNode,
                            onFieldSubmitted) {
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: const InputDecoration(
                              hintText: 'Search by name or roll no...',
                            ),
                          );
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Text('Error loading students',
                        style: TextStyle(color: AppColors.danger)),
                  ),
                  const SizedBox(height: 20),
                  Text('PROGRAM (OPTIONAL)',
                      style: AppTextStyles.label.copyWith(
                          color: AppColors.darkTextMuted, letterSpacing: 1.0)),
                  const SizedBox(height: 8),
                  programsAsync.when(
                    data: (programs) {
                      return DropdownButtonFormField<int>(
                        value: _selectedProgramId,
                        decoration: const InputDecoration(
                          hintText: 'Select program (leave blank if student selected)',
                        ),
                        dropdownColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : AppColors.surface,
                        items: [
                          const DropdownMenuItem<int>(
                            value: null,
                            child: Text('None (Individual Student)'),
                          ),
                          ...programs.map((p) => DropdownMenuItem(
                              value: p.id, child: Text(p.name)))
                        ],
                        onChanged: (v) =>
                            setState(() => _selectedProgramId = v),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Text('Error loading programs',
                        style: TextStyle(color: AppColors.danger)),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('FEE TYPE',
                                style: AppTextStyles.label.copyWith(
                                    color: AppColors.darkTextMuted,
                                    letterSpacing: 1.0)),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _feeType,
                              dropdownColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : AppColors.surface,
                              items: _feeTypes
                                  .map((e) => DropdownMenuItem(
                                      value: e, child: Text(e)))
                                  .toList(),
                              onChanged: (v) => setState(
                                  () => _feeType = v ?? _feeTypes.first),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('AMOUNT (PKR)',
                                style: AppTextStyles.label.copyWith(
                                    color: AppColors.darkTextMuted,
                                    letterSpacing: 1.0)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _amountCtrl,
                              decoration: const InputDecoration(
                                hintText: '25000',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('DUE DATE',
                                style: AppTextStyles.label.copyWith(
                                    color: AppColors.darkTextMuted,
                                    letterSpacing: 1.0)),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: _selectDueDate,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  suffixIcon:
                                      Icon(Icons.calendar_today_rounded),
                                ),
                                child: Text(
                                  _dueDate != null
                                      ? DateFormat('MM/dd/yyyy')
                                          .format(_dueDate!)
                                      : 'mm/dd/yyyy',
                                  style: TextStyle(
                                    color: _dueDate != null
                                        ? Colors.white
                                        : AppColors.darkTextMuted,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('TERM',
                                style: AppTextStyles.label.copyWith(
                                    color: AppColors.darkTextMuted,
                                    letterSpacing: 1.0)),
                            const SizedBox(height: 8),
                            sessionsAsync.when(
                              data: (sessions) {
                                return DropdownButtonFormField<int>(
                                  value: _selectedSessionId,
                                  decoration: const InputDecoration(
                                    hintText: 'Select term',
                                  ),
                                  dropdownColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : AppColors.surface,
                                  items: sessions
                                      .map((s) => DropdownMenuItem(
                                          value: s.id, child: Text(s.name)))
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => _selectedSessionId = v),
                                );
                              },
                              loading: () =>
                                  const Center(child: CircularProgressIndicator()),
                              error: (err, _) => Text('Error loading sessions',
                                  style: TextStyle(color: AppColors.danger)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: AppColors.darkBorder),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                    ),
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
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
}
