import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cims/core/constants/app_colors.dart';
import 'package:cims/core/constants/app_text_styles.dart';
import 'package:cims/core/utils/responsive.dart';
import 'package:cims/core/widgets/app_scaffold.dart';
import 'package:cims/core/widgets/badge_chip.dart';
import 'package:cims/features/student/providers/student_dashboard_provider.dart';

class StudentDashboardScreen extends ConsumerWidget {
  final void Function(String route) onNavigate;

  const StudentDashboardScreen({
    super.key,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    final padding = isMobile ? 16.0 : 24.0;

    final dashboardAsync = ref.watch(studentDashboardProvider);

    return AppScaffold(
      title: 'Dashboard',
      subtitle: 'STUDENT PORTAL',
      currentRoute: '/dashboard',
      role: 'student',
      onNavigate: onNavigate,
      body: dashboardAsync.when(
        loading: () => Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (data) {
          if (data == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.school_outlined,
                      size: 48,
                      color: AppColors.textMuted,
                    ),
                    SizedBox(height: 12),
                    Text('Dashboard not available', style: AppTextStyles.h3),
                    SizedBox(height: 8),
                    Text(
                      'Sign in with a student account linked to an enrollment record.',
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
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StudentHero(data: data),
                SizedBox(height: isMobile ? 16 : 20),
                _StudentStats(data: data),
                SizedBox(height: isMobile ? 16 : 20),
                if (isMobile)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _AcademicSnapshot(data: data),
                      SizedBox(height: isMobile ? 16 : 20),
                      _SubjectPerformance(data: data),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: _AcademicSnapshot(data: data),
                      ),
                      SizedBox(width: 20),
                      Expanded(
                        flex: 2,
                        child: _SubjectPerformance(data: data),
                      ),
                    ],
                  ),
                SizedBox(height: isMobile ? 16 : 20),
                _UpcomingClasses(data: data),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StudentHero extends StatelessWidget {
  final StudentDashboardData data;

  const _StudentHero({required this.data});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    final padding = isMobile ? 16.0 : 32.0;
    final titleFontSize = isMobile ? 18.0 : 26.0;

    final firstName = data.overview.student.firstName;
    final attendance = data.attendancePercentage.toStringAsFixed(0);
    final gpa = data.overview.stages.firstWhere(
      (s) => s.stage == data.overview.student.currentStage,
      orElse: () => data.overview.stages.last,
    ).gpa;

    final gpaText = gpa == '—' ? 'N/A' : gpa;
    final feeAmount = data.feeBalance > 0 ? 'PKR ${data.feeBalance}' : 'No fee';

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE6419A),
            Color(0xFF8B5CF6),
            Color(0xFFA78BFA),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'On track for good standing',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                SizedBox(height: isMobile ? 12 : 18),
                Text(
                  'Hi $firstName, keep it up!',
                  style: AppTextStyles.h1.copyWith(
                    color: Colors.white,
                    fontSize: titleFontSize,
                  ),
                ),
                SizedBox(height: isMobile ? 8 : 10),
                Text(
                  "You're at $attendance% attendance with $gpaText GPA. Pay your $feeAmount balance by ${data.feeDueDate} to avoid late fees.",
                  style: AppTextStyles.bodySm.copyWith(
                    color: Colors.white.withValues(alpha: 0.92),
                    height: 1.6,
                  ),
                ),
                SizedBox(height: isMobile ? 14 : 18),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      icon: const Icon(Icons.account_balance_wallet_outlined),
                      label: const Text('Pay fee'),
                    ),
                    SizedBox(height: isMobile ? 10 : 12),
                    OutlinedButton.icon(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                        minimumSize: const Size.fromHeight(48),
                      ),
                      icon: const Icon(Icons.calendar_month_outlined),
                      label: const Text('View timetable'),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'On track for good standing',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      SizedBox(height: 18),
                      Text(
                        'Hi $firstName, keep it up!',
                        style: AppTextStyles.h1.copyWith(
                          color: Colors.white,
                          fontSize: titleFontSize,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "You're at $attendance% attendance with $gpaText GPA. Pay your $feeAmount balance by ${data.feeDueDate} to avoid late fees.",
                        style: AppTextStyles.bodyLg.copyWith(
                          color: Colors.white.withValues(alpha: 0.92),
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 20),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                      ),
                      icon: const Icon(Icons.account_balance_wallet_outlined),
                      label: const Text('Pay fee'),
                    ),
                    SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                      ),
                      icon: const Icon(Icons.calendar_month_outlined),
                      label: const Text('View timetable'),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _StudentStats extends StatelessWidget {
  final StudentDashboardData data;
  const _StudentStats({required this.data});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    final gpa = data.overview.stages.firstWhere(
      (s) => s.stage == data.overview.student.currentStage,
      orElse: () => data.overview.stages.last,
    ).gpa;

    final feeText = data.feeBalance > 0 ? 'PKR ${data.feeBalance ~/ 1000}k' : 'PKR 0';

    final children = [
      _PortalStatCard(
        label: 'Attendance',
        value: '${data.attendancePercentage.toStringAsFixed(0)}%',
        pill: 'Above 75% required',
        tone: StatTone.success,
        icon: Icons.check_box_outlined,
      ),
      _PortalStatCard(
        label: 'Current GPA',
        value: gpa == '—' ? 'N/A' : gpa,
        pill: 'Good standing',
        tone: StatTone.primary,
        icon: Icons.description_outlined,
      ),
      _PortalStatCard(
        label: 'Fee Balance',
        value: feeText,
        pill: data.feeBalance > 0 ? 'Due ${data.feeDueDate}' : 'Cleared',
        tone: data.feeBalance > 0 ? StatTone.warning : StatTone.success,
        icon: Icons.account_balance_wallet_outlined,
      ),
      _PortalStatCard(
        label: 'Subjects',
        value: '${data.subjectPerformance.length}',
        pill: data.overview.sessionLabel,
        tone: StatTone.accent,
        icon: Icons.menu_book_outlined,
      ),
    ];

    if (isMobile) {
      return Column(
        children: children
            .expand((c) => [
                  c,
                  SizedBox(height: 12),
                ])
            .toList()
          ..removeLast(),
      );
    }

    return Row(
      children: children
          .expand((c) => [
                Expanded(child: c),
                SizedBox(width: 16),
              ])
          .toList()
        ..removeLast(),
    );
  }
}

enum StatTone { success, primary, warning, accent }

class _PortalStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String pill;
  final StatTone tone;
  final IconData icon;

