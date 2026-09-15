import 'package:flutter/material.dart';
import 'app_palette.dart';
import 'status_colors_extensions.dart';

abstract final class AppTheme {
  static const double radiusSmall = 16.0;
  static const double radiusMedium = 20.0;
  static const double radiusLarge = 24.0;

  /// Rubik is bundled (see pubspec) so every weight — and Arabic — works offline.
  static const fontFamily = 'Rubik';

  static TextStyle _font({double? fontSize, FontWeight? fontWeight, Color? color}) =>
      TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );

  static ThemeData get lightTheme => build(AppPalette.light, StatusColors.light);

  static ThemeData get darkTheme => build(AppPalette.dark, StatusColors.dark);

  static ThemeData build(AppPalette c, StatusColors status) {
    final isDark = c.isDark;
    final colorScheme = ColorScheme(
      brightness: c.brightness,
      primary: c.primary,
      onPrimary: c.onPrimary,
      primaryContainer: c.primaryContainer,
      onPrimaryContainer: c.primaryDark,
      secondary: c.textStrong,
      onSecondary: c.background,
      secondaryContainer: c.surfaceMuted,
      onSecondaryContainer: c.textStrong,
      error: c.error,
      onError: isDark ? c.background : c.onDark,
      errorContainer: c.errorContainer,
      onErrorContainer: c.onErrorContainer,
      surface: c.card,
      onSurface: c.text,
      onSurfaceVariant: c.textSecondary,
      surfaceContainerLowest: c.card,
      surfaceContainerLow: c.background,
      surfaceContainer: c.surfaceSunken,
      surfaceContainerHigh: c.surfaceMuted,
      surfaceContainerHighest: c.borderSubtle,
      outline: c.borderStrong,
      outlineVariant: c.borderSubtle,
      inverseSurface: c.text,
      onInverseSurface: c.background,
      inversePrimary: c.primaryLight,
      surfaceTint: Colors.transparent,
      shadow: Colors.black,
      scrim: Colors.black,
    );

    final base = isDark ? Typography.material2021().white : Typography.material2021().black;
    final textTheme = base.apply(
      fontFamily: fontFamily,
      bodyColor: c.text,
      displayColor: c.text,
    );

    OutlineInputBorder inputBorder(Color color, double width) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: c.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: c.background,
      fontFamily: fontFamily,
      textTheme: textTheme,
      iconTheme: IconThemeData(color: c.text),
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 64,
        centerTitle: false,
        titleTextStyle: _font(fontSize: 20, fontWeight: FontWeight.w600, color: c.text),
      ),
      cardTheme: CardThemeData(
        color: c.card,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          side: BorderSide(color: c.borderSubtle),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 19),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: _font(fontSize: 13, color: c.textSecondary),
        floatingLabelStyle: WidgetStateTextStyle.resolveWith(
          (states) => _font(
            fontSize: 13,
            fontWeight: states.contains(WidgetState.error) || states.contains(WidgetState.focused)
                ? FontWeight.w500
                : FontWeight.w400,
            color: states.contains(WidgetState.error)
                ? c.error
                : states.contains(WidgetState.focused)
                    ? c.primary
                    : c.textSecondary,
          ),
        ),
        hintStyle: _font(fontSize: 16, color: c.hintMuted),
        helperStyle: _font(fontSize: 13, color: c.textSecondary),
        errorStyle: _font(fontSize: 13, color: c.error),
        prefixIconColor: c.hint,
        suffixIconColor: c.textSecondary,
        border: inputBorder(c.borderStrong, 1.5),
        enabledBorder: inputBorder(c.borderStrong, 1.5),
        focusedBorder: inputBorder(c.primary, 2),
        errorBorder: inputBorder(c.error, 2),
        focusedErrorBorder: inputBorder(c.error, 2),
        disabledBorder: inputBorder(c.borderSubtle, 1.5),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 44),
          foregroundColor: c.primary,
          side: BorderSide(color: c.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSmall)),
          textStyle: _font(fontWeight: FontWeight.w500),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          minimumSize: const Size.fromHeight(62),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMedium)),
          textStyle: _font(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.primary,
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMedium)),
          textStyle: _font(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
      chipTheme: ChipThemeData(
        showCheckmark: false,
        color: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? c.text : c.card,
        ),
        side: WidgetStateBorderSide.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? BorderSide.none : BorderSide(color: c.border),
        ),
        labelStyle: WidgetStateTextStyle.resolveWith(
          (states) => _font(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: states.contains(WidgetState.selected) ? c.background : c.text,
          ),
        ),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
      dividerTheme: DividerThemeData(color: c.borderSubtle, thickness: 1, space: 1),
      dialogTheme: DialogThemeData(
        backgroundColor: c.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLarge)),
        titleTextStyle: _font(fontSize: 20, fontWeight: FontWeight.w600, color: c.text),
        contentTextStyle: _font(fontSize: 15, color: c.textStrong),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: c.card,
        surfaceTintColor: Colors.transparent,
        textStyle: _font(fontSize: 15, color: c.text),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSmall)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.card,
        surfaceTintColor: Colors.transparent,
        dragHandleColor: c.borderStrong,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusLarge)),
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: c.background,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.text,
        contentTextStyle: _font(fontSize: 14, color: c.background),
        actionTextColor: c.primaryLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSmall)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.primary),
      extensions: <ThemeExtension<dynamic>>[c, status],
    );
  }
}
