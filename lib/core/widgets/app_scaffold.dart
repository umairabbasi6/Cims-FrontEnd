import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:cims/core/constants/app_colors.dart';
import 'package:cims/core/navigation/mobile_bottom_nav.dart';
import 'package:cims/core/utils/responsive.dart';
import 'package:cims/core/widgets/mobile/app_mobile_header.dart';
import 'package:cims/core/widgets/sidebar.dart';
import 'package:cims/core/widgets/top_bar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// APP SCAFFOLD
// ─────────────────────────────────────────────────────────────────────────────

class AppScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final String currentRoute;
  final String role;
  final Widget body;
  final List<Widget>? actions;
  final void Function(String route) onNavigate;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final VoidCallback? onMobileSearchTap;
  final bool suppressDefaultMobileSearch;

  const AppScaffold({
    super.key,
    required this.title,
    this.subtitle = '',
    required this.currentRoute,
    required this.role,
    required this.body,
    this.actions,
    required this.onNavigate,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.onMobileSearchTap,
    this.suppressDefaultMobileSearch = false,
  });
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return isMobile ? _buildMobile(context, isDark) : _buildDesktop(context, isDark);
  }

  Widget _buildDesktop(BuildContext context, bool isDark) {
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.bg,
      body: SafeArea(
        child: Row(
          children: [
            AppSidebar(
              currentRoute: currentRoute,
              role: role,
              onNavigate: onNavigate,
            ),
            Expanded(
              child: Column(
                children: [
                  TopBar(
                    title: title,
                    subtitle: subtitle,
                    role: role,
                    actions: actions,
                    showMenuButton: false,
                  ),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      color: isDark ? AppColors.darkBg : AppColors.bg,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(
                            Responsive.pagePadding(context),
                          ),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1600),
                            child: body,
                          ),
                        ),
                      ),
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

  Widget _buildMobile(BuildContext context, bool isDark) {
    final navItems = mobileBottomNavItemsForRole(role);
    final activeIndex = mobileBottomNavIndex(currentRoute, role);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.bg,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation:
          floatingActionButtonLocation ?? FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppMobileHeader(
              title: title,
              subtitle: subtitle,
              actions: actions,
              onSearchTap: onMobileSearchTap ??
                  (suppressDefaultMobileSearch
                      ? null
                      : () {
                          GoRouter.of(context).push('/search');
                        }),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(
                  Responsive.pagePadding(context),
                ),
                child: body,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _MobileBottomNav(
        items: navItems,
        currentIndex: activeIndex,
        isDark: isDark,
        onTap: (i) => onNavigate(navItems[i].route),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MOBILE BOTTOM NAV WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class _MobileBottomNav extends StatelessWidget {
  final List<MobileNavItem> items;
  final int currentIndex;
  final bool isDark;
  final void Function(int index) onTap;

  const _MobileBottomNav({
    required this.items,
    required this.currentIndex,
    required this.isDark,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.08),
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final isActive = i == currentIndex;

              return Expanded(
                child: _NavButton(
                  item: item,
                  isActive: isActive,
                  isDark: isDark,
                  onTap: () => onTap(i),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final MobileNavItem item;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.primary;
    final inactiveColor = isDark
        ? Colors.white.withOpacity(0.45)
        : Colors.black.withOpacity(0.40);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      splashColor: AppColors.primary.withOpacity(0.12),
      highlightColor: AppColors.primary.withOpacity(0.06),
      child: SizedBox(
        width: double.infinity,
        height: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: isActive ? 40 : 0,
              height: isActive ? 3 : 0,
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: activeColor,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Icon(
              isActive ? item.activeIcon : item.icon,
              color: isActive ? activeColor : inactiveColor,
              size: 22,
            ),
            SizedBox(height: 3),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? activeColor : inactiveColor,
                letterSpacing: 0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
