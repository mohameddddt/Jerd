import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Theme-aware surface, text and brand colours. Widgets read these through
/// `context.palette` so light and dark both follow the design.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Brightness brightness;
  final Color background;
  final Color card;
  final Color surfaceMuted;
  final Color surfaceSunken;
  final Color text;
  final Color textStrong;
  final Color textSecondary;
  final Color hint;
  final Color hintMuted;
  final Color onDark;
  final Color borderSubtle;
  final Color border;
  final Color borderStrong;
  final Color borderDanger;
  final Color dragHandle;
  final Color primarySoft;
  final Color primary;
  final Color primaryDark;
  final Color onPrimary;
  final Color primaryContainer;
  final Color primaryLight;
  final Color error;
  final Color errorContainer;
  final Color onErrorContainer;
  final Color offlineBannerText;
  final List<(Color, Color)> categoryTints;

  const AppPalette({
    required this.brightness,
    required this.background,
    required this.card,
    required this.surfaceMuted,
    required this.surfaceSunken,
    required this.text,
    required this.textStrong,
    required this.textSecondary,
    required this.hint,
    required this.hintMuted,
    required this.onDark,
    required this.borderSubtle,
    required this.border,
    required this.borderStrong,
    required this.borderDanger,
    required this.dragHandle,
    required this.primarySoft,
    required this.primary,
    required this.primaryDark,
    required this.onPrimary,
    required this.primaryContainer,
    required this.primaryLight,
    required this.error,
    required this.errorContainer,
    required this.onErrorContainer,
    required this.offlineBannerText,
    required this.categoryTints,
  });

  bool get isDark => brightness == Brightness.dark;

  static const light = AppPalette(
    brightness: Brightness.light,
    background: AppColors.background,
    card: AppColors.card,
    surfaceMuted: AppColors.surfaceMuted,
    surfaceSunken: AppColors.surfaceSunken,
    text: AppColors.text,
    textStrong: AppColors.textStrong,
    textSecondary: AppColors.textSecondary,
    hint: AppColors.hint,
    hintMuted: AppColors.hintMuted,
    onDark: AppColors.onDark,
    borderSubtle: AppColors.borderSubtle,
    border: AppColors.border,
    borderStrong: AppColors.borderStrong,
    borderDanger: AppColors.borderDanger,
    dragHandle: AppColors.dragHandle,
    primarySoft: AppColors.primarySoft,
    primary: AppColors.primary,
    primaryDark: AppColors.primaryDark,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primaryContainer,
    primaryLight: AppColors.primaryLight,
    error: AppColors.error,
    errorContainer: AppColors.errorContainer,
    onErrorContainer: AppColors.onErrorContainer,
    offlineBannerText: Color(0xFF6E4B0E),
    categoryTints: AppColors.categoryTints,
  );

  /// Warm dark counterpart: the same hues, lifted for contrast on dark surfaces.
  static const dark = AppPalette(
    brightness: Brightness.dark,
    background: Color(0xFF1B1613),
    card: Color(0xFF251F1B),
    surfaceMuted: Color(0xFF2F2823),
    surfaceSunken: Color(0xFF221C18),
    text: Color(0xFFF3EAE1),
    textStrong: Color(0xFFD9CCC0),
    textSecondary: Color(0xFFAE9F93),
    hint: Color(0xFF8F8176),
    hintMuted: Color(0xFF7E7167),
    onDark: Color(0xFFFFF8F2),
    borderSubtle: Color(0xFF342C26),
    border: Color(0xFF3F362F),
    borderStrong: Color(0xFF51463D),
    borderDanger: Color(0xFF6B3A33),
    dragHandle: Color(0xFF51463D),
    primarySoft: Color(0xFF3D2A20),
    primary: Color(0xFFD9774E),
    primaryDark: Color(0xFFF2C2A8),
    onPrimary: Color(0xFF221008),
    primaryContainer: Color(0xFF4A2E20),
    primaryLight: Color(0xFFE8875C),
    error: Color(0xFFE77B6F),
    errorContainer: Color(0xFF45231F),
    onErrorContainer: Color(0xFFF5B2A8),
    offlineBannerText: Color(0xFFF0CD8A),
    categoryTints: [
      (Color(0xFF3A3222), Color(0xFFE3C98A)),
      (Color(0xFF3A3026), Color(0xFFDDBF98)),
      (Color(0xFF1F3533), Color(0xFF93CFCA)),
      (Color(0xFF342A36), Color(0xFFD3B6D8)),
      (Color(0xFF26331F), Color(0xFFAFD29F)),
      (Color(0xFF3F2A20), Color(0xFFF2C2A8)),
    ],
  );

  static AppPalette of(BuildContext context) =>
      Theme.of(context).extension<AppPalette>() ?? light;

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return t < 0.5 ? this : other;
  }
}

extension PaletteContext on BuildContext {
  AppPalette get palette => AppPalette.of(this);
}
