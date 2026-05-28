import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cims/core/constants/app_colors.dart';
import 'package:cims/core/constants/app_constants.dart';
import 'package:cims/core/constants/app_text_styles.dart';
import 'package:cims/core/utils/responsive.dart';
import 'package:cims/core/widgets/app_scaffold.dart';
import 'package:cims/core/widgets/badge_chip.dart';
import 'package:cims/core/widgets/stat_card.dart';
import 'package:cims/core/session/app_session.dart';
import 'package:cims/features/auth/providers/auth_provider.dart';
import 'package:cims/features/admin/dashboard/providers/admin_dashboard_provider.dart';

class AdminDashboard extends ConsumerWidget {
  final void Function(String route) onNavigate;

  const AdminDashboard({
    super.key,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(adminDashboardProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      title: 'Dashboard',
      subtitle: 'ADMIN PORTAL',
      currentRoute: '/dashboard',
      role: AppSession.currentRole,
      onNavigate: onNavigate,
      body: dashboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Error: $error',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(adminDashboardProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (data) {
          final userAsync = ref.watch(currentUserProvider);
          final userName = userAsync.whenOrNull(data: (user) => user?.username) ?? 'Admin';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeroBanner(
                isDark: isDark,
                name: userName,
                sessionName: data.currentSessionName,
                onQuickAdd: () {},
                onExport: () {},
              ),
              const SizedBox(height: 20),
              _StatsGrid(data: data),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final useStack = constraints.maxWidth < 1100;
                  final trendCard = _SectionCard(
                    title: 'Enrollment Trend',
                    subtitle: 'Student growth and fee trends by month',
                    child: _EnrollmentTrendChart(
                      trend: data.enrollmentTrend,
                      isDark: isDark,
                    ),
                  );
                  final deptCard = _SectionCard(
                    title: 'Department Distribution',
                    subtitle: 'Student count by department',
                    child: _DepartmentDistribution(
                      distribution: data.departmentDistribution,
                      total: data.totalStudents,
                      isDark: isDark,
                    ),
                  );

                  if (useStack) {
                    return Column(
                      children: [
                        trendCard,
                        const SizedBox(height: 16),
                        deptCard,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: trendCard),
                      const SizedBox(width: 16),
                      Expanded(flex: 2, child: deptCard),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final useStack = constraints.maxWidth < 1200;
                  final feeCard = _SectionCard(
                    title: 'Fee by Program',
                    subtitle: 'Fee collection snapshot by program',
                    child: _FeeByProgramTable(
                      data: data.feeByProgram,
                      isDark: isDark,
                    ),
                  );
                  final activityCard = _SectionCard(
                    title: 'Recent Activity',
                    subtitle: 'Latest dashboard events',
                    child: _RecentActivity(isDark: isDark),
                  );

                  if (useStack) {
                    return Column(
                      children: [
                        feeCard,
                        const SizedBox(height: 16),
                        activityCard,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: feeCard),
                      const SizedBox(width: 16),
                      Expanded(flex: 2, child: activityCard),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  final bool isDark;
  final String name;
  final String sessionName;
  final VoidCallback onQuickAdd;
  final VoidCallback onExport;

  const _HeroBanner({
    required this.isDark,
    required this.name,
    required this.sessionName,
    required this.onQuickAdd,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: AppColors.gradientPrimary,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -60,
            top: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(AppConstants.radiusFull),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.20),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const _PulseDot(),
                              const SizedBox(width: 8),
                              Text(
                                '$sessionName Session is live',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Good evening, $name',
                          style: AppTextStyles.h1.copyWith(
                            color: Colors.white,
                            fontSize: 28,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 760),
                          child: RichText(
                            text: TextSpan(
                              style: AppTextStyles.bodyLg.copyWith(
                                color: Colors.white.withValues(alpha: 0.86),
                                height: 1.7,
                              ),
                              children: const [
                                TextSpan(text: 'You have '),
                                TextSpan(
                                  text: '14 fee defaulters, 6 attendance shortages, and 3 result sheets',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                TextSpan(text: ' awaiting publication. Quick actions are available below.'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: onQuickAdd,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Quick add'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: onExport,
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: const Text('Export report'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: const [
                  _QuickAction(icon: Icons.person_add_alt_1, label: 'Add Student'),
                  _QuickAction(icon: Icons.receipt_long, label: 'Generate Fee'),
                  _QuickAction(icon: Icons.grading_rounded, label: 'Publish Result'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final AdminDashboardData data;

  const _StatsGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);

    final card1 = StatCard(
      label: 'Total Students',
      value: data.totalStudents.toString(),
      trend: '+${(data.totalStudents * 0.05).toStringAsFixed(0)} this month',
      trendUp: true,
      tone: StatTone.primary,
      icon: const Icon(Icons.people_rounded),
    );
    final card2 = StatCard(
      label: 'Faculty Members',
      value: data.totalStaff.toString(),
      trend: '+3 joining',
      trendUp: true,
      tone: StatTone.accent,
      icon: const Icon(Icons.badge_rounded),
    );
    final card3 = StatCard(
      label: 'Fee Collection',
      value: 'PKR ${(data.totalFeeCollection / 1000000).toStringAsFixed(1)}M',
      trend: '86% rate',
      trendUp: true,
      tone: StatTone.success,
      icon: const Icon(Icons.account_balance_wallet_rounded),
    );
    final card4 = StatCard(
      label: 'Pending Dues',
      value: 'PKR ${(data.totalPendingDues / 1000000).toStringAsFixed(1)}M',
      trend: 'Active session',
      trendUp: false,
      tone: StatTone.warning,
      icon: const Icon(Icons.warning_rounded),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          card1,
          const SizedBox(height: 12),
          card2,
          const SizedBox(height: 12),
          card3,
          const SizedBox(height: 12),
          card4,
        ],
      );
    }

    if (isTablet) {
      return Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: card1),
                const SizedBox(width: 12),
                Expanded(child: card2),
              ],
            ),
          ),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: card3),
                const SizedBox(width: 12),
                Expanded(child: card4),
              ],
            ),
          ),
        ],
      );
    }

    // Desktop
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: card1),
          const SizedBox(width: 12),
          Expanded(child: card2),
          const SizedBox(width: 12),
          Expanded(child: card3),
          const SizedBox(width: 12),
          Expanded(child: card4),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTextStyles.bodySm.copyWith(
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _EnrollmentTrendChart extends StatelessWidget {
  final List<Map<String, dynamic>> trend;
  final bool isDark;

  const _EnrollmentTrendChart({
    required this.trend,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bars = trend
        .map(
          (entry) => _TrendBar(
            label: entry['month']?.toString() ?? '',
            value: (entry['students'] as num?)?.toDouble() ?? 0,
            feeValue: (entry['fees'] as num?)?.toDouble() ?? 0,
          ),
        )
        .toList();
    final maxValue = bars.isEmpty
        ? 1.0
        : bars.map((bar) => bar.value).reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 260,
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final bar in bars)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            bar.value.toInt().toString(),
                            style: AppTextStyles.caption.copyWith(
                              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 160,
                            alignment: Alignment.bottomCenter,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 18,
                              height: maxValue == 0 ? 0 : 150 * (bar.value / maxValue),
                              decoration: BoxDecoration(
                                gradient: AppColors.gradientPrimary,
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            bar.label,
                            style: AppTextStyles.labelSm.copyWith(fontSize: 11),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${bar.feeValue.toStringAsFixed(1)}M',
                            style: AppTextStyles.caption.copyWith(
                              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendBar {
  final String label;
  final double value;
  final double feeValue;

  const _TrendBar({
    required this.label,
    required this.value,
    required this.feeValue,
  });
}

class _DepartmentDistribution extends StatelessWidget {
  final List<Map<String, dynamic>> distribution;
  final int total;
  final bool isDark;

  const _DepartmentDistribution({
    required this.distribution,
    required this.total,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final entry in distribution)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _DistributionRow(
              label: entry['name']?.toString() ?? 'Other',
              value: (entry['count'] as num?)?.toInt() ?? 0,
              total: total,
              isDark: isDark,
            ),
          ),
      ],
    );
  }
}

class _DistributionRow extends StatelessWidget {
  final String label;
  final int value;
  final int total;
  final bool isDark;

  const _DistributionRow({
    required this.label,
    required this.value,
    required this.total,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final percent = total == 0 ? 0.0 : value / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              '$value',
              style: AppTextStyles.labelSm.copyWith(
                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 8,
            backgroundColor: isDark ? AppColors.darkBorder : AppColors.surfaceAlt,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }
}

class _FeeByProgramTable extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final bool isDark;

  const _FeeByProgramTable({
    required this.data,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _tableHeader('PROGRAM', 3),
              _tableHeader('STUDENTS', 1),
                _tableHeader('PAID', 14),
                _tableHeader('PENDING', 14),
            ],
          ),
        ),
        const SizedBox(height: 8),
        for (final row in data)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                ),
              ),
            ),
            child: Row(
              children: [
                _tableCell(row['program']?.toString() ?? 'Unknown', 3, bold: true),
                _tableCell('${row['students'] ?? 0}', 1),
                _tableCell('PKR ${(row['collected'] as num?)?.toDouble().toStringAsFixed(1) ?? '0.0'}M', 14),
                _tableCell('PKR ${(row['pending'] as num?)?.toDouble().toStringAsFixed(1) ?? '0.0'}M', 14),
              ],
            ),
          ),
      ],
    );
  }

  Widget _tableHeader(String label, int flex) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: AppTextStyles.labelSm.copyWith(fontSize: 11),
      ),
    );
  }

  Widget _tableCell(String value, int flex, {bool bold = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        value,
        style: AppTextStyles.body.copyWith(
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}

class _RecentActivity extends StatelessWidget {
  final bool isDark;

  const _RecentActivity({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Fee batch posted', 'Finance', '2m ago', BadgeTone.success),
      ('Attendance session saved', 'Academics', '18m ago', BadgeTone.primary),
      ('New result sheet ready', 'Exams', '1h ago', BadgeTone.warning),
      ('Student profile updated', 'Admissions', '3h ago', BadgeTone.accent),
    ];

    return Column(
      children: [
        for (final item in items)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BadgeChip(label: item.$2, tone: item.$4),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.$1,
                        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.$3,
                        style: AppTextStyles.caption.copyWith(
                          color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;

  const _QuickAction({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.65 + (_controller.value * 0.35)),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.18 + (_controller.value * 0.12)),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
    );
  }
}
