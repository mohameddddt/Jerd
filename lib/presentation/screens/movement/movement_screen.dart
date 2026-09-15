import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/movement.dart';
import '../../../data/models/product.dart';
import '../../../data/repositories/movements_repo.dart';
import '../../../di/service_locator.dart';
import '../../../logic/cubits/products/products_cubit.dart';
import '../../l10n_helpers.dart';
import '../../themes/app_palette.dart';
import '../../themes/status_colors_extensions.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/progress_button.dart';
import '../../widgets/ui.dart';

/// The core write path: received / sold / adjust.
class MovementScreen extends StatefulWidget {
  final Product product;
  final MovementReason initialReason;

  const MovementScreen({
    super.key,
    required this.product,
    this.initialReason = MovementReason.received,
  });

  @override
  State<MovementScreen> createState() => _MovementScreenState();
}

class _MovementScreenState extends State<MovementScreen> {
  static const presets = [1, 6, 12, 24];
  static const reasons = [MovementReason.received, MovementReason.sold, MovementReason.adjusted];

  final quantity = TextEditingController(text: '1');
  final note = TextEditingController();
  late MovementReason reason = widget.initialReason;
  int currentStock = 0;

  @override
  void initState() {
    super.initState();
    getIt<MovementsRepo>().getStock(widget.product.uuid).then((value) {
      if (mounted) setState(() => currentStock = value);
    });
  }

  @override
  void dispose() {
    quantity.dispose();
    note.dispose();
    super.dispose();
  }

  bool get isAdjust => reason == MovementReason.adjusted;

  int get amount => int.tryParse(quantity.text.trim()) ?? 0;

  int get signedAmount => switch (reason) {
        MovementReason.sold => -amount.abs(),
        MovementReason.received => amount.abs(),
        _ => amount,
      };

  void setAmount(int value) {
    final clamped = isAdjust ? value.clamp(-99999, 99999) : value.clamp(1, 99999);
    quantity.text = '$clamped';
    setState(() {});
  }

  void selectReason(MovementReason value) {
    setState(() => reason = value);
    if (!isAdjust && amount < 1) setAmount(amount.abs() < 1 ? 1 : amount.abs());
  }

