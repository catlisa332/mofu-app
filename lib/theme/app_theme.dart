import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Apple Human Interface Guidelines に準じた カラーシステム
class MofuColors {
  // ─── System Backgrounds ───────────────────────────────────
  static const systemBackground          = Color(0xFFFAF8F5); // warm white
  static const secondarySystemBackground = Color(0xFFF2EDE8);
  static const cardBackground            = Color(0xFFFFFFFF);

  // ─── Labels ───────────────────────────────────────────────
  static const label          = Color(0xFF1C1C1E); // primary
  static const secondaryLabel = Color(0xFF6C6C70); // secondary
  static const tertiaryLabel  = Color(0xFFAEAEB2); // tertiary

  // ─── Separators ───────────────────────────────────────────
  static const separator      = Color(0xFFE8E3DF);
  static const opaqueSeparator = Color(0xFFC6C0BB);

  // ─── Accent（温かみのある Apple-like トーン）─────────────────
  static const accent         = Color(0xFFBF8B67); // refined warm brown
  static const accentSoft     = Color(0xFFF5EDE5); // very light accent fill

  // ─── Semantic Colors（iOS system colors）────────────────────
  static const systemGreen    = Color(0xFF34C759);
  static const systemOrange   = Color(0xFFFF9F0A);
  static const systemRed      = Color(0xFFFF3B30);
  static const systemBlue     = Color(0xFF007AFF);
  static const systemPurple   = Color(0xFFAF52DE);

  // ─── Legacy aliases（既存コードとの互換）────────────────────
  static const cream          = systemBackground;
  static const softPeach      = accentSoft;
  static const warmTan        = accent;
  static const softBrown      = label;
  static const mossGreen      = systemGreen;
  static const softLavender   = Color(0xFFD4C5E2);
  static const nightBlue      = Color(0xFF1C1C1E);
  static const textDark       = label;
  static const textLight      = secondaryLabel;
  static const divider        = separator;
  static const calmHigh       = systemGreen;
  static const calmMid        = systemOrange;
  static const calmLow        = systemRed;
}

class AppTheme {
  static ThemeData get light {
    final base = GoogleFonts.notoSansJpTextTheme();
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary:   MofuColors.accent,
        secondary: MofuColors.systemGreen,
        surface:   MofuColors.systemBackground,
        onSurface: MofuColors.label,
        outline:   MofuColors.separator,
      ),
      scaffoldBackgroundColor: MofuColors.systemBackground,

      // ─── Typography ─────────────────────────────────────────
      textTheme: base.copyWith(
        // Large Title  34pt · Bold
        displayLarge: GoogleFonts.notoSansJp(
          fontSize: 34, fontWeight: FontWeight.w700,
          color: MofuColors.label, letterSpacing: -0.5,
        ),
        // Title 1  28pt · Bold
        displayMedium: GoogleFonts.notoSansJp(
          fontSize: 28, fontWeight: FontWeight.w700,
          color: MofuColors.label, letterSpacing: -0.3,
        ),
        // Title 2  22pt · Bold
        displaySmall: GoogleFonts.notoSansJp(
          fontSize: 22, fontWeight: FontWeight.w700,
          color: MofuColors.label,
        ),
        // Headline  17pt · Semibold
        headlineMedium: GoogleFonts.notoSansJp(
          fontSize: 17, fontWeight: FontWeight.w600,
          color: MofuColors.label,
        ),
        // Body  17pt · Regular
        bodyLarge: GoogleFonts.notoSansJp(
          fontSize: 17, fontWeight: FontWeight.w400,
          color: MofuColors.label,
        ),
        // Callout  16pt · Regular
        bodyMedium: GoogleFonts.notoSansJp(
          fontSize: 16, fontWeight: FontWeight.w400,
          color: MofuColors.label,
        ),
        // Subhead  15pt · Regular
        bodySmall: GoogleFonts.notoSansJp(
          fontSize: 15, fontWeight: FontWeight.w400,
          color: MofuColors.secondaryLabel,
        ),
        // Caption  12pt · Regular
        labelSmall: GoogleFonts.notoSansJp(
          fontSize: 12, fontWeight: FontWeight.w400,
          color: MofuColors.tertiaryLabel,
        ),
      ),

