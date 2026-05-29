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

class CreateInvoiceModal extends ConsumerStatefulWidget {
  const CreateInvoiceModal({
    super.key,
  });

  @override
  ConsumerState<CreateInvoiceModal> createState() => _CreateInvoiceModalState();
}

class _CreateInvoiceModalState extends ConsumerState<CreateInvoiceModal> {
  final _amountCtrl = TextEditingController();
  TextEditingController? _autocompleteCtrl;

  StudentApiModel? _selectedStudent;
  String _feeType = 'Tuition Fee';
  DateTime? _dueDate;
  int? _selectedSessionId;

  bool _saving = false;

  List<Map<String, dynamic>> _availableStructures = [];
  Map<String, dynamic>? _selectedStructure;

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

  void _prefillFromCurrentFeeType() {
    if (_availableStructures.isEmpty) {
      setState(() {
        _selectedStructure = null;
      });
      return;
    }

    final String targetType = _feeType == 'Tuition Fee' ? 'Tuition' : _feeType;

    final match = _availableStructures.firstWhere(
      (s) => s['fee_type']?.toString().toLowerCase() == targetType.toLowerCase(),
      orElse: () => {},
    );

    if (match.isNotEmpty) {
      setState(() {
        _selectedStructure = match;
        _amountCtrl.text = (num.tryParse(match['amount'].toString()) ?? 0).toStringAsFixed(0);
        final rawDate = match['due_date'];
        if (rawDate != null) {
          try {
            _dueDate = DateTime.parse(rawDate.toString());
          } catch (_) {}
        }
      });
    } else {
      setState(() {
        _selectedStructure = null;
      });
    }
  }

  Future<void> _loadStructures() async {
    final programId = _selectedStudent?.program?.id;
    final sessionId = _selectedSessionId;
    final stage = _selectedStudent?.currentStage;

    if (programId == null || sessionId == null) {
      setState(() {
        _availableStructures = [];
        _selectedStructure = null;
      });
      return;
    }

    setState(() {
      _selectedStructure = null;
      _availableStructures = [];
    });

    try {
      final repo = ref.read(feesRepositoryProvider);
      final res = await repo.listStructures(
        programId: programId,
        sessionId: sessionId,
        stage: stage,
      );
      final list = res['structures'] as List? ?? [];
      setState(() {
        _availableStructures = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      });
      _prefillFromCurrentFeeType();
    } catch (e) {
      // Fail silently
    }
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

    StudentApiModel? finalStudent = _selectedStudent;
    if (finalStudent != null && _autocompleteCtrl != null) {
      final disp = "${finalStudent.fullName} - ${finalStudent.studentIdCode ?? finalStudent.registrationNumber ?? ''}";
      if (_autocompleteCtrl!.text != disp) {
        finalStudent = null;
      }
    }

    if (finalStudent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a student')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final feesRepo = ref.read(feesRepositoryProvider);

      final feeTypeStr = _feeType == 'Tuition Fee' ? 'Tuition' : _feeType;

      if (finalStudent != null) {
        await feesRepo.createAssignment({
          'student_id': finalStudent.id,
          'fee_type': feeTypeStr,
          'amount': amount,
          'due_date': DateFormat('yyyy-MM-dd').format(_dueDate!),
          'academic_session_id': _selectedSessionId,
          'stage': finalStudent.currentStage,
        });
      }

      ref.invalidate(pendingAssignmentsProvider);
      ref.invalidate(feesDashboardProvider);
      ref.invalidate(feesTopDefaultersProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice created successfully')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate invoice: $e')),
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
                        Text('Create Invoice', style: AppTextStyles.h2),
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
                        onSelected: (option) {
                          setState(() {
                            _selectedStudent = option;
                          });
                          _loadStructures();
                        },
                        fieldViewBuilder: (context, controller, focusNode,
                            onFieldSubmitted) {
                          _autocompleteCtrl = controller;
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: const InputDecoration(
                              hintText: 'Search by name or roll no...',
                            ),
                            onChanged: (text) {
                              final currentSelectedText = _selectedStudent == null
                                  ? ''
                                  : "${_selectedStudent!.fullName} - ${_selectedStudent!.studentIdCode ?? _selectedStudent!.registrationNumber ?? ''}";
                              if (text != currentSelectedText && _selectedStudent != null) {
                                setState(() {
                                  _selectedStudent = null;
                                });
                                _loadStructures();
                              }
                            },
                          );
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Text('Error loading students',
                        style: TextStyle(color: AppColors.danger)),
                  ),
                  if (_selectedStudent != null && _selectedStudent!.program != null) ...[
                    const SizedBox(height: 20),
                    Text('PROGRAM',
                        style: AppTextStyles.label.copyWith(
                            color: AppColors.darkTextMuted, letterSpacing: 1.0)),
                    const SizedBox(height: 8),
                    InputDecorator(
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: AppColors.darkSurfaceAlt,
                      ),
                      child: Text(
                        _selectedStudent!.program!.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
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
                              onChanged: (v) {
                                setState(() {
                                  _feeType = v ?? _feeTypes.first;
                                });
                                _prefillFromCurrentFeeType();
                              },
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
                            if (_selectedStructure != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Default Billing: ${_selectedStructure!['billing_cycle'] ?? 'SEMESTER'} cycle detected',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
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
                                  onChanged: (v) {
                                    setState(() => _selectedSessionId = v);
                                    _loadStructures();
                                  },
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
                  const SizedBox(height: 20),
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
                    label: const Text('Create Invoice'),
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
