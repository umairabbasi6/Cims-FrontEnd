import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────
  static const primary     = Color(0xFF1463FF);
  static const primaryDark = Color(0xFF0B4CD9);
  static const primarySoft = Color(0xFFEAF1FF);

  static const accent      = Color(0xFF0F9F9A);
  static const accentSoft  = Color(0xFFE7F8F6);

  // ── Semantic ───────────────────────────────────────
  static const success     = Color(0xFF19A463);
  static const successSoft = Color(0xFFE8F7EF);

  static const warning     = Color(0xFFF59E0B);
  static const warningSoft = Color(0xFFFFF4DF);

  static const danger      = Color(0xFFDC3545);
  static const dangerSoft  = Color(0xFFFDECEF);

  static const purple      = Color(0xFF7C5CFF);
  static const purpleSoft  = Color(0xFFEFEAFF);

  static const pink        = Color(0xFFEC4899);
  static const pinkSoft    = Color(0xFFFCE7F3);

  static const info        = Color(0xFF3B82F6);
  static const infoSoft    = Color(0xFFEFF6FF);

  // ── Light Surface ──────────────────────────────────
  static const bg           = Color(0xFFF6F8FB);
  static const surface      = Color(0xFFFFFFFF);
  static const surfaceAlt   = Color(0xFFFAFBFD);
  static const surfaceHover = Color(0xFFF3F6FB);
  static const border       = Color(0xFFE5EAF1);
  static const borderSoft   = Color(0xFFEEF2F7);

  static const text          = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF475569);
  static const textMuted     = Color(0xFF94A3B8);

  static const sidebarBg    = Color(0xFFFFFFFF);
  static const sidebarFg    = Color(0xFF334155);
  static const sidebarMuted = Color(0xFF94A3B8);

  // ── Dark Surface ───────────────────────────────────
  static const darkBg           = Color(0xFF06080F);
  static const darkSurface      = Color(0xFF0F172A);
  static const darkSurfaceAlt   = Color(0xFF131C30);
  static const darkSurfaceHover = Color(0xFF182238);
  static const darkBorder       = Color(0xFF1F2A44);
  static const darkBorderSoft   = Color(0xFF182238);

  static const darkText          = Color(0xFFF1F5F9);
  static const darkTextSecondary = Color(0xFFCBD5E1);
  static const darkTextMuted     = Color(0xFF64748B);

  static const darkSidebarBg    = Color(0xFF0A1020);
  static const darkSidebarFg    = Color(0xFFCBD5E1);
  static const darkSidebarMuted = Color(0xFF64748B);

  // ── Gradients ──────────────────────────────────────
  static const gradientPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, accent],
  );
  static const gradientAccent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [purple, primary],
  );
  static const gradientWarm = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [warning, pink],
  );

  // ── Role Colors ────────────────────────────────────
  static Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':    return success;
      case 'inactive':  return textMuted;
      case 'suspended': return danger;
      case 'on leave':  return warning;
      case 'current':   return success;
      case 'closed':    return textMuted;
      case 'paid':      return success;
      case 'overdue':   return danger;
      default:          return textMuted;
    }
  }

  static Color statusBg(String status) {
    switch (status.toLowerCase()) {
      case 'active':    return successSoft;
      case 'inactive':  return surfaceHover;
      case 'suspended': return dangerSoft;
      case 'on leave':  return warningSoft;
      case 'current':   return successSoft;
      case 'closed':    return surfaceHover;
      case 'paid':      return successSoft;
      case 'overdue':   return dangerSoft;
      default:          return surfaceHover;
    }
  }
}