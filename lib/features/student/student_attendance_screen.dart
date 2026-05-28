import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cims/core/constants/app_colors.dart';
import 'package:cims/core/constants/app_text_styles.dart';
import 'package:cims/core/widgets/app_scaffold.dart';
import 'package:cims/core/widgets/badge_chip.dart';
import 'package:cims/core/widgets/avatar.dart';
import 'package:cims/features/student/providers/student_attendance_provider.dart';

class StudentAttendanceScreen extends ConsumerWidget {
  final void Function(String route) onNavigate;

  const StudentAttendanceScreen({
    super.key,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    final attendanceAsync = ref.watch(studentAttendanceProvider);

    return AppScaffold(
      title: 'My Attendance',
      subtitle: 'RECORDS',
      currentRoute: '/attendance',
      role: 'student',
      onNavigate: onNavigate,
      body: attendanceAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (data) {
          if (data == null || data.subjects.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 48,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(height: 12),
                    Text('No attendance records found', style: AppTextStyles.h3),
                    const SizedBox(height: 8),
                    Text(
                      'There are no attendance sessions logged for the current academic session.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 12.0 : 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMetrics(context, data, isMobile),
                  const SizedBox(height: 20),
                  Container(
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
                                    const _AttendanceDropdown(),
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
                                    const SizedBox(width: 120, child: _AttendanceDropdown()),
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
                        if (isMobile)
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: data.subjects.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.darkBorder),
                            itemBuilder: (context, index) {
                              return _buildAttendanceMobileCard(data.subjects[index]);
                            },
                          )
                        else ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            color: AppColors.darkSurfaceAlt,
                            child: Row(
                              children: [
                                Expanded(flex: 28, child: Text('SUBJECT', style: AppTextStyles.labelSm)),
                                Expanded(flex: 9, child: Text('HELD', style: AppTextStyles.labelSm)),
                                Expanded(flex: 9, child: Text('PRESENT', style: AppTextStyles.labelSm)),
                                Expanded(flex: 9, child: Text('ABSENT', style: AppTextStyles.labelSm)),
                                Expanded(flex: 9, child: Text('LATE', style: AppTextStyles.labelSm)),
                                Expanded(flex: 20, child: Text('ATTENDANCE', style: AppTextStyles.labelSm)),
                                Expanded(flex: 12, child: Text('STATUS', style: AppTextStyles.labelSm)),
                              ],
                            ),
                          ),
                          ...data.subjects.map(
                            (row) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              decoration: const BoxDecoration(
                                border: Border(top: BorderSide(color: AppColors.darkBorder)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 28,
                                    child: Row(
                                      children: [
                                        Avatar(text: row.initials),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                row.name,
                                                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                                              ),
                                              Text(row.code, style: const TextStyle(color: AppColors.darkTextMuted)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(flex: 9, child: Text('${row.held}')),
                                  Expanded(flex: 9, child: Text('${row.present}')),
                                  Expanded(flex: 9, child: Text('${row.absent}')),
                                  Expanded(flex: 9, child: Text('${row.late}')),
                                  Expanded(
                                    flex: 20,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(999),
                                            child: LinearProgressIndicator(
                                              minHeight: 6,
                                              value: row.percentage / 100,
                                              color: row.percentage < 75.0 ? AppColors.warning : AppColors.accent,
                                              backgroundColor: AppColors.darkSurfaceAlt,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text('${row.percentage.toStringAsFixed(0)}%'),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 12,
                                    child: BadgeChip(
                                      label: row.status,
                                      tone: row.status == 'Watch' ? BadgeTone.warning : BadgeTone.success,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetrics(BuildContext context, StudentAttendanceData data, bool isMobile) {
    final overallStr = '${data.overallPercentage.toStringAsFixed(0)}%';
    final overallPill = data.overallPercentage >= 75.0 ? 'Above required' : 'Below required';
    final overallTone = data.overallPercentage >= 75.0 ? BadgeTone.success : BadgeTone.warning;

    final metrics = [
      _StudentMetric(
        label: 'Overall',
        value: overallStr,
        pill: overallPill,
        icon: Icons.check_box_outlined,
        tone: overallTone,
      ),
      _StudentMetric(
        label: 'Sessions Held',
        value: '${data.sessionsHeld}',
        pill: 'This semester',
        icon: Icons.calendar_month_outlined,
        tone: BadgeTone.primary,
      ),
      _StudentMetric(
        label: 'Present',
        value: '${data.presentCount}',
        pill: '$overallStr rate',
        icon: Icons.check_circle_outline_rounded,
        tone: BadgeTone.success,
      ),
      _StudentMetric(
        label: 'Absences',
        value: '${data.absentCount}',
        pill: 'Missed sessions',
        icon: Icons.warning_amber_rounded,
        tone: data.overallPercentage >= 75.0 ? BadgeTone.primary : BadgeTone.warning,
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

  Widget _buildAttendanceMobileCard(StudentAttendanceSubjectRow row) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Avatar(text: row.initials),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.name,
                      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      row.code,
                      style: const TextStyle(color: AppColors.darkTextMuted),
                    ),
                  ],
                ),
              ),
              BadgeChip(
                label: row.status,
                tone: row.status == 'Watch' ? BadgeTone.warning : BadgeTone.success,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCompactMetric('HELD', '${row.held}'),
              _buildCompactMetric('PRESENT', '${row.present}'),
              _buildCompactMetric('ABSENT', '${row.absent}'),
              _buildCompactMetric('LATE', '${row.late}'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    value: row.percentage / 100,
                    color: row.percentage < 75.0 ? AppColors.warning : AppColors.accent,
                    backgroundColor: AppColors.darkSurfaceAlt,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${row.percentage.toStringAsFixed(0)}%',
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactMetric(String label, String value) {
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

class _AttendanceDropdown extends StatelessWidget {
  const _AttendanceDropdown();

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: 'All Status',
      decoration: const InputDecoration(),
      items: const [
        DropdownMenuItem(
          value: 'All Status',
          child: Text('All Status'),
        ),
      ],
      onChanged: (_) {},
    );
  }
}

class _StudentMetric extends StatelessWidget {
  final String label;
  final String value;
  final String pill;
  final IconData icon;
  final BadgeTone tone;

  const _StudentMetric({
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
      BadgeTone.warning => AppColors.warning,
      _ => AppColors.purple,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.darkBorder),
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
                    color: AppColors.darkTextMuted,
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
          Text(
            value,
            style: AppTextStyles.h1.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 12),
          BadgeChip(
            label: pill,
            tone: tone,
          ),
        ],
      ),
    );
  }
}