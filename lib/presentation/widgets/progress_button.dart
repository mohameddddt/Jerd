import 'package:flutter/material.dart';
import '../../l10n/gen/app_localizations.dart';
import 'app_icon.dart';
import 'my_snackbar.dart';

class ReturnResult {
  final bool state;
  final String message;

  const ReturnResult({required this.state, required this.message});
}

class MyProgressButton extends StatefulWidget {
  final String label;
  final String buttonType;
  final Future<ReturnResult> Function() onPressed;
  final String? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double height;
  final double radius;
  final double fontSize;

  const MyProgressButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.buttonType = 'action',
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.height = 62,
    this.radius = 20,
    this.fontSize = 18,
  });

  @override
  State<MyProgressButton> createState() => _MyProgressButtonState();
}

class _MyProgressButtonState extends State<MyProgressButton> {
  bool isLoading = false;

  Future<void> handleProgressButtonPress() async {
    if (isLoading) return;

    setState(() => isLoading = true);

    try {
      final result = await widget.onPressed();
      if (!mounted) return;

      if (widget.buttonType != 'silent' && result.message.isNotEmpty) {
        if (result.state) {
          MySnackBar.success(context, result.message);
        } else {
          MySnackBar.error(context, result.message);
        }
      }
    } catch (e) {
      if (mounted) {
        MySnackBar.error(context, AppLocalizations.of(context).errorUnknown);
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = widget.backgroundColor ??
        (widget.buttonType == 'danger' ? colorScheme.error : colorScheme.primary);
    final foregroundColor = widget.foregroundColor ?? colorScheme.onPrimary;

    return SizedBox(
      height: widget.height,
      child: FilledButton(
        onPressed: handleProgressButtonPress,
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: foregroundColor,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    AppIcon(widget.icon!, size: 22, strokeWidth: 2.4, color: foregroundColor),
                    const SizedBox(width: 10),
                  ],
                  Flexible(
                    child: Text(
                      widget.label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: widget.fontSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