      // ─── AppBar ──────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: MofuColors.systemBackground,
        foregroundColor: MofuColors.label,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: MofuColors.separator,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),

      // ─── Card ────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: MofuColors.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      // ─── ElevatedButton ──────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: MofuColors.accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
          elevation: 0,
          textStyle: GoogleFonts.notoSansJp(
            fontSize: 17, fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ─── BottomNavigationBar ─────────────────────────────────
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: MofuColors.accent,
        unselectedItemColor: MofuColors.tertiaryLabel,
        selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
        unselectedLabelStyle: TextStyle(fontSize: 10),
        elevation: 0,
      ),

      // ─── Divider ─────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: MofuColors.separator,
        thickness: 0.5,
        space: 0,
      ),

      // ─── SnackBar ────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: MofuColors.label,
        contentTextStyle: GoogleFonts.notoSansJp(
          color: Colors.white, fontSize: 14,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData get night {
    // 温かみのある深いブラウン系ナイトパレット
    const bg     = Color(0xFF1E1A16); // 最も暗い背景
    const cardBg = Color(0xFF2D2620); // カード背景（少し明るい）
    const text1  = Color(0xFFEDD9C5); // プライマリテキスト（ウォームクリーム）
    const text2  = Color(0xFFAB8E7A); // セカンダリテキスト（ミュートなウォーム）
    const border = Color(0xFF4A3D32); // ボーダー・区切り線

    final base = GoogleFonts.notoSansJpTextTheme();
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary:   MofuColors.accent,
        secondary: MofuColors.systemGreen,
        surface:   bg,
        onSurface: text1,
        outline:   border,
      ),
      scaffoldBackgroundColor: bg,

      // ─── Typography（ライトと同じ構造、夜色で上書き）────────────
      textTheme: base.copyWith(
        displayLarge:   GoogleFonts.notoSansJp(fontSize: 34, fontWeight: FontWeight.w700, color: text1, letterSpacing: -0.5),
        displayMedium:  GoogleFonts.notoSansJp(fontSize: 28, fontWeight: FontWeight.w700, color: text1, letterSpacing: -0.3),
        displaySmall:   GoogleFonts.notoSansJp(fontSize: 22, fontWeight: FontWeight.w700, color: text1),
        headlineMedium: GoogleFonts.notoSansJp(fontSize: 17, fontWeight: FontWeight.w600, color: text1),
        bodyLarge:      GoogleFonts.notoSansJp(fontSize: 17, fontWeight: FontWeight.w400, color: text1),
        bodyMedium:     GoogleFonts.notoSansJp(fontSize: 16, fontWeight: FontWeight.w400, color: text1),
        bodySmall:      GoogleFonts.notoSansJp(fontSize: 15, fontWeight: FontWeight.w400, color: text2),
        labelSmall:     GoogleFonts.notoSansJp(fontSize: 12, fontWeight: FontWeight.w400, color: text2),
      ),

      // ─── AppBar ──────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        foregroundColor: text1,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: border,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),

      // ─── Card ────────────────────────────────────────────────
      cardTheme: const CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      // ─── ListTile / SwitchListTile ───────────────────────────
      listTileTheme: const ListTileThemeData(
        tileColor: cardBg,
        textColor: text1,
        subtitleTextStyle: TextStyle(color: text2, fontSize: 13),
        iconColor: text2,
      ),

      // ─── ElevatedButton ──────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: MofuColors.accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
          elevation: 0,
          textStyle: GoogleFonts.notoSansJp(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),

      // ─── Divider ─────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 0.5,
        space: 0,
      ),

      // ─── SnackBar ────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardBg,
        contentTextStyle: GoogleFonts.notoSansJp(color: text1, fontSize: 14),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
