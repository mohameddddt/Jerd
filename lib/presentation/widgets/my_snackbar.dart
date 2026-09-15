import 'package:flutter/material.dart';

class MySnackBar {
  const MySnackBar._();

  static void success(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
    bool clearOtherSnackBeforeShow = true,
  }) {
    if (clearOtherSnackBeforeShow) {
      ScaffoldMessenger.of(context).clearSnackBars();
    }
    final color = Theme.of(context).colorScheme.primary;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        backgroundColor: color,
      ),
    );
  }

  static void error(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 6),
    bool clearOtherSnackBeforeShow = true,
  }) {
    if (clearOtherSnackBeforeShow) {
      ScaffoldMessenger.of(context).clearSnackBars();
    }
    final color = Theme.of(context).colorScheme.error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        backgroundColor: color,
      ),
    );
  }
}
