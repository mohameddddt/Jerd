import 'package:flutter/material.dart';

abstract final class AppColors {
  // Surfaces
  static const background = Color(0xFFFAF5EE);
  static const card = Color(0xFFFFFCF8);
  static const surfaceMuted = Color(0xFFF3EBE1);
  static const surfaceSunken = Color(0xFFF7F0E7);

  // Text
  static const text = Color(0xFF2A221D);
  static const textStrong = Color(0xFF5C4F45);
  static const textSecondary = Color(0xFF7B6D62);
  static const hint = Color(0xFF9A8B7F);
  static const hintMuted = Color(0xFFA99A8E);
  static const onDark = Color(0xFFFFF8F2);

  // Borders
  static const borderSubtle = Color(0xFFEFE5D8);
  static const border = Color(0xFFE8DCCD);
  static const borderStrong = Color(0xFFD9CBBB);
  static const borderDanger = Color(0xFFEBC9C3);
  static const dragHandle = Color(0xFFDDD0C2);

  // Highlight for the "just scanned" card
  static const primarySoft = Color(0xFFF6E3D8);

  // Brand
  static const primary = Color(0xFFB85C38);
  static const primaryDark = Color(0xFF8E3F22);
  static const onPrimary = onDark;
  static const primaryContainer = Color(0xFFF2D6C6);
  static const onPrimaryContainer = primaryDark;
  static const primaryLight = Color(0xFFE8875C);

  // Error
  static const error = Color(0xFFC0453A);
  static const errorContainer = Color(0xFFF8E1DD);
  static const onErrorContainer = Color(0xFF9E3328);

  // Status: base is for dots, bars and filled buttons; text is for numbers
  // and icons on light surfaces; container/onContainer are for badges.
  static const received = Color(0xFF3E8A57);
  static const receivedText = Color(0xFF2F6E44);
  static const receivedContainer = Color(0xFFE2F0E4);
  static const onReceivedContainer = Color(0xFF2F6E44);

  static const soldOut = Color(0xFFC0453A);
  static const soldOutText = Color(0xFFC0453A);
  static const soldOutContainer = Color(0xFFF8E1DD);
  static const onSoldOutContainer = Color(0xFF9E3328);

  static const lowStock = Color(0xFFC98A1E);
  static const lowStockText = Color(0xFFA8700F);
  static const lowStockContainer = Color(0xFFF9EDD2);
  static const onLowStockContainer = Color(0xFF7A5410);

  // Scanner (camera screen)
  static const scanBackground = Color(0xFF1E1916);
  static const onScanBackground = Color(0xFFFBF4EC);
  static const scanAccent = primaryLight;

  // Product category avatars: (background, foreground)
  static const categoryTints = <(Color, Color)>[
    (Color(0xFFEFE3C8), Color(0xFF7A5A16)),
    (Color(0xFFF1E4D3), Color(0xFF8A6A45)),
    (Color(0xFFDCEBEA), Color(0xFF2F6966)),
    (Color(0xFFEDE3EE), Color(0xFF6D4F72)),
    (Color(0xFFE1EDDC), Color(0xFF43683A)),
    (Color(0xFFF4E0D5), Color(0xFF8E3F22)),
  ];
}
