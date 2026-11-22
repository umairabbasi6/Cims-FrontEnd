import 'package:flutter/material.dart';

import 'package:cims/core/constants/app_colors.dart';
import 'package:cims/core/constants/app_constants.dart';

class BadgeChip extends StatelessWidget {
  final String label;
  final BadgeTone tone;
  final double? fontSize;
  final Color? color;

  const BadgeChip({
    super.key,
    required this.label,
    this.tone = BadgeTone.muted,
    this.fontSize,
    this.color,
  });

  factory BadgeChip.status(String status) {
    final lower = status.toLowerCase();

    BadgeTone tone;

    if ([
      'active',
      'current',
      'paid',
      'submitted',
      'passed',
      'completed',
      'cleared',
      'good standing'
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
      'overdue',
      'failed'
    ].contains(lower)) {
      tone = BadgeTone.danger;
    } else if ([
      'on leave',
      'pending',
      'due'
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
    if (color != null) {
      return _BadgeColors(
        color!,
        color!.withValues(alpha: isDark ? 0.2 : 0.12),
      );
    }

    switch (tone) {
      case BadgeTone.success:
        return _BadgeColors(
          AppColors.success,
          isDark ? AppColors.success.withValues(alpha: 0.16) : AppColors.successSoft,
        );

      case BadgeTone.warning:
        return _BadgeColors(
          AppColors.warning,
          isDark ? AppColors.warning.withValues(alpha: 0.16) : AppColors.warningSoft,
        );

      case BadgeTone.danger:
        return _BadgeColors(
          AppColors.danger,
          isDark ? AppColors.danger.withValues(alpha: 0.16) : AppColors.dangerSoft,
        );

      case BadgeTone.primary:
        return _BadgeColors(
          AppColors.primary,
          isDark ? AppColors.primary.withValues(alpha: 0.16) : AppColors.primarySoft,
        );

      case BadgeTone.accent:
        return _BadgeColors(
          AppColors.accent,
          isDark ? AppColors.accent.withValues(alpha: 0.16) : AppColors.accentSoft,
        );

      case BadgeTone.purple:
        return _BadgeColors(
          AppColors.purple,
          isDark ? AppColors.purple.withValues(alpha: 0.16) : AppColors.purpleSoft,
        );

      case BadgeTone.pink:
        return _BadgeColors(
          AppColors.pink,
          isDark ? AppColors.pink.withValues(alpha: 0.16) : AppColors.pinkSoft,
        );

      case BadgeTone.info:
        return _BadgeColors(
          AppColors.info,
          isDark ? AppColors.info.withValues(alpha: 0.16) : AppColors.infoSoft,
        );

      case BadgeTone.muted:
        return _BadgeColors(
          isDark ? AppColors.darkTextMuted : AppColors.textMuted,
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