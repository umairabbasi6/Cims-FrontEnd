import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cims/features/teacher/results/providers/results_provider.dart';
import 'package:cims/features/teacher/results/providers/results_api_provider.dart';
import 'package:cims/features/admin/subjects/providers/subject_provider.dart';
import 'package:cims/features/admin/sessions/providers/session_provider.dart';
import 'package:cims/features/admin/enrollments/providers/enrollment_provider.dart';
import 'package:cims/features/admin/staff/providers/staff_provider.dart';
import 'package:cims/features/timetable/providers/timetable_provider.dart';
import 'package:cims/features/timetable/services/timetable_service.dart' as api;

import 'package:cims/core/constants/app_colors.dart';
import 'package:cims/core/constants/app_text_styles.dart';
import 'package:cims/core/widgets/app_scaffold.dart';
import 'package:cims/core/widgets/badge_chip.dart';
import 'package:cims/core/widgets/stat_card.dart';
import 'package:cims/core/session/app_session.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  final void Function(String route) onNavigate;

  const ResultsScreen({
    super.key,
    required this.onNavigate,
  });

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  String selectedSubject = '';
  String selectedSession = '';

  int? _selectedSubjectId;
  int? _selectedSessionId;

  List<ResultRecord> _mergeEnrollmentsAndResults(
    List<Map<String, dynamic>> enrollments,
    List<Map<String, dynamic>> results,
    bool hasPractical,
  ) {
    final List<ResultRecord> out = [];
    final colors = [
      AppColors.info,
      AppColors.primary,
      AppColors.purple,
      AppColors.warning,
      AppColors.accent,
    ];

    double parseDouble(Object? v) {
      if (v == null) {
        return 0.0;
      }
      if (v is double) {
        return v;
      }
      if (v is int) {
        return v.toDouble();
      }
      if (v is String) {
        return double.tryParse(v) ?? 0.0;
      }
      return 0.0;
    }

    for (var i = 0; i < enrollments.length; i++) {
      final enrollment = enrollments[i];
      final enrollmentId = enrollment['id'] as int;

      // Extract student details
      final student = (enrollment['student'] is Map)
          ? enrollment['student'] as Map<String, dynamic>
          : enrollment;
      final name = (student['full_name'] ?? student['name'] ?? student['student_name'] ?? 'Unknown Student') as String;
      final roll = (student['roll_no'] ?? student['registration_number'] ?? student['student_id_code'] ?? '-') as String;

      String initials = '';
      if (name.isNotEmpty) {
        final parts = name.trim().split(' ');
        initials = parts.map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase();
      }
      if (initials.isEmpty) initials = 'ST';

      final avatarColor = colors[i % colors.length];

      // Find matching result
      Map<String, dynamic>? matchingResult;
      for (final res in results) {
        if (res['enrollment_id'] == enrollmentId) {
          matchingResult = res;
          break;
        }
      }

      if (matchingResult != null) {
        final resultId = matchingResult['id'] as int;
        final tMarks = parseDouble(matchingResult['theory_marks']);
        final tTotal = parseDouble(matchingResult['theory_total'] ?? 100.0);
        final pMarks = matchingResult['practical_marks'] != null ? parseDouble(matchingResult['practical_marks']) : null;
        final pTotal = matchingResult['practical_total'] != null ? parseDouble(matchingResult['practical_total']) : null;
        final grade = (matchingResult['grade_letter'] ?? matchingResult['grade'] ?? '-') as String;
        final gpaVal = matchingResult['gpa_points'] ?? matchingResult['gpa'];
        final gpa = gpaVal != null ? parseDouble(gpaVal).toStringAsFixed(2) : '-';

        out.add(ResultRecord(
          enrollmentId: enrollmentId,
          resultId: resultId,
          initials: initials,
          name: name,
          rollNo: roll,
          theoryMarks: tMarks,
          theoryTotal: tTotal,
          practicalMarks: pMarks,
          practicalTotal: pTotal,
          grade: grade,
          gpa: gpa,
          status: 'Graded',
          avatarColor: avatarColor,
          hasPractical: hasPractical,
        ));
      } else {
        out.add(ResultRecord(
          enrollmentId: enrollmentId,
          resultId: null,
          initials: initials,
          name: name,
          rollNo: roll,
          theoryMarks: 0.0,
          theoryTotal: 100.0,
          practicalMarks: hasPractical ? 0.0 : null,
          practicalTotal: hasPractical ? 50.0 : null,
          grade: 'Pending',
          gpa: '-',
          status: 'Pending',
          avatarColor: avatarColor,
          hasPractical: hasPractical,
        ));
      }
    }
    return out;
  }

  void _showMarksDialog({
    required BuildContext context,
    required ResultRecord record,
    required bool isEdit,
  }) {
    final theoryController = TextEditingController(
      text: isEdit ? record.theoryMarks.toString() : '',
    );
    final theoryTotalController = TextEditingController(
      text: isEdit ? record.theoryTotal.toString() : '100',
    );
    final practicalController = TextEditingController(
      text: isEdit && record.practicalMarks != null ? record.practicalMarks.toString() : '',
    );
    final practicalTotalController = TextEditingController(
      text: isEdit && record.practicalTotal != null ? record.practicalTotal.toString() : '50',
    );

    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: !isLoading,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.darkSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.darkBorder),
              ),
              title: Row(
                children: [
                  Icon(
                    isEdit ? Icons.edit_note_rounded : Icons.add_chart_rounded,
                    color: AppColors.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isEdit ? 'Edit Marks' : 'Enter Marks',
                      style: AppTextStyles.h3,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.name,
                        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Roll No: ${record.rollNo}',
                        style: AppTextStyles.caption.copyWith(color: AppColors.darkTextMuted),
                      ),
                      const SizedBox(height: 16),
                      
                      // Theory Section
                      Text(
                        'THEORY EXAM',
                        style: AppTextStyles.labelSm.copyWith(color: AppColors.primary),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: theoryController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Obtained Marks',
                                hintText: '0.0',
                              ),
                              style: const TextStyle(color: Colors.white),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Required';
                                }
                                final numVal = double.tryParse(val);
                                if (numVal == null || numVal < 0) {
                                  return 'Invalid';
                                }
                                final totVal = double.tryParse(theoryTotalController.text) ?? 100.0;
                                if (numVal > totVal) {
                                  return 'Max $totVal';
                                }
                                return null;
                              },
                            ),
                          ),
                          if (!isEdit) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: theoryTotalController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Total Marks',
                                  hintText: '100',
                                ),
                                style: const TextStyle(color: Colors.white),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Required';
                                  }
                                  final numVal = double.tryParse(val);
                                  if (numVal == null || numVal <= 0) {
                                    return 'Must be > 0';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ],
                      ),

                      if (record.hasPractical) ...[
                        const SizedBox(height: 20),
                        // Practical Section
                        Text(
                          'PRACTICAL / LAB EXAM',
                          style: AppTextStyles.labelSm.copyWith(color: AppColors.success),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: practicalController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Obtained Marks',
                                  hintText: '0.0',
                                ),
                                style: const TextStyle(color: Colors.white),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Required';
                                  }
                                  final numVal = double.tryParse(val);
                                  if (numVal == null || numVal < 0) {
                                    return 'Invalid';
                                  }
                                  final totVal = double.tryParse(practicalTotalController.text) ?? 50.0;
                                  if (numVal > totVal) {
                                    return 'Max $totVal';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            if (!isEdit) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: practicalTotalController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(
                                    labelText: 'Total Marks',
                                    hintText: '50',
                                  ),
                                  style: const TextStyle(color: Colors.white),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    final numVal = double.tryParse(val);
                                    if (numVal == null || numVal <= 0) {
                                      return 'Must be > 0';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(ctx),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                  ),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (formKey.currentState?.validate() != true) return;
                          
                          setState(() {
                            isLoading = true;
                          });

                          try {
                            final repo = ref.read(resultsRepositoryProvider);
                            if (isEdit) {
                              final body = {
                                'theory_marks': double.parse(theoryController.text),
                                if (record.hasPractical)
                                  'practical_marks': double.parse(practicalController.text),
                              };
                              await repo.updateMarks(record.resultId!, body);
                            } else {
                              final body = {
                                'enrollment_id': record.enrollmentId,
                                'theory_marks': double.parse(theoryController.text),
                                'theory_total': double.parse(theoryTotalController.text),
                                if (record.hasPractical) ...{
                                  'practical_marks': double.parse(practicalController.text),
                                  'practical_total': double.parse(practicalTotalController.text),
                                }
                              };
                              await repo.saveMarks(body);
                            }

                            // Invalidate class results to reload list
                            ref.invalidate(classResultsProvider);
                            
                            if (context.mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isEdit
                                        ? 'Marks updated successfully'
                                        : 'Marks entered successfully',
                                  ),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          } catch (e) {
                            setState(() {
                              isLoading = false;
                            });
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to save marks: $e'),
                                  backgroundColor: AppColors.danger,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(isEdit ? 'Update' : 'Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    final isTeacher = AppSession.currentRole == 'teacher';

    final sessionAsync = ref.watch(currentAcademicSessionProvider);
    final activeSessionId = sessionAsync.value?.id;

    final sessionsAsync = ref.watch(sessionsListProvider);
    final subjectsAsync = ref.watch(subjectsListProvider);

    // Initialize default session selection when provider becomes available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedSessionId == null && sessionsAsync is AsyncData) {
        final sessions = sessionsAsync.value;
        if (sessions != null && sessions.isNotEmpty) {
          final cur = sessions.firstWhere((s) => s.isCurrent, orElse: () => sessions.first);
          setState(() {
            _selectedSessionId = cur.id;
            selectedSession = cur.name;
          });
        }
      }
    });

    // 1. Retrieve the list of subjects to display in the dropdown
    final List<({int id, String name})> dropDownSubjects = [];

    if (isTeacher) {
      final staffAsync = ref.watch(currentStaffProvider);
      final staff = staffAsync.value;

      final slotsAsync = activeSessionId != null && staff != null
          ? ref.watch(timetableSlotsListProvider((
              sessionId: activeSessionId,
              stage: null,
              staffId: staff.id,
            )))
          : const AsyncValue<List<api.TimetableSlot>>.data([]);

      final uniqueSubjects = <int, String>{};
      if (slotsAsync.value != null) {
        for (final slot in slotsAsync.value!) {
          uniqueSubjects[slot.subjectId] = slot.subjectName;
        }
      }
      dropDownSubjects.addAll(
        uniqueSubjects.entries.map((e) => (id: e.key, name: e.value)),
      );
    } else {
      if (subjectsAsync.value != null) {
        for (final sub in subjectsAsync.value!) {
          dropDownSubjects.add((id: sub.id, name: sub.name));
        }
      }
    }

    // 2. Initialize default subject selection when dropDownSubjects becomes available
    if (_selectedSubjectId == null && dropDownSubjects.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedSubjectId = dropDownSubjects.first.id;
            selectedSubject = dropDownSubjects.first.name;
          });
        }
      });
    }

    // If dropdown subjects updated and selected subject is no longer valid, correct it
    if (_selectedSubjectId != null && dropDownSubjects.isNotEmpty &&
        !dropDownSubjects.any((s) => s.id == _selectedSubjectId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedSubjectId = dropDownSubjects.first.id;
            selectedSubject = dropDownSubjects.first.name;
          });
        }
      });
    }

    // 3. Determine if the selected subject has a practical
    bool hasPractical = false;
    if (_selectedSubjectId != null && subjectsAsync.value != null) {
      final matched = subjectsAsync.value!.firstWhere(
        (s) => s.id == _selectedSubjectId,
        orElse: () => subjectsAsync.value!.first,
      );
      hasPractical = matched.hasPractical;
    }

    // 4. Load enrollments and results
    final enrollmentsAsync = _selectedSubjectId != null && _selectedSessionId != null
        ? ref.watch(subjectEnrollmentsProvider(SubjectEnrollmentsArgs(
            subjectId: _selectedSubjectId!,
            sessionId: _selectedSessionId!,
          )))
        : const AsyncValue<List<Map<String, dynamic>>>.data([]);

    final resultsAsync = _selectedSubjectId != null && _selectedSessionId != null
        ? ref.watch(classResultsProvider(ResultsQuery(
            subjectId: _selectedSubjectId!,
            sessionId: _selectedSessionId!,
          )))
        : const AsyncValue<List<Map<String, dynamic>>>.data([]);

    // 5. Combine and merge
    final List<ResultRecord> records = [];
    if (enrollmentsAsync.value != null && resultsAsync.value != null) {
      records.addAll(
        _mergeEnrollmentsAndResults(
          enrollmentsAsync.value!,
          resultsAsync.value!,
          hasPractical,
        ),
      );
    }

    return AppScaffold(
      title: 'Results',
      subtitle: 'Operations',
      currentRoute: '/results',
      role: AppSession.currentRole,
      onNavigate: widget.onNavigate,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 12.0 : 22.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(dropDownSubjects, isMobile),
              const SizedBox(height: 22),
              _buildStats(records, isMobile),
              const SizedBox(height: 22),
              _buildMarksTable(records, enrollmentsAsync, resultsAsync, isMobile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(List<({int id, String name})> dropDownSubjects, bool isMobile) {
    final sessionsAsync = ref.watch(sessionsListProvider);
    final subjectsAsync = ref.watch(subjectsListProvider);

    final dropdowns = [
      SizedBox(
        width: isMobile ? double.infinity : 220,
        child: subjectsAsync.when(
          loading: () => const SizedBox(height: 48, child: Center(child: CircularProgressIndicator())),
          error: (err, _) => Text('Failed to load subjects', style: AppTextStyles.bodySm),
          data: (_) {
            final items = dropDownSubjects
                .map((s) => DropdownMenuItem<int>(value: s.id, child: Text(s.name)))
                .toList();

            return DropdownButtonFormField<int>(
              value: _selectedSubjectId,
              decoration: const InputDecoration(labelText: 'SUBJECT'),
              dropdownColor: AppColors.darkSurface,
              items: items,
              onChanged: (v) {
                if (v == null) return;
                final sel = dropDownSubjects.firstWhere((s) => s.id == v);
                setState(() {
                  _selectedSubjectId = v;
                  selectedSubject = sel.name;
                });
              },
            );
          },
        ),
      ),
      if (isMobile) const SizedBox(height: 12) else const SizedBox(width: 12),
      SizedBox(
        width: isMobile ? double.infinity : 180,
        child: sessionsAsync.when(
          loading: () => const SizedBox(height: 48, child: Center(child: CircularProgressIndicator())),
          error: (err, _) => Text('Failed to load sessions', style: AppTextStyles.bodySm),
          data: (sessions) {
            final items = sessions
                .map((s) => DropdownMenuItem<int>(value: s.id, child: Text(s.name)))
                .toList();

            return DropdownButtonFormField<int>(
              value: _selectedSessionId,
              decoration: const InputDecoration(labelText: 'SESSION'),
              dropdownColor: AppColors.darkSurface,
              items: items,
              onChanged: (v) {
                if (v == null) return;
                final sel = sessions.firstWhere((s) => s.id == v);
                setState(() {
                  _selectedSessionId = v;
                  selectedSession = sel.name;
                });
              },
            );
          },
        ),
      ),
    ];

    final buttons = [
      OutlinedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.download_rounded),
        label: const Text('Export CSV'),
        style: isMobile ? OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)) : null,
      ),
      if (isMobile) const SizedBox(height: 10) else const SizedBox(width: 12),
      ElevatedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.send_rounded),
        label: const Text('Publish results'),
        style: isMobile ? ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)) : null,
      ),
    ];

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...dropdowns,
          const SizedBox(height: 16),
          ...buttons,
        ],
      );
    }

    return Row(
      children: [
        ...dropdowns,
        const Spacer(),
        ...buttons,
      ],
    );
  }

  Widget _buildStats(List<ResultRecord> records, bool isMobile) {
    final gradedRecords = records.where((r) => r.status == 'Graded').toList();
    
    double classAveragePct = 0.0;
    double topScorePct = 0.0;
    String topScoreName = 'N/A';
    int passCount = 0;
    int atRiskCount = 0;

    if (gradedRecords.isNotEmpty) {
      double totalPct = 0.0;
      for (final r in gradedRecords) {
        final totalObtained = r.theoryMarks + (r.practicalMarks ?? 0.0);
        final totalGrand = r.theoryTotal + (r.practicalTotal ?? 0.0);
        final pct = totalGrand > 0 ? (totalObtained / totalGrand) * 100 : 0.0;
        
        totalPct += pct;
        if (pct >= 50.0) {
          passCount++;
        } else {
          atRiskCount++;
        }

        if (pct > topScorePct) {
          topScorePct = pct;
          topScoreName = r.name;
        }
      }
      classAveragePct = totalPct / gradedRecords.length;
    }

    final passRate = gradedRecords.isNotEmpty
        ? (passCount / gradedRecords.length * 100).round()
        : 0;

    String avgGrade = 'N/A';
    if (gradedRecords.isNotEmpty) {
      if (classAveragePct >= 85) {
        avgGrade = 'A+';
      } else if (classAveragePct >= 80) {
        avgGrade = 'A';
      } else if (classAveragePct >= 75) {
        avgGrade = 'B+';
      } else if (classAveragePct >= 70) {
        avgGrade = 'B';
      } else if (classAveragePct >= 65) {
        avgGrade = 'C+';
      } else if (classAveragePct >= 60) {
        avgGrade = 'C';
      } else if (classAveragePct >= 50) {
        avgGrade = 'D';
      } else {
        avgGrade = 'F';
      }
    }

    final cards = [
      StatCard(
        label: 'Class Average',
        value: gradedRecords.isNotEmpty ? '${classAveragePct.toStringAsFixed(1)}%' : '0%',
        trend: gradedRecords.isNotEmpty ? '$avgGrade grade' : 'No grades',
        tone: StatTone.primary,
        icon: const Icon(Icons.track_changes_rounded),
      ),
      StatCard(
        label: 'Pass Rate',
        value: gradedRecords.isNotEmpty ? '$passRate%' : '0%',
        trend: gradedRecords.isNotEmpty ? '$passCount passed' : 'No grades',
        tone: StatTone.success,
        icon: const Icon(Icons.check_circle_outline_rounded),
      ),
      StatCard(
        label: 'Top Score',
        value: gradedRecords.isNotEmpty ? '${topScorePct.toStringAsFixed(0)}%' : '0%',
        trend: topScoreName,
        tone: StatTone.accent,
        icon: const Icon(Icons.auto_awesome_rounded),
      ),
      StatCard(
        label: 'At Risk',
        value: '$atRiskCount',
        trend: 'Below 50%',
        trendUp: false,
        tone: StatTone.warning,
        icon: const Icon(Icons.warning_amber_rounded),
      ),
    ];

    if (isMobile) {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: isMobile ? 0.85 : 1.3,
        children: cards,
      );
    }

    return Row(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          Expanded(child: cards[i]),
          if (i < cards.length - 1) const SizedBox(width: 16),
        ]
      ],
    );
  }

  Widget _buildMarksTable(
    List<ResultRecord> records,
    AsyncValue<List<Map<String, dynamic>>> enrollmentsAsync,
    AsyncValue<List<Map<String, dynamic>>> resultsAsync,
    bool isMobile,
  ) {
    final isLoading = enrollmentsAsync.isLoading || resultsAsync.isLoading;
    final hasError = enrollmentsAsync.hasError || resultsAsync.hasError;
    final errorMessage = enrollmentsAsync.error?.toString() ?? resultsAsync.error?.toString() ?? '';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Marks Entry', style: AppTextStyles.h3),
                const SizedBox(height: 4),
                Text(
                  'Tap entry icon to record marks • grade auto-calculates',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.darkTextMuted,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.darkBorder),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (hasError)
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Text(
                  'Failed to load results: $errorMessage',
                  style: const TextStyle(color: AppColors.danger),
                ),
              ),
            )
          else if (records.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Text(
                  'No students enrolled in this subject.',
                  style: AppTextStyles.body.copyWith(color: AppColors.darkTextMuted),
                ),
              ),
            )
          else if (isMobile)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: records.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.darkBorder),
              itemBuilder: (context, index) {
                return _buildStudentResultMobileCard(records[index]);
              },
            )
          else
            Column(
              children: [
                Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  color: AppColors.darkSurfaceAlt,
                  child: Row(
                    children: [
                      _header('STUDENT', 2.4),
                      _header('ROLL NO', 1.8),
                      _header('THEORY', 1.5),
                      _header('PRACTICAL', 1.5),
                      _header('GRADE', 1.2),
                      _header('GPA', 1.0),
                      _header('ACTIONS', 1.0),
                    ],
                  ),
                ),
                ...records.map(_resultRow),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStudentResultMobileCard(ResultRecord e) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: e.avatarColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  e.initials,
                  style: AppTextStyles.bodySm.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.name,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      e.rollNo,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.darkTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _showMarksDialog(
                  context: context,
                  record: e,
                  isEdit: e.status == 'Graded',
                ),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.darkBorder),
                  ),
                  child: Icon(
                    e.status == 'Graded' ? Icons.edit_outlined : Icons.add_chart_rounded,
                    size: 18,
                    color: e.status == 'Graded' ? AppColors.darkTextMuted : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetric('THEORY', e.status == 'Graded' ? '${e.theoryMarks}/${e.theoryTotal}' : '-'),
              _buildMetric('PRACTICAL', e.hasPractical ? (e.status == 'Graded' && e.practicalMarks != null ? '${e.practicalMarks}/${e.practicalTotal}' : '-') : 'N/A'),
              _buildMetricWidget(
                'GRADE',
                BadgeChip(label: e.grade, tone: _gradeTone(e.grade)),
              ),
              _buildMetric('GPA', e.gpa),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            fontSize: 10,
            color: AppColors.darkTextMuted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricWidget(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            fontSize: 10,
            color: AppColors.darkTextMuted,
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }

  Widget _resultRow(ResultRecord e) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.darkBorder),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 24,
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: e.avatarColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    e.initials,
                    style: AppTextStyles.bodySm.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.name,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        e.rollNo,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.darkTextMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 18,
            child: Text(
              e.rollNo,
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 15,
            child: Text(
              e.status == 'Graded' ? '${e.theoryMarks}/${e.theoryTotal}' : '-',
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 15,
            child: Text(
              e.hasPractical
                  ? (e.status == 'Graded' && e.practicalMarks != null
                      ? '${e.practicalMarks}/${e.practicalTotal}'
                      : '-')
                  : 'N/A',
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w700,
                color: e.hasPractical ? null : Colors.white.withValues(alpha: 0.3),
              ),
            ),
          ),
          Expanded(
            flex: 12,
            child: BadgeChip(
              label: e.grade,
              tone: _gradeTone(e.grade),
            ),
          ),
          Expanded(
            flex: 10,
            child: Text(
              e.gpa,
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 10,
            child: Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _showMarksDialog(
                  context: context,
                  record: e,
                  isEdit: e.status == 'Graded',
                ),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.darkBorder),
                  ),
                  child: Icon(
                    e.status == 'Graded' ? Icons.edit_outlined : Icons.add_chart_rounded,
                    size: 18,
                    color: e.status == 'Graded' ? AppColors.darkTextMuted : AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(String text, double flex) {
    return Expanded(
      flex: (flex * 10).toInt(),
      child: Text(
        text,
        style: AppTextStyles.labelSm.copyWith(
          fontSize: 12,
        ),
      ),
    );
  }

  BadgeTone _gradeTone(String grade) {
    switch (grade) {
      case 'A+':
      case 'A':
        return BadgeTone.success;
      case 'B+':
      case 'B':
        return BadgeTone.primary;
      case 'C+':
      case 'C':
        return BadgeTone.warning;
      case 'Pending':
        return BadgeTone.purple;
      default:
        return BadgeTone.danger;
    }
  }
}

class ResultRecord {
  final int enrollmentId;
  final int? resultId;
  final String initials;
  final String name;
  final String rollNo;
  final double theoryMarks;
  final double theoryTotal;
  final double? practicalMarks;
  final double? practicalTotal;
  final String grade;
  final String gpa;
  final String status;
  final Color avatarColor;
  final bool hasPractical;

  ResultRecord({
    required this.enrollmentId,
    this.resultId,
    required this.initials,
    required this.name,
    required this.rollNo,
    required this.theoryMarks,
    required this.theoryTotal,
    this.practicalMarks,
    this.practicalTotal,
    required this.grade,
    required this.gpa,
    required this.status,
    required this.avatarColor,
    required this.hasPractical,
  });
}