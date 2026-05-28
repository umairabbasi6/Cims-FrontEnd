import 'package:flutter/widgets.dart';

/// Responsive breakpoint helpers for CIMS.
///
/// Breakpoints:
///   Mobile  → width < 768
///   Tablet  → 768 ≤ width < 1024
///   Desktop → width ≥ 1024
class Responsive {
  Responsive._();

  // ─────────────────────────────────────────────────────
  // BREAKPOINTS
  // ─────────────────────────────────────────────────────

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 768;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w >= 768 && w < 1024;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1024;

  // ─────────────────────────────────────────────────────
  // LAYOUT
  // ─────────────────────────────────────────────────────

  /// Page-level content padding based on screen width.
  static double pagePadding(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= 1600) return 48.0;
    if (w >= 1024) return 32.0;
    if (w >= 768) return 24.0;
    return 16.0;
  }

  /// Stat/KPI card columns: 1 on mobile, 4 on larger screens.
  static int dashboardColumns(BuildContext context) =>
      isMobile(context) ? 1 : 4;

  /// Minimum width for horizontal data tables before they scroll.
  static double tableMinWidth(BuildContext context) =>
      isMobile(context) ? 720 : 1200;

  /// True when the top bar should use compact (icon-only) action buttons.
  static bool compactTopBar(BuildContext context) =>
      MediaQuery.of(context).size.width < 1200;

  // ─────────────────────────────────────────────────────
  // MODALS
  // ─────────────────────────────────────────────────────

  /// Full width on mobile, fixed width on larger screens.
  static double modalWidth(BuildContext context) {
    if (isMobile(context)) return MediaQuery.of(context).size.width;
    return MediaQuery.of(context).size.width >= 1400 ? 620 : 560;
  }

  /// No inset padding on mobile (full-width modal); 24 px on desktop.
  static EdgeInsets modalInsetPadding(BuildContext context) =>
      isMobile(context) ? EdgeInsets.zero : const EdgeInsets.all(24);

  /// Returns a responsive childAspectRatio based on local constraints width.
  static double getResponsiveRatio(double width) {
    if (width < 600) return 0.9;
    if (width < 900) return 1.15;
    if (width < 1200) return 1.35;
    return 1.6;
  }
}