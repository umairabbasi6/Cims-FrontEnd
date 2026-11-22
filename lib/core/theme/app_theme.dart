import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:cims/core/constants/app_colors.dart';
import 'package:cims/core/constants/app_constants.dart';
import 'package:cims/core/constants/mobile_tokens.dart';

class AppTheme {
  AppTheme._();

  // =====================================================
  // LIGHT THEME
  // =====================================================

  static ThemeData get light {
    const borderSide = BorderSide(color: AppColors.border, width: 1.0);
    const borderSideStrong = BorderSide(color: AppColors.border, width: 1.5);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // -------------------------------------------------
      // COLOR SCHEME
      // -------------------------------------------------
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.accent,
        onSecondary: Colors.white,
        error: AppColors.danger,
        onError: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.text,
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: AppColors.bg,
        surfaceContainer: AppColors.surfaceAlt,
        surfaceContainerHigh: AppColors.surfaceHover,
        surfaceContainerHighest: AppColors.surfaceHover,
        outline: AppColors.border,
        outlineVariant: AppColors.borderSoft,
        surfaceTint: Colors.transparent,
      ),

      scaffoldBackgroundColor: AppColors.bg,
      canvasColor: AppColors.surface,
      cardColor: AppColors.surface,
      dialogBackgroundColor: AppColors.surface,

      // -------------------------------------------------
      // TYPOGRAPHY
      // -------------------------------------------------
      fontFamily: GoogleFonts.inter().fontFamily,

      textTheme: TextTheme(
        // DISPLAY
        displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 44,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: AppColors.text,
        ),
        displayMedium: GoogleFonts.plusJakartaSans(
          fontSize: 36,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
          color: AppColors.text,
        ),
        displaySmall: GoogleFonts.plusJakartaSans(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
          color: AppColors.text,
        ),

