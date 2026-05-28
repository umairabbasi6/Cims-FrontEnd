import 'package:flutter/material.dart';

import 'package:cims/core/constants/app_colors.dart';
import 'package:cims/core/constants/app_text_styles.dart';
import 'package:cims/core/constants/mobile_tokens.dart';

/// Compact header for mobile shell: title, optional subtitle, actions + search.
class AppMobileHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget>? actions;
  final VoidCallback? onSearchTap;

  const AppMobileHeader({
    super.key,
    required this.title,
    this.subtitle = '',
    this.actions,
    this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark
          ? AppColors.darkSurface.withValues(alpha: 0.96)
          : AppColors.surface.withValues(alpha: 0.96),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDark
                  ? AppColors.darkBorderSoft
                  : AppColors.borderSoft,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (subtitle.isNotEmpty) ...[
                    Text(subtitle.toUpperCase(),
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.accent,
                        fontSize: AppMobileTypography.caption,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    title,
                    style: AppTextStyles.h4.copyWith(
                      fontSize: AppMobileTypography.sectionTitle,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.darkText
                          : AppColors.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (onSearchTap != null)
              IconButton(
                tooltip: 'Search',
                icon: const Icon(Icons.search_rounded),
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
                onPressed: onSearchTap,
              ),
            if (actions != null) ...actions!,
          ],
        ),
      ),
    );
  }
}