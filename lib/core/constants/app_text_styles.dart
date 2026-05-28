import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cims/core/constants/app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get displayFont => GoogleFonts.plusJakartaSans();
  static TextStyle get bodyFont    => GoogleFonts.inter();

  // ── Display ────────────────────────────────────────
  static TextStyle display = GoogleFonts.plusJakartaSans(
    fontSize: 44, fontWeight: FontWeight.w800, letterSpacing: -0.5,
  );
  static TextStyle h1 = GoogleFonts.plusJakartaSans(
    fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.3,
  );
  static TextStyle h2 = GoogleFonts.plusJakartaSans(
    fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.2,
  );
  static TextStyle h3 = GoogleFonts.plusJakartaSans(
    fontSize: 16, fontWeight: FontWeight.w700,
  );
  static TextStyle h4 = GoogleFonts.plusJakartaSans(
    fontSize: 14, fontWeight: FontWeight.w700,
  );

  // ── Body ───────────────────────────────────────────
  static TextStyle bodyLg = GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400);
  static TextStyle body   = GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400);
  static TextStyle bodySm = GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400);
  static TextStyle caption = GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400);

  // ── Label ──────────────────────────────────────────
  static TextStyle labelLg = GoogleFonts.inter(
    fontSize: 13, fontWeight: FontWeight.w700,
    letterSpacing: 0.04, color: AppColors.textSecondary,
  );
  static TextStyle label = GoogleFonts.inter(
    fontSize: 12, fontWeight: FontWeight.w700,
    letterSpacing: 0.04, color: AppColors.textSecondary,
  );
  static TextStyle labelSm = GoogleFonts.inter(
    fontSize: 11, fontWeight: FontWeight.w700,
    letterSpacing: 0.08, color: AppColors.textMuted,
  );

  // ── Stat ───────────────────────────────────────────
  static TextStyle statValue = GoogleFonts.plusJakartaSans(
    fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5,
  );
  static TextStyle statValueSm = GoogleFonts.plusJakartaSans(
    fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.3,
  );
}