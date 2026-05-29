import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cims/core/constants/app_colors.dart';
import 'package:cims/core/constants/app_text_styles.dart';
import 'package:cims/core/widgets/app_scaffold.dart';
import 'package:cims/core/widgets/badge_chip.dart';
import 'package:cims/features/teacher/dashboard/providers/teacher_dashboard_provider.dart';
import 'package:cims/core/utils/responsive.dart';
import 'package:intl/intl.dart';

class TeacherDashboard extends ConsumerWidget {
  final void Function(String route) onNavigate;

  const TeacherDashboard({
    super.key,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(teacherDashboardProvider);
    final isMobile = Responsive.isMobile(context);
    final padding = isMobile ? 16.0 : 24.0;

    return AppScaffold(
      title: 'Dashboard',
      subtitle: 'TEACHER PORTAL',
      currentRoute: '/dashboard',
      role: 'teacher',
      onNavigate: onNavigate,
      body: dashboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Error: $e', textAlign: TextAlign.center),
          ),
        ),
        data: (data) {
          if (data == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Dashboard not available. Ensure you are logged in with a teacher account.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. WELCOME HERO BANNER
                _TeacherHero(data: data, onNavigate: onNavigate),
                const SizedBox(height: 20),

                // 2. STATS GRID
                _TeacherStats(data: data),
                const SizedBox(height: 20),

                // 3. MIDDLE ROW (SCHEDULE & CHART)
                if (isMobile)
                  Column(
                    children: [
                      _TodaySchedule(data: data),
                      const SizedBox(height: 20),
                      _AttendanceTrendChart(),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _TodaySchedule(data: data)),
                      const SizedBox(width: 20),
                      Expanded(flex: 2, child: _AttendanceTrendChart()),
                    ],
                  ),
                const SizedBox(height: 20),

                // 4. BOTTOM CLASSES TABLE
                _AssignedClassesTable(data: data, onNavigate: onNavigate),
              ],
            ),
          );
        },
      ),
    );
  }
}

// =====================================================
// WELCOME HERO BANNER
// =====================================================
class _TeacherHero extends StatelessWidget {
  final TeacherDashboardData data;
  final void Function(String route) onNavigate;

