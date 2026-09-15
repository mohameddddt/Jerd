import 'package:flutter/material.dart';
import '../l10n_helpers.dart';
import '../themes/app_palette.dart';
import 'app_icon.dart';
import 'progress_button.dart';

class MyConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String dialogType; // confirm | delete | danger
  final Future<ReturnResult> Function() onConfirm;
  final VoidCallback? onClose;
  final String? confirmLabel;
  final String? cancelLabel;

  const MyConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.dialogType,
    required this.onConfirm,
    this.onClose,
    this.confirmLabel,
    this.cancelLabel,
  });

  bool get isDanger => dialogType == 'delete' || dialogType == 'danger';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.palette;
    final accent = isDanger ? c.error : c.primary;

    return AlertDialog(
      title: Row(
        children: [
          AppIcon(isDanger ? AppIcons.warning : AppIcons.check, color: accent),
          const SizedBox(width: 10),
          Expanded(child: Text(title)),
        ],
      ),
      content: Text(message),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          onPressed: () {
            onClose?.call();
            Navigator.of(context).pop();
          },
          child: Text(cancelLabel ?? l10n.cancel),
        ),
        MyProgressButton(
          label: confirmLabel ?? (dialogType == 'delete' ? l10n.delete : l10n.confirm),
          buttonType: isDanger ? 'danger' : 'action',
          height: 44,
          radius: 16,
          fontSize: 16,
          onPressed: () async {
            final result = await onConfirm();
            if (context.mounted && result.state && Navigator.of(context).canPop()) {
              Navigator.of(context).pop(result);
            }
            return result;
          },
        ),
      ],
    );
  }
}
