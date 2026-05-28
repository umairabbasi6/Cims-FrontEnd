import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cims/core/constants/app_colors.dart';
import 'package:cims/core/constants/app_text_styles.dart';
import 'package:cims/core/widgets/app_scaffold.dart';
import 'package:cims/core/widgets/badge_chip.dart';
import 'package:cims/features/student/providers/student_program_provider.dart';

class StudentProgramScreen extends ConsumerWidget {
  final void Function(String route) onNavigate;

  const StudentProgramScreen({
    super.key,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    final overviewAsync = ref.watch(studentProgramOverviewProvider);

    return AppScaffold(
      title: 'My Program',
      subtitle: 'ACADEMICS',
      currentRoute: '/programs',
      role: 'student',
      onNavigate: onNavigate,
      body: overviewAsync.when(
        loading: () => Padding(
          padding: EdgeInsets.symmetric(vertical: 80),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => _MessageCard(
          title: 'Could not load program',
          message: e.toString(),
        ),
        data: (overview) {
          if (overview == null) {
            return const _MessageCard(
              title: 'Program not available',
              message:
                  'Sign in with a student account linked to an enrollment record.',
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MetricsRow(overview: overview),
              SizedBox(height: 20),
              _ProgramStructureCard(overview: overview),
            ],
          );
        },
      ),
    );
  }
}

class _MetricsRow extends StatelessWidget {
  final StudentProgramOverview overview;

  const _MetricsRow({required this.overview});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    final cards = [
      _MetricCard(
        label: 'Program',
        value: overview.programCode,
        pill: overview.programTitle,
        icon: Icons.school_outlined,
        tone: BadgeTone.primary,
      ),
      _MetricCard(
        label: 'Semester',
        value: overview.semesterValue,
        pill: overview.sessionLabel,
        icon: Icons.calendar_month_outlined,
        tone: BadgeTone.accent,
      ),
      _MetricCard(
        label: 'Advisor',
        value: '—',
        pill: 'Faculty mentor',
        icon: Icons.person_outline_rounded,
        tone: BadgeTone.success,
      ),
      _MetricCard(
        label: 'Credits',
        value: overview.creditsValue,
        pill: overview.creditsPill,
        icon: Icons.menu_book_outlined,
        tone: BadgeTone.warning,
      ),
    ];

    if (isMobile) {
      return Column(
        children: cards
            .map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: c,
              ),
            )
            .toList(),
      );
    }

    return Row(
      children: cards
          .expand(
            (c) => [
              Expanded(child: c),
              if (c != cards.last) SizedBox(width: 16),
            ],
          )
          .toList(),
    );
  }
}

class _ProgramStructureCard extends StatelessWidget {
  final StudentProgramOverview overview;

  const _ProgramStructureCard({required this.overview});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final headerBg = isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Program Structure', style: AppTextStyles.h2),
                      SizedBox(height: 4),
                      Text(
                        overview.structureSubtitle,
                        style: AppTextStyles.bodySm.copyWith(
                          color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Brochure'),
                ),
              ],
            ),
          ),
          if (!isMobile) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              color: headerBg,
              child: Row(
                children: [
                  Expanded(flex: 12, child: Text('SEMESTER', style: AppTextStyles.labelSm)),
                  Expanded(flex: 36, child: Text('CORE SUBJECTS', style: AppTextStyles.labelSm)),
                  Expanded(flex: 14, child: Text('CREDIT HOURS', style: AppTextStyles.labelSm)),
                  Expanded(flex: 10, child: Text('GPA', style: AppTextStyles.labelSm)),
                  Expanded(flex: 14, child: Text('STATUS', style: AppTextStyles.labelSm)),
                ],
              ),
            ),
            ...overview.stages.map((row) => _StructureRow(row: row, border: border)),
          ] else
            ...overview.stages.map((row) => _StructureMobileCard(row: row, border: border)),
        ],
      ),
    );
  }
}

class _StructureRow extends StatelessWidget {
  final ProgramStageRow row;
  final Color border;

  const _StructureRow({required this.row, required this.border});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 12,
            child: Text(
              row.semesterLabel,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(flex: 36, child: Text(row.subjectsLabel)),
          Expanded(flex: 14, child: Text(row.creditHours)),
          Expanded(flex: 10, child: Text(row.gpa)),
          Expanded(flex: 14, child: _StatusChip(status: row.status)),
        ],
      ),
    );
  }
}

class _StructureMobileCard extends StatelessWidget {
  final ProgramStageRow row;
  final Color border;

  const _StructureMobileCard({required this.row, required this.border});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: border))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(row.semesterLabel, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800)),
              const Spacer(),
              _StatusChip(status: row.status),
            ],
          ),
          SizedBox(height: 8),
          Text(row.subjectsLabel),
          SizedBox(height: 8),
          Text(
            'Credits: ${row.creditHours} · GPA: ${row.gpa}',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.darkTextMuted),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final tone = switch (status) {
      'Passed' => BadgeTone.success,
      'Active' => BadgeTone.primary,
      _ => BadgeTone.muted,
    };

    return BadgeChip(label: status, tone: tone);
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String pill;
  final IconData icon;
  final BadgeTone tone;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.pill,
    required this.icon,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = switch (tone) {
      BadgeTone.primary => AppColors.primary,
      BadgeTone.accent => AppColors.accent,
      BadgeTone.success => AppColors.success,
      _ => AppColors.warning,
    };

    return Container(
      padding: const EdgeInsets.all(20),
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
                  style: AppTextStyles.bodySm.copyWith(
                    color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                  ),
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.h1.copyWith(fontSize: 24),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 16),
          BadgeChip(label: pill, tone: tone),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final String title;
  final String message;

  const _MessageCard({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      child: Column(
        children: [
          Icon(Icons.school_outlined, size: 48, color: AppColors.textMuted),
          SizedBox(height: 12),
          Text(title, style: AppTextStyles.h3),
          SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
