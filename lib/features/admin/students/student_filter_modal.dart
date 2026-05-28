import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cims/core/constants/app_colors.dart';
import 'package:cims/core/constants/app_text_styles.dart';
import 'package:cims/features/admin/programs/providers/program_provider.dart';
import 'package:cims/features/admin/sessions/providers/session_provider.dart';
import 'package:cims/features/admin/students/providers/student_provider.dart';

class StudentFilterModal extends ConsumerStatefulWidget {
  const StudentFilterModal({super.key});

  @override
  ConsumerState<StudentFilterModal> createState() => _StudentFilterModalState();
}

class _StudentFilterModalState extends ConsumerState<StudentFilterModal> {
  int? _tempProgramId;
  int? _tempSessionId;
  String? _tempStatus;

  @override
  void initState() {
    super.initState();
    // Initialize temporary state from current provider values
    _tempProgramId = ref.read(studentProgramFilterProvider);
    _tempSessionId = ref.read(studentSessionFilterProvider);
    _tempStatus = ref.read(studentStatusFilterProvider);
  }

  @override
  Widget build(BuildContext context) {
    final programsAsync = ref.watch(programsProvider);
    final sessionsAsync = ref.watch(sessionsListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 480,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppColors.darkBorder,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                          'Filter Students',
                          style: AppTextStyles.h2,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Refine the student records list',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.darkTextMuted,
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
              height: 1,
              color: AppColors.darkBorder,
            ),
            // CONTENT
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // PROGRAM FILTER
                  Text('PROGRAM', style: AppTextStyles.label),
                  const SizedBox(height: 8),
                  programsAsync.when(
                    data: (list) => DropdownButtonFormField<int?>(
                      initialValue: _tempProgramId,
                      dropdownColor: AppColors.darkSurface,
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('All Programs'),
                        ),
                        ...list.map((p) => DropdownMenuItem<int?>(
                              value: p.id,
                              child: Text(p.name),
                            )),
                      ],
                      onChanged: (val) => setState(() => _tempProgramId = val),
                    ),
                    loading: () => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (err, _) => Text(
                      'Failed to load programs: $err',
                      style: TextStyle(color: AppColors.danger),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // SESSION FILTER
                  Text('ADMISSION SESSION / YEAR', style: AppTextStyles.label),
                  const SizedBox(height: 8),
                  sessionsAsync.when(
                    data: (list) => DropdownButtonFormField<int?>(
                      initialValue: _tempSessionId,
                      dropdownColor: AppColors.darkSurface,
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('All Sessions'),
                        ),
                        ...list.map((s) => DropdownMenuItem<int?>(
                              value: s.id,
                              child: Text(s.name),
                            )),
                      ],
                      onChanged: (val) => setState(() => _tempSessionId = val),
                    ),
                    loading: () => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (err, _) => Text(
                      'Failed to load sessions: $err',
                      style: TextStyle(color: AppColors.danger),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // STATUS FILTER
                  Text('STATUS', style: AppTextStyles.label),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    initialValue: _tempStatus,
                    dropdownColor: AppColors.darkSurface,
                    items: const [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All Status'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'active',
                        child: Text('Active'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'graduated',
                        child: Text('Graduated'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'struck_off',
                        child: Text('Struck Off'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'on_leave',
                        child: Text('On Leave'),
                      ),
                    ],
                    onChanged: (val) => setState(() => _tempStatus = val),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: AppColors.darkBorder,
            ),
            // FOOTER
            Padding(
              padding: const EdgeInsets.all(22),
              child: Row(
                children: [
                  OutlinedButton(
                    onPressed: () {
                      // Reset temp variables
                      setState(() {
                        _tempProgramId = null;
                        _tempSessionId = null;
                        _tempStatus = null;
                      });
                    },
                    child: const Text('Reset'),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      // Apply temp state to providers
                      ref.read(studentProgramFilterProvider.notifier).state = _tempProgramId;
                      ref.read(studentSessionFilterProvider.notifier).state = _tempSessionId;
                      ref.read(studentStatusFilterProvider.notifier).state = _tempStatus;
                      Navigator.pop(context);
                    },
                    child: const Text('Apply'),
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