  const _TeacherHero({required this.data, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bannerGrad = isDark
        ? const LinearGradient(
            colors: [Color(0xFF2E3B8E), Color(0xFF4B3280), Color(0xFF6B227B)],
          )
        : const LinearGradient(
            colors: [Color(0xFF3B82F6), Color(0xFF6366F1), Color(0xFF8B5CF6)],
          );

    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: BoxDecoration(
        gradient: bannerGrad,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.25),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderBadge(data.todayClasses),
                const SizedBox(height: 14),
                Text(
                  'Welcome, ${data.staffName}',
                  style: AppTextStyles.h1.copyWith(color: Colors.white, fontSize: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  data.totalSubjects > 0
                      ? 'Your next class is ${data.nextClassSubject} at ${data.nextClassTime} in ${data.nextClassRoom}. ${data.attendancePendingCount} attendance session is pending submission.'
                      : 'You do not have any subjects assigned in the current session.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13.5,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => onNavigate('/attendance'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF6366F1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Mark attendance'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => onNavigate('/results'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Marks entry'),
                      ),
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
                      _buildHeaderBadge(data.todayClasses),
                      const SizedBox(height: 14),
                      Text(
                        'Welcome, ${data.staffName}',
                        style: AppTextStyles.h1.copyWith(color: Colors.white, fontSize: 28),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data.totalSubjects > 0
                            ? 'Your next class is ${data.nextClassSubject} at ${data.nextClassTime} in ${data.nextClassRoom}. ${data.attendancePendingCount} attendance session is pending submission.'
                            : 'You do not have any subjects assigned in the current session.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => onNavigate('/attendance'),
                      icon: const Icon(Icons.check_circle_rounded, size: 16),
                      label: const Text('Mark attendance'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF6366F1),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => onNavigate('/results'),
                      icon: const Icon(Icons.edit_note_rounded, size: 18),
                      label: const Text('Marks entry'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildHeaderBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.electric_bolt_rounded, color: Colors.amber, size: 14),
          const SizedBox(width: 4),
          Text(
            '$count classes today',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// STATS CARDS GRID
// =====================================================
class _TeacherStats extends StatelessWidget {
  final TeacherDashboardData data;

  const _TeacherStats({required this.data});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    final isTablet = width >= 600 && width < 1100;

    // Calculate total students assigned (dynamic mock matching subjects count)
    int totalStudentsCount = 0;
    for (var c in data.assignedClassesList) {
      totalStudentsCount += (c['students'] as num).toInt();
    }
    if (totalStudentsCount == 0) totalStudentsCount = 115;

    final stats = [
      (
        'Assigned Classes',
        '${data.totalSubjects}',
        '$totalStudentsCount students',
        Icons.business_outlined,
        const Color(0xFF6366F1)
      ),
      (
        'Today\'s Sessions',
        '${data.todayClasses}',
        data.todayClasses > 0 ? 'Next at ${data.nextClassTime}' : 'No sessions today',
        Icons.calendar_today_rounded,
        const Color(0xFF14B8A6)
      ),
      (
        'Attendance Pending',
        '${data.attendancePendingCount}',
        data.assignedClassesList.isNotEmpty ? data.assignedClassesList[0]['className'].toString() : 'No classes',
        Icons.check_box_outlined,
        const Color(0xFFF59E0B)
      ),
      (
        'Marks Pending',
        '${data.marksPendingCount}',
        'Mid-term entries',
        Icons.assignment_outlined,
        const Color(0xFF10B981)
      ),
    ];

    if (isMobile) {
      return Column(
        children: stats.map((s) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _StatCard(title: s.$1, value: s.$2, subtitle: s.$3, icon: s.$4, color: s.$5),
        )).toList(),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stats.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet ? 2 : 4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: isTablet ? 2.0 : 1.35,
      ),
      itemBuilder: (context, index) {
        final s = stats[index];
        return _StatCard(title: s.$1, value: s.$2, subtitle: s.$3, icon: s.$4, color: s.$5);
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const Spacer(),
          Text(value, style: AppTextStyles.h1.copyWith(fontSize: 28)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              subtitle,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// TODAY'S SCHEDULE
// =====================================================
class _TodaySchedule extends StatelessWidget {
  final TeacherDashboardData data;

  const _TodaySchedule({required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final todayStr = DateFormat('MMMM dd, yyyy · EEEE').format(DateTime.now());

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Today\'s Schedule', style: AppTextStyles.h3),
                  const SizedBox(height: 2),
                  Text(
                    todayStr,
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.print_rounded, size: 14),
                label: const Text('Print'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (data.todaySchedule.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No classes scheduled for today.',
                  style: TextStyle(color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
                ),
              ),
            )
          else
            ...List.generate(data.todaySchedule.length, (index) {
              final s = data.todaySchedule[index];
              final isFirst = index == 0;

              // Mock statuses to match layout
              String statusLabel = 'Open';
              BadgeTone tone = BadgeTone.warning;
              if (index == 0) {
                statusLabel = 'Done';
                tone = BadgeTone.success;
              } else if (index == 1) {
                statusLabel = 'Next';
                tone = BadgeTone.primary;
              } else if (s['type'] == 'LAB') {
                statusLabel = 'Lab';
                tone = BadgeTone.purple;
              }

              // Dynamic mock room and class
              final roomName = s['room'] ?? 'Room 201';
              final classLabel = data.assignedClassesList.isNotEmpty
                  ? data.assignedClassesList[index % data.assignedClassesList.length]['className'].toString()
                  : 'DPT 6th Sem';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: isFirst
                      ? Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5)
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (isFirst ? AppColors.primary : Colors.grey).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFirst ? Icons.check_circle_outline_rounded : Icons.schedule_rounded,
                        color: isFirst ? AppColors.primary : Colors.grey,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s['subject'] ?? 'Unknown',
                            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${s['time']} · $roomName · $classLabel',
                            style: TextStyle(
                              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    BadgeChip(label: statusLabel, tone: tone),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

// =====================================================
// CLASS ATTENDANCE TREND CHART
// =====================================================
class _AttendanceTrendChart extends StatelessWidget {
  const _AttendanceTrendChart();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          Text('Class Attendance Trend', style: AppTextStyles.h3),
          const SizedBox(height: 2),
          Text(
            'This week',
            style: TextStyle(
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 160,
            width: double.infinity,
            child: CustomPaint(
              painter: AttendanceChartPainter(
                data: [82.0, 85.0, 80.0, 88.0, 84.0, 89.0, 87.0],
                labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Mon', style: TextStyle(fontSize: 11, color: AppColors.darkTextMuted)),
              Text('Tue', style: TextStyle(fontSize: 11, color: AppColors.darkTextMuted)),
              Text('Wed', style: TextStyle(fontSize: 11, color: AppColors.darkTextMuted)),
              Text('Thu', style: TextStyle(fontSize: 11, color: AppColors.darkTextMuted)),
              Text('Fri', style: TextStyle(fontSize: 11, color: AppColors.darkTextMuted)),
              Text('Sat', style: TextStyle(fontSize: 11, color: AppColors.darkTextMuted)),
              Text('Sun', style: TextStyle(fontSize: 11, color: AppColors.darkTextMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

class AttendanceChartPainter extends CustomPainter {
  final List<double> data;
  final List<String> labels;

  AttendanceChartPainter({required this.data, required this.labels});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF6366F1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    if (data.isEmpty) return;

    final stepX = size.width / (data.length - 1);

    double getX(int index) => index * stepX;
    double getY(double val) {
      final pct = (val - 50.0) / 50.0; // scale between 50% and 100%
      final clampedPct = pct.clamp(0.0, 1.0);
      return size.height - (size.height * clampedPct * 0.85);
    }

    path.moveTo(getX(0), getY(data[0]));
    fillPath.moveTo(getX(0), size.height);
    fillPath.lineTo(getX(0), getY(data[0]));

    for (int i = 1; i < data.length; i++) {
      final x1 = getX(i - 1);
      final y1 = getY(data[i - 1]);
      final x2 = getX(i);
      final y2 = getY(data[i]);
      final controlX1 = x1 + (x2 - x1) / 2;
      final controlY1 = y1;
      final controlX2 = x1 + (x2 - x1) / 2;
      final controlY2 = y2;

      path.cubicTo(controlX1, controlY1, controlX2, controlY2, x2, y2);
      fillPath.cubicTo(controlX1, controlY1, controlX2, controlY2, x2, y2);
    }

    fillPath.lineTo(getX(data.length - 1), size.height);
    fillPath.close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF6366F1).withValues(alpha: 0.35),
        const Color(0xFF6366F1).withValues(alpha: 0.0),
      ],
    );
    fillPaint.shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    canvas.drawPath(path, paint);

    final pointPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = const Color(0xFF6366F1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    for (int i = 0; i < data.length; i++) {
      final center = Offset(getX(i), getY(data[i]));
      canvas.drawCircle(center, 4.5, pointPaint);
      canvas.drawCircle(center, 4.5, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// =====================================================
// BOTTOM CLASSES TABLE / LIST
// =====================================================
class _AssignedClassesTable extends StatelessWidget {
  final TeacherDashboardData data;
  final void Function(String route) onNavigate;

  const _AssignedClassesTable({required this.data, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = Responsive.isMobile(context);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Assigned Classes', style: AppTextStyles.h2),
                    const SizedBox(height: 4),
                    const Text('Spring 2026', style: TextStyle(color: AppColors.darkTextMuted)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => onNavigate('/subjects'),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Add subject'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt,
                    foregroundColor: isDark ? Colors.white : AppColors.text,
                    elevation: 0,
                    side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.border),
          if (data.assignedClassesList.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No assigned classes found.',
                  style: TextStyle(color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
                ),
              ),
            )
          else if (isMobile)
            ...data.assignedClassesList.map((c) => _buildMobileClassRow(c, isDark))
          else
            _buildDesktopTable(isDark),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(bool isDark) {
    return Column(
      children: [
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          color: isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt,
          child: Row(
            children: [
              Expanded(flex: 30, child: Text('SUBJECT', style: AppTextStyles.labelSm)),
              Expanded(flex: 16, child: Text('CLASS', style: AppTextStyles.labelSm)),
              Expanded(flex: 22, child: Text('NEXT SESSION', style: AppTextStyles.labelSm)),
              Expanded(flex: 12, child: Text('STUDENTS', style: AppTextStyles.labelSm)),
              Expanded(flex: 20, child: Text('AVG ATTENDANCE', style: AppTextStyles.labelSm)),
              Expanded(flex: 12, child: Text('STATUS', style: AppTextStyles.labelSm)),
            ],
          ),
        ),
        ...data.assignedClassesList.map((c) {
          final initials = c['name'].toString().substring(0, 1).toUpperCase();
          final att = c['avgAttendance'] as int;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 30,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c['name'],
                              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              c['code'],
                              style: const TextStyle(fontSize: 12, color: AppColors.darkTextMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 16,
                  child: Text(
                    c['className'],
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  flex: 22,
                  child: Text(
                    c['nextSession'],
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                Expanded(
                  flex: 12,
                  child: Text(
                    '${c['students']}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  flex: 20,
                  child: Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: att / 100.0,
                            minHeight: 6,
                            backgroundColor: isDark ? AppColors.darkBorder : AppColors.border,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              att >= 80 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$att%',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 12,
                  child: BadgeChip(
                    label: c['status'],
                    tone: c['status'] == 'Active' ? BadgeTone.success : BadgeTone.warning,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMobileClassRow(Map<String, dynamic> c, bool isDark) {
    final initials = c['name'].toString().substring(0, 1).toUpperCase();
    final att = c['avgAttendance'] as int;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c['name'],
                      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${c['code']} · ${c['className']}',
                      style: const TextStyle(fontSize: 12, color: AppColors.darkTextMuted),
                    ),
                  ],
                ),
              ),
              BadgeChip(
                label: c['status'],
                tone: c['status'] == 'Active' ? BadgeTone.success : BadgeTone.warning,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('NEXT SESSION', style: TextStyle(fontSize: 10, color: AppColors.darkTextMuted)),
                  const SizedBox(height: 2),
                  Text(c['nextSession'], style: const TextStyle(fontSize: 12)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('STUDENTS', style: TextStyle(fontSize: 10, color: AppColors.darkTextMuted)),
                  const SizedBox(height: 2),
                  Text('${c['students']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('ATTENDANCE  ', style: TextStyle(fontSize: 10, color: AppColors.darkTextMuted)),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: att / 100.0,
                    minHeight: 5,
                    backgroundColor: isDark ? AppColors.darkBorder : AppColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      att >= 80 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$att%',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
