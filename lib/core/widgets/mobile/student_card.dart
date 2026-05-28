import 'package:flutter/material.dart';

import 'package:cims/core/constants/app_colors.dart';
import 'package:cims/core/constants/app_text_styles.dart';
import 'package:cims/core/constants/mobile_tokens.dart';
import 'package:cims/core/widgets/badge_chip.dart';

/// View model for roster cards (mock-friendly).
class StudentCardData {
  final String initials;
  final String name;
  final String rollNo;
  final String program;
  final String session;
  final String stage;
  final String status;
  final Color avatarColor;
  final int? studentId;

  const StudentCardData({
    required this.initials,
    required this.name,
    required this.rollNo,
    required this.program,
    required this.session,
    required this.stage,
    required this.status,
    required this.avatarColor,
    this.studentId,
  });
}

/// Mobile-first student row / card (used on phone lists).
class StudentCard extends StatelessWidget {
  final StudentCardData data;
  final VoidCallback? onTap;
  final bool showMenu;
  final PopupMenuItemBuilder<String>? menuItems;
  final ValueChanged<String>? onMenuSelected;

  const StudentCard({
    super.key,
    required this.data,
    this.onTap,
    this.showMenu = true,
    this.menuItems,
    this.onMenuSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppMobileRadii.card),
        child: Container(
          padding: const EdgeInsets.all(16),
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
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: data.avatarColor,
                      borderRadius: BorderRadius.circular(
                        AppMobileRadii.avatar,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      data.initials,
                      style: AppTextStyles.bodySm.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.name,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          data.rollNo,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.darkTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showMenu && menuItems != null)
                    PopupMenuButton<String>(
                      itemBuilder: menuItems!,
                      onSelected: onMenuSelected,
                    ),
                ],
              ),
              const SizedBox(height: 14),
              _detailRow('Program', data.program),
              const SizedBox(height: 10),
              _detailRow('Session', data.session),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _detailBadge(
                      'Stage',
                      BadgeChip(
                        label: data.stage,
                        tone: BadgeTone.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _detailBadge(
                      'Status',
                      BadgeChip.status(data.status),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.darkTextMuted,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.body,
          ),
        ),
      ],
    );
  }

  Widget _detailBadge(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.darkTextMuted,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

Future<void> showStudentQuickDetailSheet(
  BuildContext context,
  StudentCardData data,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.darkSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppMobileRadii.sheet),
      ),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: data.avatarColor,
                      borderRadius: BorderRadius.circular(
                        AppMobileRadii.avatar,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      data.initials,
                      style: AppTextStyles.body.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.name,
                          style: AppTextStyles.h3,
                        ),
                        Text(
                          data.rollNo,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.darkTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                data.program,
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 8),
              Text(
                '${data.session} · Stage ${data.stage}',
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.darkTextMuted,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
