import 'package:flutter/material.dart';

import 'package:cims/core/constants/app_colors.dart';
import 'package:cims/core/constants/app_constants.dart';

class BadgeChip extends StatelessWidget {
  final String label;
  final BadgeTone tone;
  final double? fontSize;

  const BadgeChip({
    super.key,
    required this.label,
    this.tone = BadgeTone.muted,
    this.fontSize,
  });

  factory BadgeChip.status(String status) {
    final lower = status.toLowerCase();

    BadgeTone tone;

    if ([
      'active',
      'current',
      'paid',
      'submitted'
    ].contains(lower)) {
      tone = BadgeTone.success;
    } else if ([
      'inactive',
      'closed',
      'view only'
    ].contains(lower)) {
      tone = BadgeTone.muted;
    } else if ([
      'suspended',
      'overdue'
    ].contains(lower)) {
      tone = BadgeTone.danger;
    } else if ([
      'on leave',
      'pending'
    ].contains(lower)) {
      tone = BadgeTone.warning;
    } else {
      tone = BadgeTone.info;
    }

    return BadgeChip(
      label: status,
      tone: tone,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final colors = _toneColors(isDark);

    return Container(
      height: 24,

      padding: const EdgeInsets.symmetric(
        horizontal: 10,
      ),

      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(
          AppConstants.radiusFull,
        ),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,

            decoration: BoxDecoration(
              color: colors.foreground,
              shape: BoxShape.circle,
            ),
          ),

          SizedBox(width: 6),

          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: fontSize ?? 11,
                fontWeight: FontWeight.w700,
                color: colors.foreground,
                letterSpacing: 0.02,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _BadgeColors _toneColors(bool isDark) {
    switch (tone) {
      case BadgeTone.success:
        return _BadgeColors(
          AppColors.success,
          AppColors.successSoft,
        );

      case BadgeTone.warning:
        return _BadgeColors(
          AppColors.warning,
          AppColors.warningSoft,
        );

      case BadgeTone.danger:
        return _BadgeColors(
          AppColors.danger,
          AppColors.dangerSoft,
        );

      case BadgeTone.primary:
        return _BadgeColors(
          AppColors.primary,
          AppColors.primarySoft,
        );

      case BadgeTone.accent:
        return _BadgeColors(
          AppColors.accent,
          AppColors.accentSoft,
        );

      case BadgeTone.purple:
        return _BadgeColors(
          AppColors.purple,
          AppColors.purpleSoft,
        );

      case BadgeTone.pink:
        return _BadgeColors(
          AppColors.pink,
          AppColors.pinkSoft,
        );

      case BadgeTone.info:
        return _BadgeColors(
          AppColors.info,
          AppColors.infoSoft,
        );

      case BadgeTone.muted:
        return _BadgeColors(
          AppColors.textMuted,
          isDark
              ? AppColors.darkSurfaceHover
              : AppColors.surfaceHover,
        );
    }
  }
}

class _BadgeColors {
  final Color foreground;
  final Color background;

  const _BadgeColors(
    this.foreground,
    this.background,
  );
}

enum BadgeTone {
  success,
  warning,
  danger,
  primary,
  accent,
  purple,
  pink,
  info,
  muted,
}