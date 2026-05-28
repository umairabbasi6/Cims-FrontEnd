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

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,

        // -------------------------------------------------
        // COLORS
        // -------------------------------------------------

        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.accent,
          error: AppColors.danger,
          surface: AppColors.surface,
        ),

        scaffoldBackgroundColor: AppColors.bg,

        // -------------------------------------------------
        // TYPOGRAPHY
        // -------------------------------------------------

        fontFamily: GoogleFonts.inter().fontFamily,

        textTheme: TextTheme(
          // HEADINGS
          headlineLarge: GoogleFonts.plusJakartaSans(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),

          headlineMedium: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),

          headlineSmall: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),

          // BODY
          bodyLarge: GoogleFonts.inter(
            fontSize: 16,
            color: AppColors.text,
          ),

          bodyMedium: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),

          bodySmall: GoogleFonts.inter(
            fontSize: 12,
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
          elevation: 0,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppMobileRadii.card,
            ),

            side: const BorderSide(
              color: AppColors.border,
            ),
          ),
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

            borderSide: const BorderSide(
              color: AppColors.border,
            ),
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              AppMobileRadii.input,
            ),

            borderSide: const BorderSide(
              color: AppColors.border,
              width: 1.5,
            ),
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

          hintStyle: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 16,
          ),

          labelStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
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

            side: const BorderSide(
              color: AppColors.border,
              width: 1.5,
            ),

            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                AppMobileRadii.button,
              ),
            ),
          ),
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
          space: 0,
        ),

        dividerColor: AppColors.border,

        // -------------------------------------------------
        // SPLASH REMOVAL
        // -------------------------------------------------

        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
      );

  // =====================================================
  // DARK THEME
  // =====================================================

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,

        // -------------------------------------------------
        // COLORS
        // -------------------------------------------------

        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.accent,
          error: AppColors.danger,
          surface: AppColors.darkSurface,
        ),

        scaffoldBackgroundColor: AppColors.darkBg,

        // -------------------------------------------------
        // TYPOGRAPHY
        // -------------------------------------------------

        fontFamily: GoogleFonts.inter().fontFamily,

        textTheme: TextTheme(
          // HEADINGS
          headlineLarge: GoogleFonts.plusJakartaSans(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: AppColors.darkText,
          ),

          headlineMedium: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.darkText,
          ),

          headlineSmall: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.darkText,
          ),

          // BODY
          bodyLarge: GoogleFonts.inter(
            fontSize: 16,
            color: AppColors.darkText,
          ),

          bodyMedium: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.darkTextSecondary,
          ),

          bodySmall: GoogleFonts.inter(
            fontSize: 12,
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
          elevation: 0,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppMobileRadii.card,
            ),

            side: const BorderSide(
              color: AppColors.darkBorder,
            ),
          ),
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

            borderSide: const BorderSide(
              color: AppColors.darkBorder,
            ),
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              AppMobileRadii.input,
            ),

            borderSide: const BorderSide(
              color: AppColors.darkBorder,
              width: 1.5,
            ),
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

          hintStyle: const TextStyle(
            color: AppColors.darkTextMuted,
            fontSize: 16,
          ),
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

        // -------------------------------------------------
        // DIVIDER
        // -------------------------------------------------

        dividerTheme: const DividerThemeData(
          color: AppColors.darkBorder,
          thickness: 1,
          space: 0,
        ),

        dividerColor: AppColors.darkBorder,

        // -------------------------------------------------
        // SPLASH REMOVAL
        // -------------------------------------------------

        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
      );
}