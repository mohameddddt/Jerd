import 'package:flutter/material.dart';
import 'app_colors.dart';

@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  final Color received;
  final Color receivedText;
  final Color receivedContainer;
  final Color onReceivedContainer;

  final Color soldOut;
  final Color soldOutText;
  final Color soldOutContainer;
  final Color onSoldOutContainer;

  final Color lowStock;
  final Color lowStockText;
  final Color lowStockContainer;
  final Color onLowStockContainer;

  const StatusColors({
    required this.received,
    required this.receivedText,
    required this.receivedContainer,
    required this.onReceivedContainer,
    required this.soldOut,
    required this.soldOutText,
    required this.soldOutContainer,
    required this.onSoldOutContainer,
    required this.lowStock,
    required this.lowStockText,
    required this.lowStockContainer,
    required this.onLowStockContainer,
  });

  static const light = StatusColors(
    received: AppColors.received,
    receivedText: AppColors.receivedText,
    receivedContainer: AppColors.receivedContainer,
    onReceivedContainer: AppColors.onReceivedContainer,
    soldOut: AppColors.soldOut,
    soldOutText: AppColors.soldOutText,
    soldOutContainer: AppColors.soldOutContainer,
    onSoldOutContainer: AppColors.onSoldOutContainer,
    lowStock: AppColors.lowStock,
    lowStockText: AppColors.lowStockText,
    lowStockContainer: AppColors.lowStockContainer,
    onLowStockContainer: AppColors.onLowStockContainer,
  );

  static StatusColors of(BuildContext context) =>
      Theme.of(context).extension<StatusColors>()!;

  @override
  StatusColors copyWith({
    Color? received,
    Color? receivedText,
    Color? receivedContainer,
    Color? onReceivedContainer,
    Color? soldOut,
    Color? soldOutText,
    Color? soldOutContainer,
    Color? onSoldOutContainer,
    Color? lowStock,
    Color? lowStockText,
    Color? lowStockContainer,
    Color? onLowStockContainer,
  }) {
    return StatusColors(
      received: received ?? this.received,
      receivedText: receivedText ?? this.receivedText,
      receivedContainer: receivedContainer ?? this.receivedContainer,
      onReceivedContainer: onReceivedContainer ?? this.onReceivedContainer,
      soldOut: soldOut ?? this.soldOut,
      soldOutText: soldOutText ?? this.soldOutText,
      soldOutContainer: soldOutContainer ?? this.soldOutContainer,
      onSoldOutContainer: onSoldOutContainer ?? this.onSoldOutContainer,
      lowStock: lowStock ?? this.lowStock,
      lowStockText: lowStockText ?? this.lowStockText,
      lowStockContainer: lowStockContainer ?? this.lowStockContainer,
      onLowStockContainer: onLowStockContainer ?? this.onLowStockContainer,
    );
  }

  @override
  StatusColors lerp(ThemeExtension<StatusColors>? other, double t) {
    if (other is! StatusColors) return this;
    return StatusColors(
      received: Color.lerp(received, other.received, t)!,
      receivedText: Color.lerp(receivedText, other.receivedText, t)!,
      receivedContainer:
          Color.lerp(receivedContainer, other.receivedContainer, t)!,
      onReceivedContainer:
          Color.lerp(onReceivedContainer, other.onReceivedContainer, t)!,
      soldOut: Color.lerp(soldOut, other.soldOut, t)!,
      soldOutText: Color.lerp(soldOutText, other.soldOutText, t)!,
      soldOutContainer:
          Color.lerp(soldOutContainer, other.soldOutContainer, t)!,
      onSoldOutContainer:
          Color.lerp(onSoldOutContainer, other.onSoldOutContainer, t)!,
      lowStock: Color.lerp(lowStock, other.lowStock, t)!,
      lowStockText: Color.lerp(lowStockText, other.lowStockText, t)!,
      lowStockContainer:
          Color.lerp(lowStockContainer, other.lowStockContainer, t)!,
      onLowStockContainer:
          Color.lerp(onLowStockContainer, other.onLowStockContainer, t)!,
    );
  }
}
