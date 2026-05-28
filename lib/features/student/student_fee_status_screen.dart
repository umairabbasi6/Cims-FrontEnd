import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:cims/core/constants/app_colors.dart';
import 'package:cims/core/constants/app_text_styles.dart';
import 'package:cims/core/widgets/app_scaffold.dart';
import 'package:cims/core/widgets/badge_chip.dart';

import 'package:cims/features/admin/fees/providers/fees_api_provider.dart';
import 'package:cims/features/admin/sessions/providers/session_provider.dart';
import 'package:cims/features/admin/students/providers/student_provider.dart';

class StudentFeeStatusScreen extends ConsumerWidget {
  final void Function(String route) onNavigate;

  const StudentFeeStatusScreen({
    super.key,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(currentStudentProvider);
    final sessionAsync = ref.watch(currentAcademicSessionProvider);



    return studentAsync.when(
      data: (student) {
        if (student == null) {
          return const Scaffold(
            body: Center(child: Text('Student profile not found')),
          );
        }

        return sessionAsync.when(
          data: (session) {
            final param = StudentFeeDashboardParam(
              studentId: student.id,
              sessionId: session?.id,
            );

            final dashboardAsync = ref.watch(studentFeeDashboardProvider(param));
            final paymentsAsync = ref.watch(studentPaymentsProvider(param));

            // Helper to safely format currency in "k" formats
            String formatCurrency(dynamic val, String fallback) {
              if (val == null) return fallback;
              final numValue = num.tryParse(val.toString())?.toDouble();
              if (numValue == null) return val.toString();
              if (numValue >= 1000000) {
                return 'PKR ${(numValue / 1000000).toStringAsFixed(1)}m';
              } else if (numValue >= 1000) {
                if (numValue % 1000 == 0) {
                  return 'PKR ${(numValue ~/ 1000)}k';
                }
                return 'PKR ${(numValue / 1000).toStringAsFixed(1)}k';
              }
              return 'PKR ${NumberFormat('#,##0').format(numValue)}';
            }

            // Helper to format due date
            String formatDueDate(dynamic dateVal, String fallback) {
              if (dateVal == null) return fallback;
              final dateStr = dateVal.toString();
              if (dateStr.isEmpty) return fallback;
              try {
                final parsed = DateTime.parse(dateStr);
                return "Due ${DateFormat('MMM dd').format(parsed)}";
              } catch (_) {
                return "Due $dateStr";
              }
            }

            final dashboardData = dashboardAsync.asData?.value;
            final summary = dashboardData?['summary'] as Map<String, dynamic>?;
            final currentDue = dashboardData?['current_due'] as Map<String, dynamic>?;

            final semFeeVal = formatCurrency(summary?['semester_fee'], 'PKR 0');
            final semFeePaidVal = "${formatCurrency(summary?['paid_amount'], 'PKR 0')} paid";

            final pendingBalVal = formatCurrency(summary?['pending_balance'], 'PKR 0');
            final pendingBalPill = formatDueDate(currentDue?['due_date'], 'Cleared');

            final scholarshipVal = "${summary?['scholarship_percentage'] ?? '0'}%";
            final scholarshipPill = 'Scholarship';

            final totalPaidVal = formatCurrency(summary?['total_paid_lifetime'] ?? summary?['paid_amount'], 'PKR 0');

            final historyList = paymentsAsync.when(
              data: (list) {
                if (list.isEmpty) return <(String, String, String, String, String)>[];
                return list.map<(String, String, String, String, String)>((item) {
                  final receiptNo = item['receipt_number']?.toString() ?? item['id']?.toString() ?? 'REC-000';
                  final term = item['remarks']?.toString() ?? session?.name ?? '—';
                  final amountPaid = (item['amount_paid'] as num?)?.toDouble() ?? 0.0;
                  final amountStr = 'PKR ${NumberFormat('#,##0').format(amountPaid)}';
                  final method = item['payment_method']?.toString() ?? 'Cash';

                  String dateStr = '—';
                  final rawDate = item['payment_date'] ?? item['created_at'];
                  if (rawDate != null) {
                    try {
                      final parsed = DateTime.parse(rawDate.toString());
                      dateStr = DateFormat('MMM dd, yyyy').format(parsed);
                    } catch (_) {
                      dateStr = rawDate.toString();
                    }
                  }

                  return (receiptNo, term, amountStr, method, dateStr);
                }).toList();
              },
              loading: () => <(String, String, String, String, String)>[],
              error: (_, __) => <(String, String, String, String, String)>[],
            );

            final displayHistory = historyList;

            return AppScaffold(
              title: 'Fee Status',
              subtitle: 'RECORDS',
              currentRoute: '/fees',
              role: 'student',
              onNavigate: onNavigate,
              body: Column(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 600) {
                        // Mobile layout: 2 columns
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                              width: (constraints.maxWidth - 12) / 2,
                              child: _FeeMetric(
                                label: 'Semester Fee',
                                value: semFeeVal,
                                pill: semFeePaidVal,
                                icon: Icons.receipt_long_outlined,
                                tone: BadgeTone.primary,
                              ),
                            ),
                            SizedBox(
                              width: (constraints.maxWidth - 12) / 2,
                              child: _FeeMetric(
                                label: 'Pending Balance',
                                value: pendingBalVal,
                                pill: pendingBalPill,
                                icon: Icons.warning_amber_rounded,
                                tone: BadgeTone.warning,
                              ),
                            ),
                            SizedBox(
                              width: (constraints.maxWidth - 12) / 2,
                              child: _FeeMetric(
                                label: 'Scholarship',
                                value: scholarshipVal,
                                pill: scholarshipPill,
                                icon: Icons.auto_awesome_outlined,
                                tone: BadgeTone.success,
                              ),
                            ),
                            SizedBox(
                              width: (constraints.maxWidth - 12) / 2,
                              child: _FeeMetric(
                                label: 'Total Paid',
                                value: totalPaidVal,
                                pill: 'Lifetime',
                                icon: Icons.check_circle_outline_rounded,
                                tone: BadgeTone.accent,
                              ),
                            ),
                          ],
                        );
                      } else {
                        // Desktop/tablet layout: 4 columns in a row
                        return Row(
                          children: [
                            Expanded(
                              child: _FeeMetric(
                                label: 'Semester Fee',
                                value: semFeeVal,
                                pill: semFeePaidVal,
                                icon: Icons.receipt_long_outlined,
                                tone: BadgeTone.primary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _FeeMetric(
                                label: 'Pending Balance',
                                value: pendingBalVal,
                                pill: pendingBalPill,
                                icon: Icons.warning_amber_rounded,
                                tone: BadgeTone.warning,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _FeeMetric(
                                label: 'Scholarship',
                                value: scholarshipVal,
                                pill: scholarshipPill,
                                icon: Icons.auto_awesome_outlined,
                                tone: BadgeTone.success,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _FeeMetric(
                                label: 'Total Paid',
                                value: totalPaidVal,
                                pill: 'Lifetime',
                                icon: Icons.check_circle_outline_rounded,
                                tone: BadgeTone.accent,
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  if (currentDue != null)
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.darkSurface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.darkBorder),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth < 600) {
                              // Mobile layout: stack vertically
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: AppColors.warningSoft,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.receipt_long_outlined, color: AppColors.warning),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "${currentDue['fee_type'] ?? 'Tuition Fee'} · ${session?.name ?? ''}",
                                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                                            ),
                                            Text(
                                              "INV-${currentDue['id'] ?? '—'} · ${session?.name ?? ''}",
                                              style: const TextStyle(color: AppColors.darkTextMuted, fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Text(
                                        formatCurrency(currentDue['due_amount'], 'PKR 22,000'),
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      BadgeChip(
                                        label: formatDueDate(currentDue['due_date'], 'Due May 15'),
                                        tone: currentDue['is_overdue'] == true ? BadgeTone.danger : BadgeTone.warning,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: AppColors.darkBorder),
                                        ),
                                        child: const Icon(Icons.visibility_outlined, color: AppColors.darkTextMuted),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () {},
                                          icon: const Icon(Icons.account_balance_wallet_outlined),
                                          label: Text('Pay ${formatCurrency(currentDue['due_amount'], 'PKR 22,000')}'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            } else {
                              // Desktop/tablet layout: horizontal row
                              return Row(
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: AppColors.warningSoft,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Icon(Icons.receipt_long_outlined, color: AppColors.warning),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "${currentDue['fee_type'] ?? 'Tuition Fee'} · ${session?.name ?? ''}",
                                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
                                              ),
                                              Text(
                                                "INV-${currentDue['id'] ?? '—'} · ${session?.name ?? ''}",
                                                style: const TextStyle(color: AppColors.darkTextMuted),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          formatCurrency(currentDue['due_amount'], 'PKR 22,000'),
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                                        ),
                                        const SizedBox(width: 12),
                                        BadgeChip(
                                          label: formatDueDate(currentDue['due_date'], 'Due May 15'),
                                          tone: currentDue['is_overdue'] == true ? BadgeTone.danger : BadgeTone.warning,
                                        ),
                                        const SizedBox(width: 12),
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: AppColors.darkBorder),
                                          ),
                                          child: const Icon(Icons.visibility_outlined, color: AppColors.darkTextMuted),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  ElevatedButton.icon(
                                    onPressed: () {},
                                    icon: const Icon(Icons.account_balance_wallet_outlined),
                                    label: Text('Pay ${formatCurrency(currentDue['due_amount'], 'PKR 22,000')}'),
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.darkSurface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.darkBorder),
                      ),
                      padding: const EdgeInsets.all(20),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 24),
                          const SizedBox(width: 12),
                          Text(
                            'No outstanding payments. You are all caught up!',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.darkTextMuted,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Payment History', style: AppTextStyles.h2),
                                    const SizedBox(height: 4),
                                    const Text('Last 12 months', style: TextStyle(color: AppColors.darkTextMuted)),
                                  ],
                                ),
                              ),
                              const Text('Statements', style: TextStyle(fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                color: AppColors.darkSurfaceAlt,
                                child: Row(
                                  children: [
                                    SizedBox(width: 100, child: Text('RECEIPT', style: AppTextStyles.labelSm)),
                                    SizedBox(width: 120, child: Text('TERM', style: AppTextStyles.labelSm)),
                                    SizedBox(width: 100, child: Text('AMOUNT', style: AppTextStyles.labelSm)),
                                    SizedBox(width: 100, child: Text('METHOD', style: AppTextStyles.labelSm)),
                                    SizedBox(width: 90, child: Text('DATE', style: AppTextStyles.labelSm)),
                                    SizedBox(width: 80, child: Text('STATUS', style: AppTextStyles.labelSm)),
                                  ],
                                ),
                              ),
                              if (displayHistory.isEmpty)
                                Container(
                                  width: 590,
                                  padding: const EdgeInsets.all(24),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'No payments recorded yet.',
                                    style: TextStyle(color: AppColors.darkTextMuted),
                                  ),
                                )
                              else
                                ...displayHistory.map(
                                  (row) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                    decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.darkBorder))),
                                    child: Row(
                                      children: [
                                        SizedBox(width: 100, child: Text(row.$1, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700))),
                                        SizedBox(width: 120, child: Text(row.$2)),
                                        SizedBox(width: 100, child: Text(row.$3, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700))),
                                        SizedBox(width: 100, child: Text(row.$4)),
                                        SizedBox(width: 90, child: Text(row.$5)),
                                        SizedBox(width: 80, child: const BadgeChip(label: 'Paid', tone: BadgeTone.success)),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (err, _) => Scaffold(
            body: Center(child: Text('Error loading session: $err')),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        body: Center(child: Text('Error loading student: $err')),
      ),
    );
  }
}

class _FeeMetric extends StatelessWidget {
  final String label;
  final String value;
  final String pill;
  final IconData icon;
  final BadgeTone tone;

  const _FeeMetric({
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
      BadgeTone.warning => AppColors.warning,
      BadgeTone.success => AppColors.success,
      _ => AppColors.accent,
    };

    return Container(
      padding: const EdgeInsets.all(20),
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
              Expanded(child: Text(label, style: AppTextStyles.bodySm.copyWith(color: AppColors.darkTextMuted))),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(value, style: AppTextStyles.h1.copyWith(fontSize: 24)),
          SizedBox(height: 16),
          BadgeChip(label: pill, tone: tone),
        ],
      ),
    );
  }
}