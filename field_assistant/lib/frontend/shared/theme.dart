import 'package:flutter/material.dart';

/// Warm and earthy: cream "paper" background, white cards with hairline borders,
/// forest green for the brand, coffee-cherry for the leaf photo and amber for
/// "check with a person". Fraunces (serif) for headings, Inter for everything
/// else; both are bundled in assets/fonts so the app looks the same offline.
/// Large touch targets and high contrast for outdoor light.
abstract final class AppTheme {
  static const display = 'Fraunces';
  static const body = 'Inter';

  static ThemeData light() => _build(_light);
  static ThemeData dark() => _build(_dark);

  static const _light = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF2D5A3D),
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFDCEADB),
    onPrimaryContainer: Color(0xFF12301C),
    secondary: Color(0xFF9C4A32),
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFF6E3D9),
    onSecondaryContainer: Color(0xFF4A1D10),
    tertiary: Color(0xFF9A6200),
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFFBEBC8),
    onTertiaryContainer: Color(0xFF3D2800),
    error: Color(0xFFB3261E),
    onError: Colors.white,
    errorContainer: Color(0xFFF9DEDC),
    onErrorContainer: Color(0xFF410E0B),
    surface: Color(0xFFF7F4EC),
    onSurface: Color(0xFF1E1C18),
    onSurfaceVariant: Color(0xFF6B665C),
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: Colors.white,
    surfaceContainer: Color(0xFFF1EDE3),
    surfaceContainerHigh: Color(0xFFEBE6DA),
    surfaceContainerHighest: Color(0xFFE6E0D2),
    outline: Color(0xFFCBC3B2),
    outlineVariant: Color(0xFFE5DFD1),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: Color(0xFF2E2B26),
    onInverseSurface: Color(0xFFF5F1E8),
    inversePrimary: Color(0xFFA5CFA9),
    surfaceTint: Colors.transparent,
  );

  static const _dark = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF9CCB9F),
    onPrimary: Color(0xFF0F2A17),
    primaryContainer: Color(0xFF23432D),
    onPrimaryContainer: Color(0xFFCDE8CF),
    secondary: Color(0xFFE9A88F),
    onSecondary: Color(0xFF4A1D10),
    secondaryContainer: Color(0xFF5E2A1B),
    onSecondaryContainer: Color(0xFFF8DCD0),
    tertiary: Color(0xFFF0C36A),
    onTertiary: Color(0xFF3D2800),
    tertiaryContainer: Color(0xFF4F3A0E),
    onTertiaryContainer: Color(0xFFFBE6B8),
    error: Color(0xFFF2B8B5),
    onError: Color(0xFF601410),
    errorContainer: Color(0xFF8C1D18),
    onErrorContainer: Color(0xFFF9DEDC),
    surface: Color(0xFF171613),
    onSurface: Color(0xFFECE7DC),
    onSurfaceVariant: Color(0xFFA8A193),
    surfaceContainerLowest: Color(0xFF121110),
    surfaceContainerLow: Color(0xFF201F1B),
    surfaceContainer: Color(0xFF252420),
    surfaceContainerHigh: Color(0xFF2C2A25),
    surfaceContainerHighest: Color(0xFF34322C),
    outline: Color(0xFF57534A),
    outlineVariant: Color(0xFF38352F),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: Color(0xFFECE7DC),
    onInverseSurface: Color(0xFF2E2B26),
    inversePrimary: Color(0xFF2D5A3D),
    surfaceTint: Colors.transparent,
  );

  static TextTheme _text(ColorScheme c) {
    final base = Typography.material2021(platform: TargetPlatform.android).black.apply(
          fontFamily: body,
          bodyColor: c.onSurface,
          displayColor: c.onSurface,
        );
    TextStyle? serif(TextStyle? s, {double? size, FontWeight weight = FontWeight.w500}) =>
        s?.copyWith(fontFamily: display, fontSize: size, fontWeight: weight, letterSpacing: -0.3, height: 1.2);
    return base.copyWith(
      displaySmall: serif(base.displaySmall, size: 34),
      headlineLarge: serif(base.headlineLarge, size: 30),
      headlineMedium: serif(base.headlineMedium, size: 27),
      headlineSmall: serif(base.headlineSmall, size: 24),
      titleLarge: serif(base.titleLarge, size: 22, weight: FontWeight.w600),
      titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0),
      titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0),
      bodyLarge: base.bodyLarge?.copyWith(fontSize: 16, height: 1.45, letterSpacing: 0),
      bodyMedium: base.bodyMedium?.copyWith(fontSize: 14.5, height: 1.4, letterSpacing: 0),
      bodySmall: base.bodySmall?.copyWith(fontSize: 12.5, height: 1.35, letterSpacing: 0, color: c.onSurfaceVariant),
      labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0),
      labelMedium: base.labelMedium?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.1),
      labelSmall: base.labelSmall?.copyWith(fontWeight: FontWeight.w500, letterSpacing: 0.2),
    );
  }

  static ThemeData _build(ColorScheme c) {
    final text = _text(c);
    final hairline = BorderSide(color: c.outlineVariant);
    return ThemeData(
      colorScheme: c,
      useMaterial3: true,
      fontFamily: body,
      textTheme: text,
      scaffoldBackgroundColor: c.surface,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      splashFactory: InkSparkle.splashFactory,
      dividerTheme: DividerThemeData(color: c.outlineVariant, space: 1, thickness: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: c.surface,
        foregroundColor: c.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 72,
        indicatorColor: c.primaryContainer,
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              fontFamily: body,
              fontSize: 12,
              fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
              color: states.contains(WidgetState.selected) ? c.onSurface : c.onSurfaceVariant,
            )),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              size: 24,
              color: states.contains(WidgetState.selected) ? c.onPrimaryContainer : c.onSurfaceVariant,
            )),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: c.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: hairline),
        margin: EdgeInsets.zero,
      ),
      listTileTheme: ListTileThemeData(iconColor: c.primary, titleTextStyle: text.bodyLarge),
      chipTheme: ChipThemeData(
        backgroundColor: c.surfaceContainerLowest,
        selectedColor: c.primaryContainer,
        side: hairline,
        shape: const StadiumBorder(),
        labelStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: c.primary,
        unselectedLabelColor: c.onSurfaceVariant,
        indicatorColor: c.primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: c.outlineVariant,
        labelStyle: text.labelLarge,
        unselectedLabelStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w500),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: hairline),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: hairline),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: text.labelLarge?.copyWith(fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 44),
          foregroundColor: c.onSurface,
          side: BorderSide(color: c.outline),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: c.primary, textStyle: text.labelLarge),
      ),
      badgeTheme: BadgeThemeData(backgroundColor: c.secondary, textColor: c.onSecondary),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(color: c.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titleTextStyle: text.titleLarge,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.primary),
    );
  }
}
