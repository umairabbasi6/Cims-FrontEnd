import 'package:flutter/material.dart';

import 'package:cims/core/constants/app_colors.dart';
import 'package:cims/core/constants/app_text_styles.dart';
import 'package:cims/core/navigation/more_hub_catalog.dart';
import 'package:cims/core/session/app_session.dart';
import 'package:cims/core/utils/responsive.dart';
import 'package:cims/core/widgets/app_scaffold.dart';

class MoreScreen extends StatelessWidget {
  final void Function(String route) onNavigate;

  const MoreScreen({
    super.key,
    required this.onNavigate,
  });

@override
Widget build(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  final bool isMobile = screenWidth < 600;

  final role = AppSession.currentRole;
  final entries = visibleMoreHubEntries(role);
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return AppScaffold(
    title: 'More',
    subtitle: 'Tools',
    currentRoute: '/more',
    role: role,
    onNavigate: onNavigate,
      body : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'All tools',
            style: AppTextStyles.body.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 16),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'No additional items for this role.',
                  style: AppTextStyles.bodySm.copyWith(
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.textMuted,
                  ),
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxis = Responsive.isMobile(context) ? 2 : 3;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxis,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: isMobile ? 1.2 : 1.0,
                  ),
                  itemCount: entries.length,
                  itemBuilder: (context, i) {
                    final e = entries[i];
                    return _MoreTile(
                      entry: e,
                      isDark: isDark,
                      onTap: () => onNavigate(e.route),
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  final MoreHubEntry entry;
  final bool isDark;
  final VoidCallback onTap;

  const _MoreTile({
    required this.entry,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
  
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;
    final bool isTablet = screenWidth >= 600 && screenWidth < 1024;
    final bool isDesktop = screenWidth >= 1024;

    return Material(
      color : isDark ? AppColors.darkSurface : AppColors.surface,
      borderRadius : BorderRadius.circular(16),
      child : InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                entry.icon,
                size: 28,
                color: AppColors.primary,
              ),
              const Spacer(),
              Text(
                entry.label,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