  const _PortalStatCard({
    required this.label,
    required this.value,
    required this.pill,
    required this.tone,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    final (bg, fg, soft) = switch (tone) {
      StatTone.success => (AppColors.success, AppColors.success, AppColors.successSoft),
      StatTone.primary => (AppColors.primary, AppColors.primary, AppColors.primarySoft),
      StatTone.warning => (AppColors.warning, AppColors.warning, AppColors.warningSoft),
      _ => (AppColors.accent, AppColors.accent, AppColors.accentSoft),
    };

    return Container(
      padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
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
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.darkTextMuted,
                    fontSize: isMobile ? 11 : 12,
                  ),
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: soft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: fg, size: isMobile ? 16 : 20),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 6 : 8),
          Text(
            value,
            style: AppTextStyles.h1.copyWith(
              fontSize: isMobile ? 20 : 24,
            ),
          ),
          SizedBox(height: isMobile ? 12 : 16),
          BadgeChip(label: pill, tone: _mapTone(tone)),
        ],
      ),
    );
  }

  BadgeTone _mapTone(StatTone tone) => switch (tone) {
        StatTone.success => BadgeTone.success,
        StatTone.primary => BadgeTone.primary,
        StatTone.warning => BadgeTone.warning,
        _ => BadgeTone.accent,
      };
}

class _AcademicSnapshot extends StatelessWidget {
  final StudentDashboardData data;
  const _AcademicSnapshot({required this.data});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    final attProgress = data.totalSessions > 0 ? data.totalAttended / data.totalSessions : 0.0;
    final feeProgress = data.feeTotal > 0 ? data.feePaid / data.feeTotal : 1.0;

    // Attempt to extract credits
    final creditsValue = data.overview.creditsValue; // "92/160" or "—"
    double creditsProgress = 0.0;
    if (creditsValue.contains('/')) {
      final parts = creditsValue.split('/');
      final earned = double.tryParse(parts[0]) ?? 0;
      final total = double.tryParse(parts[1]) ?? 1;
      creditsProgress = earned / total;
    }

    return Container(
      padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Academic Snapshot', style: AppTextStyles.h2.copyWith(fontSize: isMobile ? 16 : 18)),
          SizedBox(height: 4),
          Text('${data.overview.programCode} · ${data.overview.semesterValue}', style: TextStyle(color: AppColors.darkTextMuted, fontSize: isMobile ? 12 : 13)),
          SizedBox(height: isMobile ? 16 : 24),
          _ProgressLine(
            label: 'Attendance',
            value: '${data.totalAttended} of ${data.totalSessions} sessions',
            progress: attProgress,
            color: AppColors.accent,
          ),
          SizedBox(height: isMobile ? 12 : 16),
          _ProgressLine(
            label: 'Fee Clearance',
            value: 'PKR ${data.feePaid ~/ 1000}k of ${data.feeTotal ~/ 1000}k paid',
            progress: feeProgress,
            color: AppColors.warning,
          ),
          SizedBox(height: isMobile ? 12 : 16),
          _ProgressLine(
            label: 'Result Status',
            value: '${data.subjectPerformance.length} subjects enrolled',
            progress: 1.0,
            color: AppColors.primary,
          ),
          SizedBox(height: isMobile ? 12 : 16),
          _ProgressLine(
            label: 'Credits Earned',
            value: '$creditsValue toward ${data.overview.programCode}',
            progress: creditsProgress,
            color: AppColors.success,
          ),
        ],
      ),
    );
  }
}

