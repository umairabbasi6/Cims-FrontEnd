import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cims/core/constants/app_colors.dart';
import 'package:cims/core/constants/app_text_styles.dart';
import 'package:cims/core/widgets/app_scaffold.dart';
import 'package:cims/core/widgets/badge_chip.dart';
import 'package:cims/core/widgets/avatar.dart';
import 'package:cims/features/admin/students/providers/student_provider.dart';
import 'package:cims/features/admin/subjects/providers/subject_provider.dart';
import 'package:cims/features/admin/subjects/models/subject_api_model.dart';

class StudentSubjectsScreen extends ConsumerStatefulWidget {
  final void Function(String route) onNavigate;

  const StudentSubjectsScreen({
    super.key,
    required this.onNavigate,
  });

  @override
  ConsumerState<StudentSubjectsScreen> createState() =>
      _StudentSubjectsScreenState();
}

class _StudentSubjectsScreenState extends ConsumerState<StudentSubjectsScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    final studentAsync = ref.watch(currentStudentProvider);

    return AppScaffold(
      title: 'My Subjects',
      subtitle: 'ACADEMICS',
      currentRoute: '/subjects',
      role: 'student',
      onNavigate: widget.onNavigate,
      body: studentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (student) {
          if (student == null || student.program == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.menu_book_outlined, size: 48, color: AppColors.darkTextMuted),
                  const SizedBox(height: 12),
                  Text('No subjects found', style: AppTextStyles.h3),
                  const SizedBox(height: 4),
                  Text(
                    'Sign in with a student account linked to a program.',
                    style: const TextStyle(color: AppColors.darkTextMuted),
                  ),
                ],
              ),
            );
          }

          // Fetch subjects for student's program
          final subjectsAsync = ref.watch(subjectsListProvider);

          return subjectsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (allSubjects) {
              // Filter to student's program and current stage
              var subjects = allSubjects
                  .where((s) => s.program?.id == student.program!.id && s.stage <= student.currentStage)
                  .toList();

              // Apply search filter
              if (_search.isNotEmpty) {
                final q = _search.toLowerCase();
                subjects = subjects
                    .where((s) => s.name.toLowerCase().contains(q) || s.code.toLowerCase().contains(q))
                    .toList();
              }

              return _buildContent(subjects, student.program!.code, isMobile);
            },
          );
        },
      ),
    );
  }

  Widget _buildContent(
      List<SubjectApiModel> subjects, String programCode, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        onChanged: (v) => setState(() => _search = v),
                        decoration: const InputDecoration(
                          hintText: 'Search subjects...',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.download_rounded),
                        label: const Text('Export'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          width: 320,
                          child: TextField(
                            onChanged: (v) => setState(() => _search = v),
                            decoration: const InputDecoration(
                              hintText: 'Search subjects...',
                              prefixIcon: Icon(Icons.search_rounded),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.download_rounded),
                        label: const Text('Export'),
                      ),
                    ],
                  ),
          ),
          if (!isMobile)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              color: AppColors.darkSurfaceAlt,
              child: Row(
                children: [
                  Expanded(
                      flex: 28,
                      child: Text('SUBJECT',
                          style: AppTextStyles.labelSm)),
                  Expanded(
                      flex: 14,
                      child:
                          Text('CODE', style: AppTextStyles.labelSm)),
                  Expanded(
                      flex: 12,
                      child: Text('STAGE',
                          style: AppTextStyles.labelSm)),
                  Expanded(
                      flex: 12,
                      child: Text('CREDITS',
                          style: AppTextStyles.labelSm)),
                  Expanded(
                      flex: 12,
                      child:
                          Text('TYPE', style: AppTextStyles.labelSm)),
                ],
              ),
            ),
          if (subjects.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text('No subjects match your search.',
                  style: TextStyle(color: AppColors.darkTextMuted)),
            )
          else if (isMobile)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: subjects.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.darkBorder),
              itemBuilder: (context, index) {
                final subject = subjects[index];
                final initials = subject.name.length >= 2
                    ? subject.name
                        .split(' ')
                        .where((w) => w.isNotEmpty)
                        .take(2)
                        .map((w) => w[0].toUpperCase())
                        .join()
                    : subject.name[0].toUpperCase();
                return _buildSubjectMobileCard(subject, programCode, initials);
              },
            )
          else
            ...subjects.map(
              (subject) {
                final initials = subject.name.length >= 2
                    ? subject.name
                        .split(' ')
                        .where((w) => w.isNotEmpty)
                        .take(2)
                        .map((w) => w[0].toUpperCase())
                        .join()
                    : subject.name[0].toUpperCase();

                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppColors.darkBorder),
                    ),
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
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(subject.name,
                                      style: AppTextStyles.body
                                          .copyWith(
                                              fontWeight:
                                                  FontWeight.w700)),
                                  Text('${subject.program?.code ?? programCode} · Stage ${subject.stage}',
                                    style: const TextStyle(
                                        color:
                                            AppColors.darkTextMuted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 14,
                        child: Text(subject.code,
                            style: AppTextStyles.body
                                .copyWith(fontWeight: FontWeight.w700)),
                      ),
                      Expanded(
                        flex: 12,
                        child: Text('${subject.stage}'),
                      ),
                      Expanded(
                        flex: 12,
                        child: Text('${subject.creditHours.round()}'),
                      ),
                      Expanded(
                        flex: 12,
                        child: BadgeChip(
                          label: subject.hasPractical
                              ? 'Theory + Lab'
                              : 'Theory',
                          tone: subject.hasPractical
                              ? BadgeTone.accent
                              : BadgeTone.primary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSubjectMobileCard(SubjectApiModel subject, String programCode, String initials) {
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
                      subject.name,
                      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${subject.program?.code ?? programCode} · Stage ${subject.stage}',
                      style: const TextStyle(color: AppColors.darkTextMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetric('CODE', subject.code),
              _buildMetric('STAGE', '${subject.stage}'),
              _buildMetric('CREDITS', '${subject.creditHours.round()}'),
              _buildMetricWidget(
                'TYPE',
                BadgeChip(
                  label: subject.hasPractical ? 'Theory + Lab' : 'Theory',
                  tone: subject.hasPractical ? BadgeTone.accent : BadgeTone.primary,
                ),
              ),
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
}
