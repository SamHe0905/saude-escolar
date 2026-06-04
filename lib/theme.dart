import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta institucional — derivada da logo Saúde Escolar (navy + verde).
class AppColors {
  static const navy = Color(0xFF15396B);
  static const navyHover = Color(0xFF0F2C55);
  static const navySoft = Color(0xFFEAF1FA);
  static const green = Color(0xFF1E9E4A);
  static const greenDark = Color(0xFF18843E);
  static const greenSoft = Color(0xFFE7F5EC);
  static const amber = Color(0xFFB07419);
  static const amberSoft = Color(0xFFFBF1DE);
  static const bg = Color(0xFFF3F5F9);
  static const surface = Colors.white;
  static const border = Color(0xFFE6E9F0);
  static const borderStrong = Color(0xFFD7DCE6);
  static const text = Color(0xFF18202E);
  static const textMuted = Color(0xFF647089);
  static const textFaint = Color(0xFF939CB0);
  static const danger = Color(0xFFC23A33);
  static const dangerSoft = Color(0xFFFBEAE9);
}

class AppShadows {
  static const card = [
    BoxShadow(color: Color(0x0F17306B), blurRadius: 18, offset: Offset(0, 6)),
    BoxShadow(color: Color(0x0A000000), blurRadius: 2, offset: Offset(0, 1)),
  ];
  static const soft = [
    BoxShadow(color: Color(0x0A17306B), blurRadius: 10, offset: Offset(0, 3)),
  ];
  static const float = [
    BoxShadow(color: Color(0x2117306B), blurRadius: 28, offset: Offset(0, 12)),
  ];
}

const double kBreakpoint = 880;
const double kSidebarWidth = 250;

ThemeData buildAppTheme() {
  final base = ThemeData(useMaterial3: true);
  final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
    bodyColor: AppColors.text,
    displayColor: AppColors.text,
  );

  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: c, width: w),
      );

  return base.copyWith(
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.navy,
      primary: AppColors.navy,
      surface: AppColors.surface,
    ),
    scaffoldBackgroundColor: AppColors.bg,
    textTheme: textTheme,
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: border(AppColors.border),
      enabledBorder: border(AppColors.border),
      focusedBorder: border(AppColors.navy, 1.6),
      errorBorder: border(AppColors.danger),
      focusedErrorBorder: border(AppColors.danger, 1.6),
      hintStyle: const TextStyle(color: AppColors.textFaint, fontSize: 14),
      labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
      prefixIconColor: AppColors.textFaint,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14.5),
      ).copyWith(
        overlayColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.12)),
        backgroundColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.hovered) ? AppColors.navyHover : AppColors.navy),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.text,
        backgroundColor: AppColors.surface,
        side: const BorderSide(color: AppColors.borderStrong),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
      ).copyWith(
        overlayColor: WidgetStateProperty.all(AppColors.navySoft),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.navy,
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: AppColors.textMuted),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.text,
      contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 13.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    progressIndicatorTheme:
        const ProgressIndicatorThemeData(color: AppColors.navy),
  );
}

// ---------------------------------------------------------------------------
// Tipografia auxiliar
// ---------------------------------------------------------------------------
TextStyle display() => GoogleFonts.inter(
    fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.text, letterSpacing: -0.5);
TextStyle title() => GoogleFonts.inter(
    fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text, letterSpacing: -0.2);
TextStyle sectionTitle() => GoogleFonts.inter(
    fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text);
TextStyle overline() => const TextStyle(
    fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.7);
TextStyle bodyMuted() => const TextStyle(fontSize: 13.5, color: AppColors.textMuted, height: 1.4);