  Future<ReturnResult> save() async {
    final l10n = context.l10n;
    final navigator = Navigator.of(context);
    final result = await context.read<ProductsCubit>().recordMovement(
          productUuid: widget.product.uuid,
          reason: reason,
          // The cubit applies the sign for sales; adjustments carry their own.
          quantity: isAdjust ? amount : amount.abs(),
          note: note.text,
        );
    if (result.ok) navigator.pop(true);
    return toReturnResult(l10n, result);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.palette;
    final status = StatusColors.of(context);
    final unit = widget.product.unit;

    final (Color fill, Color onFill, Color accentText, Color container) = switch (reason) {
      MovementReason.received =>
        (status.received, onReceivedFill(context), status.receivedText, status.receivedContainer),
      MovementReason.sold =>
        (status.soldOut, onSoldFill(context), status.onSoldOutContainer, status.soldOutContainer),
      _ => (c.textStrong, c.background, c.text, c.surfaceMuted),
    };

    final question = switch (reason) {
      MovementReason.received => l10n.questionReceived(unit),
      MovementReason.sold => l10n.questionSold(unit),
      _ => l10n.questionAdjust(unit),
    };

    final saveLabel = switch (reason) {
      MovementReason.received => l10n.saveReceived(amount.abs()),
      MovementReason.sold => l10n.saveSold(amount.abs()),
      _ => l10n.saveAdjusted(signed(amount)),
    };

    final after = currentStock + signedAmount;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TopBar(
              leadingIcon: AppIcons.close,
              leadingTooltip: l10n.close,
              title: TopBar.titleText(l10n.recordMovement),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CardBox(
                      child: Row(
                        children: [
                          ProductAvatar(
                            uuid: widget.product.uuid,
                            name: widget.product.name,
                            imageUrl: widget.product.imageUrl,
                            size: 48,
                            radius: 14,
                            fontSize: 19,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.product.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 2),
                                Text(
                                  l10n.nowInStock(currentStock, unit),
                                  style: TextStyle(fontSize: 13, color: c.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        for (final value in reasons) ...[
                          if (value != reasons.first) const SizedBox(width: 10),
                          Expanded(
                            child: _ReasonButton(
                              reason: value,
                              selected: value == reason,
                              fill: fill,
                              onFill: onFill,
                              onTap: () => selectReason(value),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 30),
                    Text(question, textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: c.textSecondary)),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleIconButton(
                          icon: AppIcons.minus,
                          size: 68,
                          iconSize: 28,
                          strokeWidth: 2.2,
                          background: c.surfaceMuted,
                          tooltip: l10n.decrease,
                          onTap: () => setAmount(amount - 1),
                        ),
                        const SizedBox(width: 22),
                        Container(
                          width: 130,
                          height: 96,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: c.card,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: fill, width: 2),
                          ),
                          child: TextField(
                            controller: quantity,
                            onChanged: (_) => setState(() {}),
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.ltr,
                            keyboardType: TextInputType.numberWithOptions(signed: isAdjust),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(isAdjust ? RegExp(r'^-?\d*') : RegExp(r'\d*')),
                              LengthLimitingTextInputFormatter(5),
                            ],
                            style: TextStyle(
                              fontSize: 56,
                              height: 1,
                              fontWeight: FontWeight.w600,
                              fontFeatures: tabularFigures,
                              color: accentText,
                            ),
                            decoration: const InputDecoration(
                              isCollapsed: true,
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                          ),
                        ),
                        const SizedBox(width: 22),
                        CircleIconButton(
                          icon: AppIcons.plus,
                          size: 68,
                          iconSize: 28,
                          strokeWidth: 2.2,
                          background: c.surfaceMuted,
                          tooltip: l10n.increase,
                          onTap: () => setAmount(amount + 1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final preset in presets)
                          _PresetChip(
                            label: reason == MovementReason.sold ? '−$preset' : '+$preset',
                            selected: amount.abs() == preset,
                            accent: fill,
                            accentText: accentText,
                            container: container,
                            onTap: () => setAmount(preset),
                          ),
                      ],
                    ),
                    const SizedBox(height: 26),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(l10n.stockAfterSaving, style: TextStyle(fontSize: 15, color: c.textStrong)),
                          ),
                          Text(
                            '$currentStock',
                            style: TextStyle(fontSize: 20, fontFeatures: tabularFigures, color: c.textSecondary),
                          ),
                          const SizedBox(width: 10),
                          AppIcon(AppIcons.arrowRight, size: 20, color: c.textSecondary, mirrorInRtl: true),
                          const SizedBox(width: 10),
                          Text(
                            '$after',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              fontFeatures: tabularFigures,
                              color: after < 0 ? status.soldOutText : accentText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),
                    TextField(
                      controller: note,
                      maxLength: 120,
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        labelText: l10n.noteOptional,
                        hintText: switch (reason) {
                          MovementReason.received => l10n.noteHintReceived,
                          MovementReason.sold => l10n.noteHintSold,
                          _ => l10n.noteHintAdjust,
                        },
                        counterText: '',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MyProgressButton(
                    label: saveLabel,
                    icon: AppIcons.check,
                    backgroundColor: fill,
                    foregroundColor: onFill,
                    onPressed: save,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.savedLocallyHint,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: c.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReasonButton extends StatelessWidget {
  final MovementReason reason;
  final bool selected;
  final Color fill;
  final Color onFill;
  final VoidCallback onTap;

  const _ReasonButton({
    required this.reason,
    required this.selected,
    required this.fill,
    required this.onFill,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = StatusColors.of(context);
    final c = context.palette;
    final l10n = context.l10n;
    final idle = switch (reason) {
      MovementReason.received => status.receivedText,
      MovementReason.sold => status.onSoldOutContainer,
      _ => c.textStrong,
    };
    final foreground = selected ? onFill : idle;
    final (String? icon, String label) = switch (reason) {
      MovementReason.received => (AppIcons.plus, l10n.reasonReceived),
      MovementReason.sold => (AppIcons.minus, l10n.reasonSold),
      _ => (null, l10n.reasonAdjust),
    };

    return Semantics(
      selected: selected,
      child: Tappable(
        onTap: onTap,
        height: 64,
        radius: 18,
        color: selected ? fill : c.card,
        border: selected ? BorderSide.none : BorderSide(color: c.border),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              AppIcon(icon, size: 20, strokeWidth: 2.4, color: foreground),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final Color accentText;
  final Color container;
  final VoidCallback onTap;

  const _PresetChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.accentText,
    required this.container,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Tappable(
      onTap: onTap,
      height: 44,
      radius: 22,
      color: selected ? container : c.card,
      border: BorderSide(color: selected ? accent : c.border),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 36),
        child: Center(
          widthFactor: 1,
          child: Text(
            label,
            textDirection: TextDirection.ltr,
            style: TextStyle(
              fontSize: 15,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? accentText : c.text,
            ),
          ),
        ),
      ),
    );
  }
}
