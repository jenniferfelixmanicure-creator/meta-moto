import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta baseada na logo: preto profundo + vermelho sangue + prata/branco
class AppColors {
  // Backgrounds
  static const Color background   = Color(0xFF0A0A0A);
  static const Color surface      = Color(0xFF141414);
  static const Color cardBg       = Color(0xFF1A1A1A);
  static const Color surfaceLight = Color(0xFF222222);

  // Primária — vermelho da logo
  static const Color primary      = Color(0xFFD10000);
  static const Color primaryDark  = Color(0xFF9A0000);
  static const Color primaryLight = Color(0xFFFF2222);
  static const Color primaryGlow  = Color(0x44D10000);

  // Acentos
  static const Color silver       = Color(0xFFD4D4D4);
  static const Color silverDim    = Color(0xFF888888);
  static const Color white        = Color(0xFFFFFFFF);
  static const Color accent       = Color(0xFF7B61FF); // roxo/violeta para meta mensal

  // Textos
  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFBBBBBB);
  static const Color textMuted     = Color(0xFF666666);

  // Semânticas
  static const Color success  = Color(0xFF2ECC71);
  static const Color warning  = Color(0xFFF39C12);
  static const Color error    = Color(0xFFE74C3C);
  static const Color info     = Color(0xFF3498DB);

  // Plataformas
  static const Color uber     = Color(0xFF1A1A1A);
  static const Color n99      = Color(0xFFFFCC00);
  static const Color ifood    = Color(0xFFEA1D2C);
  static const Color lalamove = Color(0xFFFF6600);
  static const Color indrive  = Color(0xFF00C853);
}

class AppTheme {
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary:    AppColors.primary,
        secondary:  AppColors.silver,
        surface:    AppColors.surface,
        onPrimary:  AppColors.white,
        onSecondary: AppColors.background,
        onSurface:  AppColors.textPrimary,
        error:      AppColors.error,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.inter(
          color: AppColors.textPrimary, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1),
        displayMedium: GoogleFonts.inter(
          color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.5),
        titleLarge: GoogleFonts.inter(
          color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700),
        titleMedium: GoogleFonts.inter(
          color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.inter(
          color: AppColors.textPrimary, fontSize: 16),
        bodyMedium: GoogleFonts.inter(
          color: AppColors.textSecondary, fontSize: 14),
        bodySmall: GoogleFonts.inter(
          color: AppColors.textMuted, fontSize: 12),
        labelSmall: GoogleFonts.inter(
          color: AppColors.textMuted, fontSize: 10, letterSpacing: 0.5),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700),
        iconTheme: const IconThemeData(color: AppColors.textSecondary),
      ),
      cardTheme: CardTheme(
        color: AppColors.cardBg,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 0,
          shadowColor: AppColors.primaryGlow,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2A2A2A), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
        hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 6,
        shape: StadiumBorder(),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerColor: AppColors.surfaceLight,
      dividerTheme: const DividerThemeData(
        color: AppColors.surfaceLight,
        space: 1,
        thickness: 1,
      ),
      iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 22),
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.inter(
          color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.cardBg,
        contentTextStyle: GoogleFonts.inter(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        circularTrackColor: AppColors.surfaceLight,
        linearTrackColor: AppColors.surfaceLight,
      ),
      tabBarTheme: TabBarTheme(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textMuted,
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
        unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.primary : AppColors.textMuted),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.primaryGlow : AppColors.surfaceLight),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.primary : Colors.transparent),
        side: const BorderSide(color: AppColors.textMuted, width: 1.5),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
      ),
    );
  }
}

/// Componentes visuais reutilizáveis
class AppDecorations {
  static BoxDecoration redCard({double radius = 16}) => BoxDecoration(
    color: AppColors.cardBg,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1),
  );

  static BoxDecoration heroCard({double radius = 20}) => BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF2A0000), Color(0xFF0A0A0A)],
    ),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: AppColors.primary.withOpacity(0.35), width: 1.5),
    boxShadow: [
      BoxShadow(
        color: AppColors.primary.withOpacity(0.1),
        blurRadius: 20,
        spreadRadius: 0,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1A0000), Color(0xFF0A0A0A)],
  );
}
