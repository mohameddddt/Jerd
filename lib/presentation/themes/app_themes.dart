import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'status_colors_extensions.dart';

abstract final class AppTheme {
  static const double radiusSmall = 16.0;
  static const double radiusMedium = 20.0;
  static const double radiusLarge = 24.0;

  static const colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.onPrimaryContainer,
    secondary: AppColors.textStrong,
    onSecondary: AppColors.onDark,
    secondaryContainer: AppColors.surfaceMuted,
    onSecondaryContainer: AppColors.textStrong,
    error: AppColors.error,
    onError: AppColors.onDark,
    errorContainer: AppColors.errorContainer,
    onErrorContainer: AppColors.onErrorContainer,
    surface: AppColors.card,
    onSurface: AppColors.text,
    onSurfaceVariant: AppColors.textSecondary,
    surfaceContainerLowest: AppColors.card,
    surfaceContainerLow: AppColors.background,
    surfaceContainer: AppColors.surfaceSunken,
    surfaceContainerHigh: AppColors.surfaceMuted,
    surfaceContainerHighest: AppColors.borderSubtle,
    outline: AppColors.borderStrong,
    outlineVariant: AppColors.borderSubtle,
    inverseSurface: AppColors.text,
    onInverseSurface: AppColors.onDark,
    inversePrimary: AppColors.primaryLight,
    surfaceTint: Colors.transparent,
    shadow: Colors.black,
    scrim: Colors.black,
  );

  static ThemeData get lightTheme {
    final textTheme = GoogleFonts.rubikTextTheme().apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    );

    OutlineInputBorder inputBorder(Color color, double width) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: GoogleFonts.rubik().fontFamily,
      textTheme: textTheme,
      iconTheme: const IconThemeData(color: AppColors.text),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 64,
        centerTitle: false,
        titleTextStyle: GoogleFonts.rubik(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.text,
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          side: const BorderSide(color: AppColors.borderSubtle),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
        labelStyle: GoogleFonts.rubik(color: AppColors.textSecondary),
        floatingLabelStyle: GoogleFonts.rubik(color: AppColors.textSecondary),
        hintStyle: GoogleFonts.rubik(color: AppColors.hint),
        helperStyle:
            GoogleFonts.rubik(fontSize: 13, color: AppColors.textSecondary),
        errorStyle: GoogleFonts.rubik(fontSize: 13, color: AppColors.error),
        prefixIconColor: AppColors.hint,
        suffixIconColor: AppColors.textSecondary,
        border: inputBorder(AppColors.borderStrong, 1.5),
        enabledBorder: inputBorder(AppColors.borderStrong, 1.5),
        focusedBorder: inputBorder(AppColors.primary, 2),
        errorBorder: inputBorder(AppColors.error, 2),
        focusedErrorBorder: inputBorder(AppColors.error, 2),
        disabledBorder: inputBorder(AppColors.borderSubtle, 1.5),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 44),
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
          textStyle: GoogleFonts.rubik(fontWeight: FontWeight.w500),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size.fromHeight(62),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: GoogleFonts.rubik(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: GoogleFonts.rubik(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      chipTheme: ChipThemeData(
        showCheckmark: false,
        color: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.text
              : AppColors.card,
        ),
        side: WidgetStateBorderSide.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? BorderSide.none
              : const BorderSide(color: AppColors.border),
        ),
        labelStyle: WidgetStateTextStyle.resolveWith(
          (states) => GoogleFonts.rubik(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? AppColors.onDark
                : AppColors.text,
          ),
        ),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.borderSubtle,
        thickness: 1,
        space: 1,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        titleTextStyle: GoogleFonts.rubik(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.text,
        ),
        contentTextStyle: GoogleFonts.rubik(
          fontSize: 15,
          color: AppColors.textStrong,
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        dragHandleColor: AppColors.borderStrong,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusLarge)),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.text,
        contentTextStyle: GoogleFonts.rubik(
          fontSize: 14,
          color: AppColors.onDark,
        ),
        actionTextColor: AppColors.primaryLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),

      extensions: const <ThemeExtension<dynamic>>[
        StatusColors.light,
      ],
    );
  }
}
