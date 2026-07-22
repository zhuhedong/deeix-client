import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_tokens.dart';

/// The "Graphite + Electric Indigo" theme.
///
/// Colors come from a hand-tuned [ColorScheme] (built on a seed, then every
/// neutral overridden for a true graphite ramp) plus the bespoke [AppTokens].
/// Type is the platform system face on a refined scale — tighter tracking and
/// heavier weights up top, comfortable line height in the body — so Chinese and
/// Latin both render natively with zero font downloads.
class AppTheme {
  AppTheme._();

  static const _radiusSm = 12.0;
  static const _radiusMd = 14.0;
  static const _radiusLg = 20.0;

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final scheme = isLight ? _lightScheme : _darkScheme;
    final tokens = isLight ? AppTokens.light : AppTokens.dark;
    final textTheme = _textTheme(scheme.onSurface, scheme.onSurfaceVariant);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,
      textTheme: textTheme,
      extensions: [tokens],
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleLarge,
        systemOverlayStyle: isLight
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
        actionsIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      ),
      dividerTheme: DividerThemeData(
        color: tokens.hairline,
        thickness: 1,
        space: 1,
      ),
      iconTheme: IconThemeData(color: scheme.onSurfaceVariant, size: 22),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight
            ? scheme.surfaceContainerLow
            : scheme.surfaceContainerHigh,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusMd),
          borderSide: BorderSide(color: tokens.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusMd),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusMd),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusMd),
          borderSide: BorderSide(color: scheme.error, width: 1.6),
        ),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusLg),
          side: BorderSide(color: tokens.hairline),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radiusMd),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size(0, 48),
          textStyle: textTheme.labelLarge,
          backgroundColor: scheme.surfaceContainerHigh,
          foregroundColor: scheme.onSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radiusMd),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          foregroundColor: scheme.onSurface,
          textStyle: textTheme.labelLarge,
          side: BorderSide(color: tokens.hairline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radiusMd),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radiusSm),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: scheme.onSurfaceVariant,
          highlightColor: tokens.softAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radiusSm),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        side: BorderSide(color: tokens.hairline),
        labelStyle: textTheme.labelMedium?.copyWith(color: scheme.onSurface),
        secondaryLabelStyle: textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusSm),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(textTheme.labelMedium),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return scheme.primary;
            return scheme.surfaceContainerLow;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return scheme.onPrimary;
            return scheme.onSurfaceVariant;
          }),
          side: WidgetStatePropertyAll(BorderSide(color: tokens.hairline)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_radiusSm),
            ),
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        titleTextStyle: textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusSm),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: scheme.surfaceContainerLowest,
        showDragHandle: true,
        dragHandleColor: tokens.hairline,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusLg),
          side: BorderSide(color: tokens.hairline),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        textStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusMd),
          side: BorderSide(color: tokens.hairline),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        actionTextColor: scheme.inversePrimary,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusSm),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusMd),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: textTheme.labelSmall?.copyWith(
          color: scheme.onInverseSurface,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.surfaceContainerHighest,
        thumbColor: scheme.primary,
        overlayColor: tokens.softAccent,
        trackHeight: 4,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return scheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return scheme.surfaceContainerHighest;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.transparent;
          return tokens.hairline;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        side: BorderSide(color: scheme.outline, width: 1.6),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return Colors.transparent;
        }),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        circularTrackColor: Colors.transparent,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: scheme.primary,
        selectionColor: scheme.primary.withValues(alpha: 0.24),
        selectionHandleColor: scheme.primary,
      ),
      expansionTileTheme: ExpansionTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        collapsedIconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
        collapsedTextColor: scheme.onSurface,
        tilePadding: EdgeInsets.zero,
        shape: const Border(),
        collapsedShape: const Border(),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thickness: const WidgetStatePropertyAll(6),
        radius: const Radius.circular(8),
        thumbColor: WidgetStatePropertyAll(
          scheme.outline.withValues(alpha: 0.6),
        ),
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: scheme.primary,
        textColor: scheme.onPrimary,
        textStyle: textTheme.labelSmall?.copyWith(color: scheme.onPrimary),
      ),
    );
  }

  /// System-font type scale: tight tracking + strong weight up top, relaxed
  /// leading in the body for long-form Markdown answers.
  static TextTheme _textTheme(Color ink, Color muted) {
    TextStyle s(
      double size,
      FontWeight weight,
      double spacing, {
      double height = 1.3,
      Color? color,
    }) => TextStyle(
      fontSize: size,
      fontWeight: weight,
      letterSpacing: spacing,
      height: height,
      color: color ?? ink,
    );

    return TextTheme(
      displayLarge: s(40, FontWeight.w700, -0.8, height: 1.1),
      displayMedium: s(34, FontWeight.w700, -0.6, height: 1.12),
      displaySmall: s(28, FontWeight.w700, -0.5, height: 1.15),
      headlineLarge: s(26, FontWeight.w700, -0.4, height: 1.2),
      headlineMedium: s(23, FontWeight.w700, -0.35, height: 1.2),
      headlineSmall: s(20, FontWeight.w700, -0.3, height: 1.25),
      titleLarge: s(19, FontWeight.w700, -0.25, height: 1.3),
      titleMedium: s(16, FontWeight.w600, -0.1, height: 1.35),
      titleSmall: s(14.5, FontWeight.w600, 0, height: 1.35),
      bodyLarge: s(15.5, FontWeight.w400, 0.1, height: 1.55),
      bodyMedium: s(14, FontWeight.w400, 0.1, height: 1.5),
      bodySmall: s(12.5, FontWeight.w400, 0.15, height: 1.45, color: muted),
      labelLarge: s(14, FontWeight.w600, 0.1, height: 1.2),
      labelMedium: s(12, FontWeight.w600, 0.2, height: 1.2),
      labelSmall: s(11, FontWeight.w500, 0.3, height: 1.2, color: muted),
    );
  }

  static final ColorScheme _lightScheme =
      ColorScheme.fromSeed(seedColor: const Color(0xFF5B5BF5)).copyWith(
        brightness: Brightness.light,
        primary: const Color(0xFF5B5BF5),
        onPrimary: Colors.white,
        primaryContainer: const Color(0xFFE4E4FD),
        onPrimaryContainer: const Color(0xFF21208A),
        secondary: const Color(0xFF585B87),
        onSecondary: Colors.white,
        secondaryContainer: const Color(0xFFE7E7F3),
        onSecondaryContainer: const Color(0xFF2B2D4E),
        tertiary: const Color(0xFF0E8A8F),
        onTertiary: Colors.white,
        tertiaryContainer: const Color(0xFFCFF3F1),
        onTertiaryContainer: const Color(0xFF04413F),
        error: const Color(0xFFDC2626),
        onError: Colors.white,
        errorContainer: const Color(0xFFFBE2E2),
        onErrorContainer: const Color(0xFF7A1616),
        surface: const Color(0xFFFBFBFD),
        onSurface: const Color(0xFF15171E),
        onSurfaceVariant: const Color(0xFF585E6E),
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: const Color(0xFFF5F6F9),
        surfaceContainer: const Color(0xFFF0F1F5),
        surfaceContainerHigh: const Color(0xFFEAEBF1),
        surfaceContainerHighest: const Color(0xFFE4E6ED),
        surfaceDim: const Color(0xFFDDDEE6),
        surfaceBright: const Color(0xFFFBFBFD),
        outline: const Color(0xFFC7CAD4),
        outlineVariant: const Color(0xFFE7E8EF),
        inverseSurface: const Color(0xFF23252E),
        onInverseSurface: const Color(0xFFF3F3F6),
        inversePrimary: const Color(0xFFBEBEFB),
        surfaceTint: const Color(0xFF5B5BF5),
      );

  static final ColorScheme _darkScheme =
      ColorScheme.fromSeed(seedColor: const Color(0xFF5B5BF5)).copyWith(
        brightness: Brightness.dark,
        primary: const Color(0xFF8385FF),
        onPrimary: const Color(0xFF10123A),
        primaryContainer: const Color(0xFF2E2E86),
        onPrimaryContainer: const Color(0xFFE1E1FF),
        secondary: const Color(0xFFB4B6E6),
        onSecondary: const Color(0xFF23254B),
        secondaryContainer: const Color(0xFF33355E),
        onSecondaryContainer: const Color(0xFFE2E3F6),
        tertiary: const Color(0xFF4FD1CE),
        onTertiary: const Color(0xFF00302F),
        tertiaryContainer: const Color(0xFF104B49),
        onTertiaryContainer: const Color(0xFFB8F3F0),
        error: const Color(0xFFF87171),
        onError: const Color(0xFF450A0A),
        errorContainer: const Color(0xFF5F1A1A),
        onErrorContainer: const Color(0xFFFED7D7),
        surface: const Color(0xFF0E0F13),
        onSurface: const Color(0xFFECEDF2),
        onSurfaceVariant: const Color(0xFF9BA0AE),
        surfaceContainerLowest: const Color(0xFF0A0B0E),
        surfaceContainerLow: const Color(0xFF14151B),
        surfaceContainer: const Color(0xFF181A21),
        surfaceContainerHigh: const Color(0xFF20222A),
        surfaceContainerHighest: const Color(0xFF272A33),
        surfaceDim: const Color(0xFF0E0F13),
        surfaceBright: const Color(0xFF2A2D36),
        outline: const Color(0xFF464A55),
        outlineVariant: const Color(0xFF2A2D37),
        inverseSurface: const Color(0xFFECEDF2),
        onInverseSurface: const Color(0xFF191A20),
        inversePrimary: const Color(0xFF5B5BF5),
        surfaceTint: const Color(0xFF8385FF),
      );
}
