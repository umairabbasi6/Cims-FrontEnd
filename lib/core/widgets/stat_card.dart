import 'package:flutter/material.dart';

import 'package:cims/core/constants/app_colors.dart';
import 'package:cims/core/constants/app_constants.dart';
import 'package:cims/core/constants/app_text_styles.dart';
import 'package:cims/core/utils/responsive.dart';

class StatCard extends StatefulWidget {
  final String label;
  final String value;
  final String? trend;
  final bool trendUp;
  final StatTone tone;
  final dynamic icon;
  final Color? color;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.trend,
    this.trendUp = true,
    this.tone = StatTone.primary,
    this.icon,
    this.color,
  });

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = _toneColors(isDark);

    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.all(Responsive.isMobile(context) ? 12 : 20),
        transform: Matrix4.translationValues(
          0,
          hovered ? -3 : 0,
          0,
        ),
        constraints: const BoxConstraints(
          minHeight: 120,
          maxHeight: 180,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(
            AppConstants.radiusMd,
          ),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: isDark ? 0.18 : 0.05,
              ),
              blurRadius: hovered ? 24 : 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.label.toUpperCase(),
                    style: AppTextStyles.label.copyWith(
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.textMuted,
                    ),
                  ),
                ),

                if (widget.icon != null)
                  Container(
                    width: 40,
                    height: 40,

                    decoration: BoxDecoration(
                      color: colors.background,
                      borderRadius: BorderRadius.circular(
                        AppConstants.radiusSm,
                      ),
                    ),
                    child: Center(
                      child: widget.icon is IconData
                          ? Icon(
                              widget.icon as IconData,
                              size: 18,
                              color: colors.foreground,
                            )
                          : IconTheme(
                              data: IconThemeData(
                                color: colors.foreground,
                                size: 18,
                              ),
                              child: widget.icon is Widget ? (widget.icon as Widget) : const SizedBox.shrink(),
                            ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 18),

            Text(
              widget.value,
              style: AppTextStyles.statValue.copyWith(
                color: isDark ? AppColors.darkText : AppColors.text,
              ),
            ),

            const SizedBox(height: 12),

            if (widget.trend != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: widget.trendUp
                      ? (isDark ? AppColors.success.withValues(alpha: 0.16) : AppColors.successSoft)
                      : (isDark ? AppColors.danger.withValues(alpha: 0.16) : AppColors.dangerSoft),
                  borderRadius: BorderRadius.circular(
                    AppConstants.radiusFull,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.trendUp
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 14,
                      color: widget.trendUp ? AppColors.success : AppColors.danger,
                    ),

                    const SizedBox(width: 4),

                    Flexible(
                      child: Text(
                        widget.trend!,
                        style: AppTextStyles.caption.copyWith(
                          color: widget.trendUp
                              ? AppColors.success
                              : AppColors.danger,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  _StatColors _toneColors(bool isDark) {
    if (widget.color != null) {
      return _StatColors(
        widget.color!,
        widget.color!.withValues(alpha: isDark ? 0.2 : 0.12),
      );
    }

    switch (widget.tone) {
      case StatTone.primary:
        return _StatColors(
          AppColors.primary,
          isDark ? AppColors.primary.withValues(alpha: 0.16) : AppColors.primarySoft,
        );

      case StatTone.success:
        return _StatColors(
          AppColors.success,
          isDark ? AppColors.success.withValues(alpha: 0.16) : AppColors.successSoft,
        );

      case StatTone.warning:
        return _StatColors(
          AppColors.warning,
          isDark ? AppColors.warning.withValues(alpha: 0.16) : AppColors.warningSoft,
        );

      case StatTone.danger:
        return _StatColors(
          AppColors.danger,
          isDark ? AppColors.danger.withValues(alpha: 0.16) : AppColors.dangerSoft,
        );

      case StatTone.accent:
        return _StatColors(
          AppColors.accent,
          isDark ? AppColors.accent.withValues(alpha: 0.16) : AppColors.accentSoft,
        );

      case StatTone.purple:
        return _StatColors(
          AppColors.purple,
          isDark ? AppColors.purple.withValues(alpha: 0.16) : AppColors.purpleSoft,
        );
    }
  }
}

class _StatColors {
  final Color foreground;
  final Color background;

  const _StatColors(
    this.foreground,
    this.background,
  );
}

enum StatTone {
  primary,
  success,
  warning,
  danger,
  accent,
  purple,
}
