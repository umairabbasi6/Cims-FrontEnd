import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cims/core/constants/app_colors.dart';
import 'package:cims/core/constants/app_text_styles.dart';
import 'package:cims/core/widgets/app_scaffold.dart';
import 'package:cims/core/widgets/badge_chip.dart';
import 'package:cims/core/widgets/avatar.dart';
import 'package:cims/features/admin/students/providers/student_provider.dart';
import 'package:cims/features/admin/sessions/providers/session_provider.dart';
import 'package:cims/features/student/providers/student_results_provider.dart';
import 'package:cims/features/student/providers/student_program_provider.dart';

class StudentResultsScreen extends ConsumerWidget {
  final void Function(String route) onNavigate;

  const StudentResultsScreen({
    super.key,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final studentAsync = ref.watch(currentStudentProvider);
    final sessionAsync = ref.watch(currentAcademicSessionProvider);

    return AppScaffold(
      title: 'My Results',
      subtitle: 'RECORDS',
      currentRoute: '/results',
      role: 'student',
      onNavigate: onNavigate,
      body: studentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading profile: $err')),
        data: (student) {
          if (student == null) {
            return const Center(child: Text('Student profile not found'));
          }

          return sessionAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error loading session: $err')),
            data: (session) {
              final activeSessionId = ref.watch(selectedResultsSessionProvider) ?? session?.id;

              if (activeSessionId == null) {
                return const Center(child: Text('No active academic session found'));
              }

              final args = StudentResultsArgs(studentId: student.id, sessionId: activeSessionId);
              final gradeCardAsync = ref.watch(studentGradeCardProvider(args));
              final allResultsAsync = ref.watch(studentAllResultsProvider(student.id));
              final overviewAsync = ref.watch(studentProgramOverviewProvider);

              // 1. Calculate CGPA dynamically
              double cgpa = 0.0;
              final allResults = allResultsAsync.value ?? [];
              if (allResults.isNotEmpty) {
                double gpaSum = 0.0;
                int count = 0;
                for (final r in allResults) {
                  final pts = r['gpa_points'] as num?;
                  if (pts != null) {
                    gpaSum += pts.toDouble();
                    count++;
                  }
                }
                cgpa = count > 0 ? gpaSum / count : 0.0;
              }

              // 2. Fetch credits from overview
              final creditsValue = overviewAsync.value?.creditsValue ?? '—';
              final creditsPill = overviewAsync.value?.creditsPill ?? 'In progress';

              return ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  scrollbars: false,
                ),
                child: Scrollbar(
                  thumbVisibility: true,
                  thickness: isMobile ? 6 : 8,
                  radius: const Radius.circular(4),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 12.0 : 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Render Metrics
                          gradeCardAsync.when(
                            data: (card) => _buildMetrics(
                              isMobile: isMobile,
                              sessionGpa: (card['cgpa'] as num?)?.toDouble() ?? 0.0,
                              cumulativeGpa: cgpa,
                              creditsValue: creditsValue,
                              creditsPill: creditsPill,
                              overallResult: card['overall_result']?.toString() ?? 'Pass',
                            ),
                            loading: () => _buildMetrics(
                              isMobile: isMobile,
                              sessionGpa: 0.0,
                              cumulativeGpa: cgpa,
                              creditsValue: creditsValue,
                              creditsPill: creditsPill,
                              overallResult: '—',
                            ),
                            error: (_, __) => _buildMetrics(
                              isMobile: isMobile,
                              sessionGpa: 0.0,
                              cumulativeGpa: cgpa,
                              creditsValue: creditsValue,
                              creditsPill: creditsPill,
                              overallResult: '—',
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurface : AppColors.surface,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                            ),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: isMobile
                                      ? Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            const _SessionDropdown(),
                                            const SizedBox(height: 12),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: TextButton.icon(
                                                    onPressed: null,
                                                    icon: const Icon(Icons.filter_alt_outlined),
                                                    label: const Text('Filters'),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: OutlinedButton.icon(
                                                    onPressed: null,
                                                    icon: const Icon(Icons.download_rounded),
                                                    label: const Text('Export'),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        )
                                      : Row(
                                          children: [
                                            const SizedBox(width: 160, child: _SessionDropdown()),
                                            const SizedBox(width: 12),
                                            TextButton.icon(
                                              onPressed: null,
                                              icon: const Icon(Icons.filter_alt_outlined),
                                              label: const Text('Filters'),
                                            ),
                                            const Spacer(),
                                            OutlinedButton.icon(
                                              onPressed: null,
                                              icon: const Icon(Icons.download_rounded),
                                              label: const Text('Export'),
                                            ),
                                          ],
                                        ),
                                ),
                                gradeCardAsync.when(
                                  loading: () => const Padding(
                                    padding: EdgeInsets.all(32),
                                    child: CircularProgressIndicator(),
                                  ),
                                  error: (err, _) {
                                    final errStr = err.toString();
                                    if (errStr.contains('404') || errStr.contains('koi result nahi mila')) {
                                      return Padding(
                                        padding: const EdgeInsets.all(32),
                                        child: Text(
                                          'No exam results uploaded yet for this session.',
                                          style: TextStyle(color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
                                        ),
                                      );
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.all(32),
                                      child: Text(
                                        'Error loading results: $err',
                                        style: TextStyle(color: AppColors.danger),
                                      ),
                                    );
                                  },
                                  data: (card) {
                                    final subjects = card['subjects'] as List<dynamic>? ?? [];
                                    if (subjects.isEmpty) {
                                      return Padding(
                                        padding: const EdgeInsets.all(32),
                                        child: Text(
                                          'No subjects found in this grade card.',
                                          style: TextStyle(color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
                                        ),
                                      );
                                    }

                                    if (isMobile) {
                                      return ListView.separated(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: subjects.length,
                                        separatorBuilder: (_, __) => Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.border),
                                        itemBuilder: (context, index) {
                                          return _buildResultMobileCard(subjects[index]);
                                        },
                                      );
                                    }

                                    return Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                          decoration: BoxDecoration(
                                            color: isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt,
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(flex: 28, child: Text('SUBJECT', style: AppTextStyles.labelSm.copyWith(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary))),
                                              Expanded(flex: 13, child: Text('THEORY', style: AppTextStyles.labelSm.copyWith(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary))),
                                              Expanded(flex: 13, child: Text('PRACTICAL', style: AppTextStyles.labelSm.copyWith(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary))),
                                              Expanded(flex: 13, child: Text('TOTAL', style: AppTextStyles.labelSm.copyWith(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary))),
                                              Expanded(flex: 12, child: Text('GRADE', style: AppTextStyles.labelSm.copyWith(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary))),
                                              Expanded(flex: 10, child: Text('GPA', style: AppTextStyles.labelSm.copyWith(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary))),
                                            ],
                                          ),
                                        ),
                                        ...subjects.map((subj) {
                                          final name = subj['subject_name']?.toString() ?? 'Subject';
                                          final code = subj['subject_code']?.toString() ?? '—';
                                          final theory = '${subj['theory_marks'] ?? 0}/${subj['theory_total'] ?? 100}';
                                          
                                          final hasPrac = subj['practical_total'] != null && subj['practical_total'] > 0;
                                          final practical = hasPrac 
                                              ? '${subj['practical_marks'] ?? 0}/${subj['practical_total']}'
                                              : '—';
                                              
                                          final total = '${subj['total_marks'] ?? 0}/${subj['grand_total'] ?? 100}';
                                          final grade = subj['grade_letter']?.toString() ?? 'F';
                                          final gpa = (subj['gpa_points'] ?? 0.0).toStringAsFixed(2);
                                          
                                          final initials = name.length >= 2
                                              ? name.split(' ').where((w) => w.isNotEmpty).take(2).map((w) => w[0].toUpperCase()).join()
                                              : name[0].toUpperCase();

                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                            decoration: BoxDecoration(
                                              border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border)),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  flex: 28,
                                                  child: Row(
                                                    children: [
                                                      Avatar(text: initials),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(name, style: AppTextStyles.body.copyWith(
                                                              fontWeight: FontWeight.w700,
                                                              color: isDark ? AppColors.darkText : AppColors.text,
                                                            )),
                                                            Text(code, style: TextStyle(color: isDark ? AppColors.darkTextMuted : AppColors.textMuted)),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Expanded(flex: 13, child: Text(theory)),
                                                Expanded(flex: 13, child: Text(practical)),
                                                Expanded(flex: 13, child: Text(total)),
                                                Expanded(
                                                  flex: 12,
                                                  child: BadgeChip(
                                                    label: grade,
                                                    tone: grade.contains('F') ? BadgeTone.danger : BadgeTone.success,
                                                  ),
                                                ),
                                                Expanded(flex: 10, child: Text(gpa)),
                                              ],
                                            ),
                                          );
                                        }),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMetrics({
    required bool isMobile,
    required double sessionGpa,
    required double cumulativeGpa,
    required String creditsValue,
    required String creditsPill,
    required String overallResult,
  }) {
    final metrics = [
      _ResultMetric(
        label: 'Semester GPA',
        value: sessionGpa > 0 ? sessionGpa.toStringAsFixed(2) : '—',
        pill: overallResult,
        icon: Icons.description_outlined,
        tone: sessionGpa > 0 ? BadgeTone.primary : BadgeTone.warning,
      ),
      _ResultMetric(
        label: 'Cumulative GPA',
        value: cumulativeGpa > 0 ? cumulativeGpa.toStringAsFixed(2) : '—',
        pill: 'Overall standing',
        icon: Icons.track_changes_outlined,
        tone: BadgeTone.success,
      ),
      _ResultMetric(
        label: 'Credits Earned',
        value: creditsValue,
        pill: creditsPill,
        icon: Icons.menu_book_outlined,
        tone: BadgeTone.accent,
      ),
      _ResultMetric(
        label: 'Academic Standing',
        value: overallResult.toUpperCase(),
        pill: 'Term status',
        icon: Icons.auto_awesome_outlined,
        tone: overallResult.toLowerCase() == 'fail' ? BadgeTone.danger : BadgeTone.purple,
      ),
    ];

    if (isMobile) {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.85,
        children: metrics,
      );
    }

    return Row(
      children: [
        for (int i = 0; i < metrics.length; i++) ...[
          Expanded(child: metrics[i]),
          if (i < metrics.length - 1) const SizedBox(width: 16),
        ]
      ],
    );
  }

  Widget _buildResultMobileCard(dynamic subj) {
    final name = subj['subject_name']?.toString() ?? 'Subject';
    final code = subj['subject_code']?.toString() ?? '—';
    final theory = '${subj['theory_marks'] ?? 0}/${subj['theory_total'] ?? 100}';
    
    final hasPrac = subj['practical_total'] != null && subj['practical_total'] > 0;
    final practical = hasPrac 
        ? '${subj['practical_marks'] ?? 0}/${subj['practical_total']}'
        : '—';
        
    final total = '${subj['total_marks'] ?? 0}/${subj['grand_total'] ?? 100}';
    final grade = subj['grade_letter']?.toString() ?? 'F';
    final gpa = (subj['gpa_points'] ?? 0.0).toStringAsFixed(2);
    
    final initials = name.length >= 2
        ? name.split(' ').where((w) => w.isNotEmpty).take(2).map((w) => w[0].toUpperCase()).join()
        : name[0].toUpperCase();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Avatar(text: initials),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      code,
                      style: const TextStyle(color: AppColors.darkTextMuted),
                    ),
                  ],
                ),
              ),
              BadgeChip(
                label: grade,
                tone: grade.contains('F') ? BadgeTone.danger : BadgeTone.success,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetric('THEORY', theory),
              _buildMetric('PRACTICAL', practical),
              _buildMetric('TOTAL', total),
              _buildMetric('GPA', gpa),
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
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _SessionDropdown extends ConsumerWidget {
  const _SessionDropdown();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsListAsync = ref.watch(sessionsListProvider);
    final currentSession = ref.watch(currentAcademicSessionProvider).value;
    final selectedSessionId = ref.watch(selectedResultsSessionProvider);

    return sessionsListAsync.when(
      data: (list) {
        final activeVal = selectedSessionId ?? currentSession?.id;
        final hasActive = list.any((s) => s.id == activeVal);
        final val = hasActive ? activeVal : (list.isNotEmpty ? list.first.id : null);

        return DropdownButtonFormField<int>(
          value: val,
          decoration: const InputDecoration(
            labelText: 'SESSION',
          ),
          dropdownColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : AppColors.surface,
          items: list
              .map(
                (s) => DropdownMenuItem<int>(
                  value: s.id,
                  child: Text(s.name),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) {
              ref.read(selectedResultsSessionProvider.notifier).state = v;
            }
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (err, _) => Text('Error: $err', style: const TextStyle(color: Colors.red)),
    );
  }
}

class _ResultMetric extends StatelessWidget {
  final String label;
  final String value;
  final String pill;
  final IconData icon;
  final BadgeTone tone;

  const _ResultMetric({
    required this.label,
    required this.value,
    required this.pill,
    required this.icon,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      BadgeTone.primary => AppColors.primary,
      BadgeTone.success => AppColors.success,
      BadgeTone.accent => AppColors.accent,
      BadgeTone.danger => AppColors.danger,
      _ => AppColors.purple,
    };

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySm.copyWith(
                    color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: AppTextStyles.h1.copyWith(
            fontSize: 20,
            color: isDark ? AppColors.darkText : AppColors.text,
          )),
          const SizedBox(height: 12),
          BadgeChip(label: pill, tone: tone),
        ],
      ),
    );
  }
}
