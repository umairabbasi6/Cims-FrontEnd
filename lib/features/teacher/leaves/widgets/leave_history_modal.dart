import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cims/core/constants/app_colors.dart';
import 'package:cims/core/constants/app_text_styles.dart';
import 'package:cims/core/widgets/badge_chip.dart';
import 'package:cims/features/teacher/leaves/models/leave_model.dart';
import 'package:cims/features/teacher/leaves/providers/leave_provider.dart';

class LeaveHistoryModal extends ConsumerWidget {
  const LeaveHistoryModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LeaveHistoryModal(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final leavesAsync = ref.watch(teacherLeavesProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBorder : AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Leave Applications',
                        style: AppTextStyles.h4.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkText : AppColors.text,
                        ),
                      ),
                      Text(
                        'Review your pending and past leave requests',
                        style: AppTextStyles.caption.copyWith(
                          color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),

          // Content
          Expanded(
            child: leavesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Error loading leaves: $e'),
                ),
              ),
              data: (leaves) {
                if (leaves.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.beach_access_rounded,
                          size: 48,
                          color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No leave requests found',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkText : AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'You haven\'t applied for any leaves yet.',
                          style: AppTextStyles.caption.copyWith(
                            color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: leaves.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final item = leaves[i];
                    return _LeaveCard(item: item, isDark: isDark);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaveCard extends StatelessWidget {
  final LeaveRequestModel item;
  final bool isDark;

  const _LeaveCard({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    String statusLabel = item.status.toUpperCase();
    if (item.isApproved) {
      badgeColor = AppColors.success;
    } else if (item.isRejected) {
      badgeColor = AppColors.danger;
    } else {
      badgeColor = AppColors.warning;
      statusLabel = 'PENDING';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkInputBg : AppColors.inputBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.formattedRange,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkText : AppColors.text,
                  ),
                ),
              ),
              BadgeChip(label: statusLabel, color: badgeColor),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Duration: ${item.durationDays} ${item.durationDays == 1 ? 'day' : 'days'}',
            style: AppTextStyles.caption.copyWith(
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            item.reason,
            style: AppTextStyles.body.copyWith(
              color: isDark ? AppColors.darkText : AppColors.text,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