        // HEADINGS
        headlineLarge: GoogleFonts.plusJakartaSans(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
          color: AppColors.text,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: AppColors.text,
        ),
        headlineSmall: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.text,
        ),

        // TITLES
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.text,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.text,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.text,
        ),

        // BODY
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.text,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13.5,
          fontWeight: FontWeight.w400,
          color: AppColors.text,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),

        // LABELS
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.02,
          color: AppColors.text,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.04,
          color: AppColors.textSecondary,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.08,
          color: AppColors.textMuted,
        ),
      ),

      // -------------------------------------------------
      // APP BAR
      // -------------------------------------------------
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.text,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.text,
        ),
      ),

      // -------------------------------------------------
      // CARD
      // -------------------------------------------------
      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppMobileRadii.card,
          ),
          side: borderSide,
        ),
      ),

      // -------------------------------------------------
      // DIALOG
      // -------------------------------------------------
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: borderSide,
        ),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.text,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
      ),

      // -------------------------------------------------
      // BOTTOM SHEET
      // -------------------------------------------------
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        modalBackgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
      ),

      // -------------------------------------------------
      // POPUP MENU
      // -------------------------------------------------
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: borderSide,
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.text,
        ),
      ),

      // -------------------------------------------------
      // DROPDOWN MENU
      // -------------------------------------------------
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(AppColors.surface),
          surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.text,
        ),
      ),

      // -------------------------------------------------
      // DATA TABLE
      // -------------------------------------------------
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(AppColors.surfaceAlt),
        dataRowColor: WidgetStateProperty.all(AppColors.surface),
        headingTextStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: AppColors.textMuted,
        ),
        dataTextStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.text,
        ),
        dividerThickness: 1,
      ),

      // -------------------------------------------------
      // INPUTS
      // -------------------------------------------------
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppMobileRadii.input,
          ),
          borderSide: borderSide,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppMobileRadii.input,
          ),
          borderSide: borderSideStrong,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppMobileRadii.input,
          ),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppMobileRadii.input,
          ),
          borderSide: const BorderSide(
            color: AppColors.danger,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppMobileRadii.input,
          ),
          borderSide: const BorderSide(
            color: AppColors.danger,
            width: 2.0,
          ),
        ),
        hintStyle: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 14,
        ),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        prefixIconColor: AppColors.textMuted,
        suffixIconColor: AppColors.textMuted,
      ),

      // -------------------------------------------------
      // BUTTONS
      // -------------------------------------------------
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppMobileRadii.button,
            ),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          side: borderSideStrong,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppMobileRadii.button,
            ),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppMobileRadii.button,
            ),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppMobileRadii.button,
            ),
          ),
        ),
      ),

      // -------------------------------------------------
      // ICONS
      // -------------------------------------------------
      iconTheme: const IconThemeData(
        color: AppColors.text,
        size: 20,
      ),

      // -------------------------------------------------
      // CHIP
      // -------------------------------------------------
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceAlt,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppConstants.radiusFull,
          ),
        ),
      ),

      // -------------------------------------------------
      // DIVIDER
      // -------------------------------------------------
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      dividerColor: AppColors.border,

      // -------------------------------------------------
      // SNACKBAR
      // -------------------------------------------------
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkSurface,
        contentTextStyle: GoogleFonts.inter(
          color: AppColors.darkText,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
        actionTextColor: AppColors.primarySoft,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),

      // -------------------------------------------------
      // CHECKBOX & SWITCH
      // -------------------------------------------------
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : Colors.transparent,
        ),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: borderSideStrong,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primarySoft
              : AppColors.border,
        ),
      ),

      // -------------------------------------------------
      // LIST TILE
      // -------------------------------------------------
      listTileTheme: const ListTileThemeData(
        textColor: AppColors.text,
        iconColor: AppColors.textSecondary,
      ),

      // -------------------------------------------------
      // SPLASH REMOVAL
      // -------------------------------------------------
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
    );
  }

  // =====================================================
  // DARK THEME
  // =====================================================

  static ThemeData get dark {
    const borderSide = BorderSide(color: AppColors.darkBorder, width: 1.0);
    const borderSideStrong = BorderSide(color: AppColors.darkBorder, width: 1.5);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // -------------------------------------------------
      // COLOR SCHEME
      // -------------------------------------------------
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.accent,
        onSecondary: Colors.white,
        error: AppColors.danger,
        onError: Colors.white,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkText,
        surfaceContainerLowest: AppColors.darkBg,
        surfaceContainerLow: AppColors.darkBg,
        surfaceContainer: AppColors.darkSurfaceAlt,
        surfaceContainerHigh: AppColors.darkSurfaceHover,
        surfaceContainerHighest: AppColors.darkSurfaceHover,
        outline: AppColors.darkBorder,
        outlineVariant: AppColors.darkBorderSoft,
        surfaceTint: Colors.transparent,
      ),

      scaffoldBackgroundColor: AppColors.darkBg,
      canvasColor: AppColors.darkSurface,
      cardColor: AppColors.darkSurface,
      dialogBackgroundColor: AppColors.darkSurface,

      // -------------------------------------------------
      // TYPOGRAPHY
      // -------------------------------------------------
      fontFamily: GoogleFonts.inter().fontFamily,

      textTheme: TextTheme(
        // DISPLAY
        displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 44,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: AppColors.darkText,
        ),
        displayMedium: GoogleFonts.plusJakartaSans(
          fontSize: 36,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
          color: AppColors.darkText,
        ),
        displaySmall: GoogleFonts.plusJakartaSans(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
          color: AppColors.darkText,
        ),

        // HEADINGS
        headlineLarge: GoogleFonts.plusJakartaSans(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
          color: AppColors.darkText,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: AppColors.darkText,
        ),
        headlineSmall: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.darkText,
        ),

        // TITLES
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.darkText,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.darkText,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.darkText,
        ),

        // BODY
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.darkText,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13.5,
          fontWeight: FontWeight.w400,
          color: AppColors.darkText,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.darkTextSecondary,
        ),

        // LABELS
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.02,
          color: AppColors.darkText,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.04,
          color: AppColors.darkTextSecondary,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.08,
          color: AppColors.darkTextMuted,
        ),
      ),

      // -------------------------------------------------
      // APP BAR
      // -------------------------------------------------
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.darkText,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.darkText,
        ),
      ),

      // -------------------------------------------------
      // CARD
      // -------------------------------------------------
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppMobileRadii.card,
          ),
          side: borderSide,
        ),
      ),

      // -------------------------------------------------
      // DIALOG
      // -------------------------------------------------
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: borderSide,
        ),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.darkText,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.darkTextSecondary,
        ),
      ),

      // -------------------------------------------------
      // BOTTOM SHEET
      // -------------------------------------------------
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkSurface,
        modalBackgroundColor: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
      ),

      // -------------------------------------------------
      // POPUP MENU
      // -------------------------------------------------
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: borderSide,
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.darkText,
        ),
      ),

      // -------------------------------------------------
      // DROPDOWN MENU
      // -------------------------------------------------
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(AppColors.darkSurface),
          surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.darkText,
        ),
      ),

      // -------------------------------------------------
      // DATA TABLE
      // -------------------------------------------------
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(AppColors.darkSurfaceAlt),
        dataRowColor: WidgetStateProperty.all(AppColors.darkSurface),
        headingTextStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: AppColors.darkTextMuted,
        ),
        dataTextStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.darkText,
        ),
        dividerThickness: 1,
      ),

      // -------------------------------------------------
      // INPUTS
      // -------------------------------------------------
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppMobileRadii.input,
          ),
          borderSide: borderSide,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppMobileRadii.input,
          ),
          borderSide: borderSideStrong,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppMobileRadii.input,
          ),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppMobileRadii.input,
          ),
          borderSide: const BorderSide(
            color: AppColors.danger,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppMobileRadii.input,
          ),
          borderSide: const BorderSide(
            color: AppColors.danger,
            width: 2.0,
          ),
        ),
        hintStyle: const TextStyle(
          color: AppColors.darkTextMuted,
          fontSize: 14,
        ),
        labelStyle: const TextStyle(
          color: AppColors.darkTextSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        prefixIconColor: AppColors.darkTextMuted,
        suffixIconColor: AppColors.darkTextMuted,
      ),

      // -------------------------------------------------
      // BUTTONS
      // -------------------------------------------------
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppMobileRadii.button,
            ),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkText,
          side: borderSideStrong,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppMobileRadii.button,
            ),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppMobileRadii.button,
            ),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppMobileRadii.button,
            ),
          ),
        ),
      ),

      // -------------------------------------------------
      // ICONS
      // -------------------------------------------------
      iconTheme: const IconThemeData(
        color: AppColors.darkText,
        size: 20,
      ),

      // -------------------------------------------------
      // CHIP
      // -------------------------------------------------
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSurfaceAlt,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppConstants.radiusFull,
          ),
        ),
      ),

      // -------------------------------------------------
      // DIVIDER
      // -------------------------------------------------
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
        space: 1,
      ),
      dividerColor: AppColors.darkBorder,

      // -------------------------------------------------
      // SNACKBAR
      // -------------------------------------------------
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surface,
        contentTextStyle: GoogleFonts.inter(
          color: AppColors.text,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
        actionTextColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),

      // -------------------------------------------------
      // CHECKBOX & SWITCH
      // -------------------------------------------------
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : Colors.transparent,
        ),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: borderSideStrong,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.darkTextMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary.withValues(alpha: 0.4)
              : AppColors.darkBorder,
        ),
      ),

      // -------------------------------------------------
      // LIST TILE
      // -------------------------------------------------
      listTileTheme: const ListTileThemeData(
        textColor: AppColors.darkText,
        iconColor: AppColors.darkTextSecondary,
      ),

      // -------------------------------------------------
      // SPLASH REMOVAL
      // -------------------------------------------------
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
    );
  }
}