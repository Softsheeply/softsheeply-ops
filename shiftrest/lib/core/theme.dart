import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primary = Color(0xFF3D5AFE);
  static const Color accent = Color(0xFFFFAB40);
  static const Color success = Color(0xFF69F0AE);
  static const Color warning = Color(0xFFFF6D00);
  static const Color nightPurple = Color(0xFF7C4DFF);
  static const Color background = Color(0xFF080C14);
  static const Color surface = Color(0xFF111827);
  static const Color surfaceVariant = Color(0xFF1C2333);
  static const Color text = Color(0xFFE8EAF6);
  static const Color textSecondary = Color(0xFF8892A4);

  static const Color dayShift = Color(0xFFFFAB40);
  static const Color afternoonShift = Color(0xFFFF6D00);
  static const Color nightShift = Color(0xFF7C4DFF);
  static const Color rotatingShift = Color(0xFF00BCD4);
  static const Color dayOff = Color(0xFF69F0AE);

  static Color shiftColor(String shiftType) {
    switch (shiftType) {
      case 'day':
        return dayShift;
      case 'afternoon':
        return afternoonShift;
      case 'night':
        return nightShift;
      case 'rotating':
        return rotatingShift;
      case 'off':
        return dayOff;
      default:
        return textSecondary;
    }
  }
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.warning,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: AppColors.text,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.sora(
          color: AppColors.text,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: AppColors.text),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.sora(
          color: AppColors.text,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: GoogleFonts.sora(
          color: AppColors.text,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: GoogleFonts.sora(
          color: AppColors.text,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        headlineLarge: GoogleFonts.sora(
          color: AppColors.text,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: GoogleFonts.sora(
          color: AppColors.text,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: GoogleFonts.sora(
          color: AppColors.text,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.nunito(
          color: AppColors.text,
          fontSize: 16,
        ),
        bodyMedium: GoogleFonts.nunito(
          color: AppColors.text,
          fontSize: 14,
        ),
        bodySmall: GoogleFonts.nunito(
          color: AppColors.textSecondary,
          fontSize: 12,
        ),
        labelLarge: GoogleFonts.nunito(
          color: AppColors.text,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.surfaceVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        labelStyle: GoogleFonts.nunito(color: AppColors.textSecondary),
        hintStyle: GoogleFonts.nunito(color: AppColors.textSecondary),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.surfaceVariant,
        thumbColor: AppColors.primary,
        overlayColor: Color(0x293D5AFE),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary.withOpacity(0.5);
          }
          return AppColors.surfaceVariant;
        }),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.surfaceVariant,
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        selectedColor: AppColors.primary.withOpacity(0.3),
        labelStyle: GoogleFonts.nunito(color: AppColors.text, fontSize: 13),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF0F2F5),
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: Colors.white,
        onSurface: Color(0xFF1A1A2E),
      ),
    );
  }
}