class _ProgressLine extends StatelessWidget {
  final String label;
  final String value;
  final double progress;
  final Color color;

  const _ProgressLine({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: isMobile ? 12 : 13,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: AppColors.darkTextMuted,
                fontSize: isMobile ? 11 : 12,
              ),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 8 : 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 6,
            value: progress,
            backgroundColor: AppColors.darkSurfaceAlt,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _SubjectPerformance extends StatelessWidget {
  final StudentDashboardData data;
  const _SubjectPerformance({required this.data});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    final items = data.subjectPerformance;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Subject Performance', style: AppTextStyles.h2.copyWith(fontSize: isMobile ? 16 : 18)),
          SizedBox(height: 4),
          Text('This semester', style: TextStyle(color: AppColors.darkTextMuted, fontSize: isMobile ? 12 : 13)),
          SizedBox(height: isMobile ? 16 : 20),
          if (items.isEmpty)
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No subjects recorded for this session.', style: TextStyle(color: AppColors.textMuted)),
            ),
          ...items.map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: isMobile ? 12 : 18),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.menu_book_outlined, color: AppColors.primary, size: 16),
                  ),
                  SizedBox(width: isMobile ? 10 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.subjectName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: isMobile ? 13 : 14,
                          ),
                        ),
                        Text(
                          item.attendance,
                          style: TextStyle(
                            color: AppColors.darkTextMuted,
                            fontSize: isMobile ? 11 : 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  BadgeChip(label: item.grade, tone: BadgeTone.success),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingClasses extends StatelessWidget {
  final StudentDashboardData data;
  const _UpcomingClasses({required this.data});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    final items = data.upcomingClasses;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(isMobile ? 14.0 : 20.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upcoming Classes',
                        style: AppTextStyles.h2.copyWith(
                          fontSize: isMobile ? 16 : 18,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Next ${items.length} sessions',
                        style: TextStyle(
                          color: AppColors.darkTextMuted,
                          fontSize: isMobile ? 12 : 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'View timetable',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: isMobile ? 12 : 13,
                  ),
                ),
              ],
            ),
          ),
          if (items.isEmpty)
            Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('No classes scheduled.', style: TextStyle(color: AppColors.textMuted)),
            ),
          if (items.isNotEmpty && isMobile)
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: items.length,
              itemBuilder: (ctx, i) {
                final item = items[i];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppColors.darkBorder),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              gradient: AppColors.gradientPrimary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              item.code,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.subject,
                                  style: AppTextStyles.body.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  item.courseCode,
                                  style: const TextStyle(
                                    color: AppColors.darkTextMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.teacher,
                              style: const TextStyle(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(item.day, style: const TextStyle(fontSize: 12)),
                          Text(item.time, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(item.room, style: const TextStyle(fontSize: 12)),
                          BadgeChip(
                            label: item.type,
                            tone: item.type.toLowerCase().contains('lab') ? BadgeTone.success : BadgeTone.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            )
          else if (items.isNotEmpty && !isMobile)
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  color: AppColors.darkSurfaceAlt,
                  child: Row(
                    children: [
                      Expanded(flex: 28, child: Text('SUBJECT', style: AppTextStyles.labelSm.copyWith(fontSize: 11))),
                      Expanded(flex: 18, child: Text('TEACHER', style: AppTextStyles.labelSm.copyWith(fontSize: 11))),
                      Expanded(flex: 14, child: Text('DAY', style: AppTextStyles.labelSm.copyWith(fontSize: 11))),
                      Expanded(flex: 14, child: Text('TIME', style: AppTextStyles.labelSm.copyWith(fontSize: 11))),
                      Expanded(flex: 14, child: Text('ROOM', style: AppTextStyles.labelSm.copyWith(fontSize: 11))),
                      Expanded(flex: 12, child: Text('TYPE', style: AppTextStyles.labelSm.copyWith(fontSize: 11))),
                    ],
                  ),
                ),
                ...items.map(
                  (item) => Container(
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
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  gradient: AppColors.gradientPrimary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  item.code,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.subject, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
                                    Text(item.courseCode, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.darkTextMuted)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(flex: 18, child: Text(item.teacher, maxLines: 1, overflow: TextOverflow.ellipsis)),
                        Expanded(flex: 14, child: Text(item.day, maxLines: 1, overflow: TextOverflow.ellipsis)),
                        Expanded(flex: 14, child: Text(item.time, maxLines: 1, overflow: TextOverflow.ellipsis)),
                        Expanded(flex: 14, child: Text(item.room, maxLines: 1, overflow: TextOverflow.ellipsis)),
                        Expanded(
                          flex: 12,
                          child: BadgeChip(
                            label: item.type,
                            tone: item.type.toLowerCase().contains('lab') ? BadgeTone.success : BadgeTone.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}