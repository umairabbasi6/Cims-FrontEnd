import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cims/features/auth/providers/auth_provider.dart';
import 'package:cims/features/admin/sessions/providers/session_provider.dart';
import 'package:cims/features/admin/students/providers/student_provider.dart';
import 'package:cims/features/admin/subjects/providers/subject_provider.dart';
import 'package:cims/core/network/app_router.dart';
import 'package:cims/core/constants/app_colors.dart';
import 'package:cims/core/constants/app_constants.dart';
import 'package:cims/core/constants/app_text_styles.dart';
import 'package:cims/core/constants/role_profile.dart';
import 'package:cims/core/theme/theme_mode_provider.dart';
import 'package:cims/core/utils/responsive.dart';
import 'package:cims/core/widgets/topbar_user_menu.dart';

class TopBar extends ConsumerWidget {
  final String title;
  final String subtitle;
  final String role;
  final bool showSearch;
  final List<Widget>? actions;
  final VoidCallback? onMenuPressed;
  final bool showMenuButton;

  const TopBar({
    super.key,
    required this.title,
    required this.role,
    this.subtitle = '',
    this.showSearch = true,
    this.actions,
    this.onMenuPressed,
    this.showMenuButton = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final compact = Responsive.compactTopBar(context);

    return Container(
      height: AppConstants.topbarHeight,
      padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 24),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurface.withValues(alpha: 0.98)
            : AppColors.surface.withValues(alpha: 0.98),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorderSoft : AppColors.borderSoft,
          ),
        ),
      ),
      child: Row(
        children: [
          if (showMenuButton) ...[
            _TopbarIconButton(
              icon: Icons.menu_rounded,
              isDark: isDark,
              onTap: onMenuPressed ?? () {},
            ),
            SizedBox(width: compact ? 12 : 16),
          ],
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle.toUpperCase(),
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: AppTextStyles.h2.copyWith(
                    fontSize: compact ? 20 : 22,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkText : AppColors.text,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: compact ? 12 : 20),
          if (showSearch && !compact) _SearchBox(isDark: isDark),
          if (showSearch && compact)
            _TopbarIconButton(
              icon: Icons.search_rounded,
              isDark: isDark,
              onTap: () {},
            ),
          if (showSearch) SizedBox(width: compact ? 8 : 16),
          if (!compact && actions != null && actions!.isNotEmpty) ...[
            ...actions!,
            const SizedBox(width: 10),
          ],
          _TopbarIconButton(
            icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            isDark: isDark,
            onTap: () {
              ref.read(themeModeProvider.notifier).state =
                  isDark ? ThemeMode.light : ThemeMode.dark;
            },
          ),
          const SizedBox(width: 8),
          Stack(
            children: [
              _TopbarIconButton(
                icon: Icons.notifications_none_rounded,
                isDark: isDark,
                onTap: () {},
              ),
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          if (!compact) ...[
            const SizedBox(width: 12),
            TopbarUserMenu(
              isDark: isDark,
              role: role,
            ),
          ],
        ],
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  final bool isDark;

  const _SearchBox({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 360,
      height: 40,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            Icon(
              Icons.search_rounded,
              size: 20,
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                style: AppTextStyles.body.copyWith(
                  color: isDark ? AppColors.darkText : AppColors.text,
                ),
                decoration: InputDecoration(
                  hintText: 'Search students, subjects, anything...',
                  hintStyle: TextStyle(
                    color:
                        isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : AppColors.border,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Ctrl+K',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopbarIconButton extends StatefulWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  const _TopbarIconButton({
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_TopbarIconButton> createState() => _TopbarIconButtonState();
}

class _TopbarIconButtonState extends State<_TopbarIconButton> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: hovered
                ? (widget.isDark
                    ? AppColors.darkSurfaceHover
                    : AppColors.surfaceHover)
                : (widget.isDark ? AppColors.darkSurface : AppColors.surface),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: hovered
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : (widget.isDark ? AppColors.darkBorder : AppColors.border),
              width: 1.5,
            ),
          ),
          child: Icon(
            widget.icon,
            size: 20,
            color: hovered
                ? AppColors.primary
                : (widget.isDark ? AppColors.darkTextMuted : AppColors.textMuted),
          ),
        ),
      ),
    );
  }
}

