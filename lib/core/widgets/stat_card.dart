import 'package:flutter/material.dart';

import 'package:cims/core/constants/app_colors.dart';
import 'package:cims/core/constants/app_constants.dart';
import 'package:cims/core/constants/app_text_styles.dart';

class StatCard extends StatefulWidget {
  final String label;
  final String value;
  final String? trend;
  final bool trendUp;
  final StatTone tone;
  final Widget? icon;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.trend,
    this.trendUp = true,
    this.tone = StatTone.primary,
    this.icon,
  });

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = _toneColors();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 12 : 20),
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
                      child: IconTheme(
                        data: IconThemeData(
                          color: colors.foreground,
                          size: 18,
                        ),
                        child: widget.icon!,
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
                  color: widget.trendUp ? AppColors.successSoft : AppColors.dangerSoft,
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

  _StatColors _toneColors() {
    switch (widget.tone) {
      case StatTone.primary:
        return _StatColors(
          AppColors.primary,
          AppColors.primarySoft,
        );

      case StatTone.success:
        return _StatColors(
          AppColors.success,
          AppColors.successSoft,
        );

      case StatTone.warning:
        return _StatColors(
          AppColors.warning,
          AppColors.warningSoft,
        );

      case StatTone.danger:
        return _StatColors(
          AppColors.danger,
          AppColors.dangerSoft,
        );

      case StatTone.accent:
        return _StatColors(
          AppColors.accent,
          AppColors.accentSoft,
        );

      case StatTone.purple:
        return _StatColors(
          AppColors.purple,
          AppColors.purpleSoft,
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
