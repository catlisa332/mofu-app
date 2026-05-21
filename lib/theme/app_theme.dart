import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MofuColors {
  // 暖色系・癒しカラーパレット
  static const cream = Color(0xFFFFF8F0);
  static const softPeach = Color(0xFFFFE8D6);
  static const warmTan = Color(0xFFD4A98A);
  static const softBrown = Color(0xFF8B6355);
  static const mossGreen = Color(0xFF7A9E7E);
  static const softLavender = Color(0xFFD4C5E2);
  static const nightBlue = Color(0xFF2C3E50);
  static const textDark = Color(0xFF3D2B1F);
  static const textLight = Color(0xFF8B7355);
  static const divider = Color(0xFFEDD9C0);

  // Calm Scoreカラー
  static const calmHigh = Color(0xFF7A9E7E);
  static const calmMid = Color(0xFFD4A98A);
  static const calmLow = Color(0xFFE07B5A);
}

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.light(
          primary: MofuColors.warmTan,
          secondary: MofuColors.mossGreen,
          surface: MofuColors.cream,
          onSurface: MofuColors.textDark,
        ),
        scaffoldBackgroundColor: MofuColors.cream,
        textTheme: GoogleFonts.notoSansJpTextTheme().copyWith(
          displayLarge: GoogleFonts.notoSansJp(
            fontSize: 28,
            fontWeight: FontWeight.w300,
            color: MofuColors.textDark,
          ),
          bodyLarge: GoogleFonts.notoSansJp(
            fontSize: 16,
            color: MofuColors.textDark,
          ),
          bodyMedium: GoogleFonts.notoSansJp(
            fontSize: 14,
            color: MofuColors.textLight,
          ),
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: MofuColors.warmTan,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(30)),
            ),
            elevation: 0,
          ),
        ),
      );

  static ThemeData get night => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.dark(
          primary: MofuColors.softPeach,
          secondary: MofuColors.mossGreen,
          surface: MofuColors.nightBlue,
          onSurface: const Color(0xFFEEE0D0),
        ),
        scaffoldBackgroundColor: MofuColors.nightBlue,
      );
}
