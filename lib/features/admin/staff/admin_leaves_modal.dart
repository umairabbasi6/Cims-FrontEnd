import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cims/core/constants/app_colors.dart';
import 'package:cims/core/constants/app_text_styles.dart';
import 'package:cims/core/widgets/badge_chip.dart';
import 'package:cims/features/teacher/leaves/models/leave_model.dart';
import 'package:cims/features/teacher/leaves/providers/leave_provider.dart';

class AdminLeavesModal extends ConsumerStatefulWidget {
  const AdminLeavesModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AdminLeavesModal(),
    );
  }

  @override
  ConsumerState<AdminLeavesModal> createState() => _AdminLeavesModalState();
}

class _AdminLeavesModalState extends ConsumerState<AdminLeavesModal> {
  String _selectedFilter = 'PENDING'; // PENDING, APPROVED, REJECTED, ALL

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusFilter = _selectedFilter == 'ALL' ? null : _selectedFilter;
    final leavesAsync = ref.watch(adminLeavesProvider(statusFilter));

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag bar
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.approval_rounded, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Staff Leave Requests',
                        style: AppTextStyles.h4.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkText : AppColors.text,
                        ),
                      ),
                      Text(
                        'Review, approve or reject staff leave applications',
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
          const SizedBox(height: 16),

          // Filter Segmented Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildFilterChip('Pending', 'PENDING', isDark),
                const SizedBox(width: 8),
                _buildFilterChip('Approved', 'APPROVED', isDark),
                const SizedBox(width: 8),
                _buildFilterChip('Rejected', 'REJECTED', isDark),
                const SizedBox(width: 8),
                _buildFilterChip('All', 'ALL', isDark),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),

          // Leaves List
          Expanded(
            child: leavesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Failed to load leaves: $err'),
                ),
              ),
              data: (leaves) {
                if (leaves.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          size: 48,
                          color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No ${_selectedFilter.toLowerCase()} leave requests',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkText : AppColors.text,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: leaves.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, i) {
                    final item = leaves[i];
                    return _AdminLeaveCard(
                      item: item,
                      isDark: isDark,
                      onReview: () => ref.invalidate(adminLeavesProvider(statusFilter)),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, bool isDark) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = value;
          });
        }
      },
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : (isDark ? AppColors.darkText : AppColors.text),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }
}

class _AdminLeaveCard extends ConsumerStatefulWidget {
  final LeaveRequestModel item;
  final bool isDark;
  final VoidCallback onReview;

  const _AdminLeaveCard({
    required this.item,
    required this.isDark,
    required this.onReview,
  });

  @override
  ConsumerState<_AdminLeaveCard> createState() => _AdminLeaveCardState();
}

class _AdminLeaveCardState extends ConsumerState<_AdminLeaveCard> {
  bool _isProcessing = false;

  Future<void> _handleReview(bool approve) async {
    final notesController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(approve ? 'Approve Leave Request?' : 'Reject Leave Request?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Teacher: ${widget.item.teacherName} (${widget.item.staffIdCode})',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('Dates: ${widget.item.formattedRange} (${widget.item.durationDays} days)'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Admin Note / Remarks (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: approve ? AppColors.success : AppColors.danger,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(approve ? 'Confirm Approval' : 'Confirm Rejection'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isProcessing = true);
      try {
        await ref.read(leaveServiceProvider).approveLeave(
          widget.item.id,
          approved: approve,
          notes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: approve ? AppColors.success : AppColors.danger,
              content: Text(
                approve ? 'Leave request approved successfully.' : 'Leave request rejected.',
              ),
            ),
          );
          widget.onReview();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error reviewing leave: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isProcessing = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isDark = widget.isDark;

    Color badgeColor = AppColors.warning;
    if (item.isApproved) badgeColor = AppColors.success;
    if (item.isRejected) badgeColor = AppColors.danger;

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
              CircleAvatar(
                radius: 17,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  item.teacherName.isNotEmpty ? item.teacherName[0].toUpperCase() : 'T',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.teacherName,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkText : AppColors.text,
                      ),
                    ),
                    Text(
                      item.staffIdCode,
                      style: AppTextStyles.caption.copyWith(
                        color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              BadgeChip(label: item.status, color: badgeColor),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          Row(
            children: [
              const Icon(Icons.date_range_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                item.formattedRange,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkText : AppColors.text,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${item.durationDays} ${item.durationDays == 1 ? 'day' : 'days'}',
                  style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.reason,
            style: AppTextStyles.body.copyWith(
              color: isDark ? AppColors.darkText : AppColors.text,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),

          if (item.isPending) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                  ),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Reject'),
                  onPressed: _isProcessing ? null : () => _handleReview(false),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success,
                  ),
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Approve'),
                  onPressed: _isProcessing ? null : () => _handleReview(true),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
