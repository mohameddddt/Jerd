import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/movements_repo.dart';
import '../../../data/repositories/products_repo.dart';
import '../../../data/repositories/stock_count_repo.dart';
import '../../../data/services/data_change_bus.dart';
import '../../../di/service_locator.dart';
import '../../../infrastructure/app_prefs.dart';
import '../../../logic/cubits/stock_count/stock_count_cubit.dart';
import '../../../logic/cubits/stock_count/stock_count_state.dart';
import '../../l10n_helpers.dart';
import '../../themes/app_palette.dart';
import '../../themes/status_colors_extensions.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/my_snackbar.dart';
import '../../widgets/ui.dart';
import '../scan/scan_screen.dart';

class StockCountScreen extends StatelessWidget {
  const StockCountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StockCountCubit(
        counts: getIt<StockCountRepo>(),
        products: getIt<ProductsRepo>(),
        movements: getIt<MovementsRepo>(),
        bus: getIt<DataChangeBus>(),
        currentUser: () => getIt<AppPrefs>().user,
      )..open(),
      child: const _StockCountView(),
    );
  }
}

class _StockCountView extends StatefulWidget {
  const _StockCountView();

  @override
  State<_StockCountView> createState() => _StockCountViewState();
}

enum _LeaveChoice { later, discard }

class _StockCountViewState extends State<_StockCountView> {
  bool showDifferences = true;

  StockCountCubit get cubit => context.read<StockCountCubit>();

  Future<void> scanNext() async {
    final l10n = context.l10n;
    final code = await ScanScreen.pick(context);
    if (code == null || !mounted) return;
    final outcome = await cubit.scan(code);
    if (outcome == ScanOutcome.unknownBarcode && mounted) {
      MySnackBar.error(context, l10n.unknownBarcode(code));
    }
  }

  /// Unsaved-work guard: the count is already persisted, so leaving only asks
  /// whether to keep it for later or throw it away.
  Future<void> leave() async {
    final l10n = context.l10n;
    final navigator = Navigator.of(context);
    final state = cubit.state;
    final hasWork = state is StockCountCounting && state.hasUnsavedWork;
    if (!hasWork) {
      if (state is StockCountCounting) await cubit.discard();
      navigator.pop();
      return;
    }
    final choice = await showDialog<_LeaveChoice>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.leaveCountTitle),
        content: Text(l10n.leaveCountBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, _LeaveChoice.discard),
            child: Text(l10n.discardCount, style: TextStyle(color: dialogContext.palette.error)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, _LeaveChoice.later),
            child: Text(l10n.continueLater),
          ),
        ],
      ),
    );
    if (choice == null) return;
    if (choice == _LeaveChoice.discard) await cubit.discard();
    navigator.pop();
  }

  Future<void> confirmFinish(StockCountReconciling state) async {
    final l10n = context.l10n;
    final count = state.differences.length;
    final result = await showDialog(
      context: context,
      builder: (_) => MyConfirmationDialog(
        dialogType: 'confirm',
        title: l10n.finishCountTitle,
        message: count == 0 ? l10n.finishCountNoDiff : l10n.finishCountBody(count),
        confirmLabel: l10n.commitCount,
        cancelLabel: l10n.keepCounting,
        onConfirm: () async => toReturnResult(l10n, await cubit.commit()),
      ),
    );
    if (!mounted) return;
    if (result == null) {
      cubit.keepCounting();
      return;
    }
    MySnackBar.success(context, l10n.countSaved);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<StockCountCubit, StockCountState>(
      listenWhen: (previous, current) => current is StockCountReconciling && previous is! StockCountReconciling,
      listener: (context, state) => confirmFinish(state as StockCountReconciling),
      builder: (context, state) {
        final StockCountCounting? counting = switch (state) {
          StockCountCounting s => s,
          StockCountReconciling(:final counting) => counting,
          _ => null,
        };
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) leave();
          },
          child: Scaffold(
            body: SafeArea(
              child: switch (state) {
                StockCountError(:final failure) => Column(
                    children: [
                      TopBar(leadingIcon: AppIcons.close, onLeading: () => Navigator.pop(context)),
                      Expanded(
                        child: Center(
                          child: MessageView(
                            icon: AppIcons.warning,
                            title: l10n.failure(failure),
                            actionLabel: l10n.retry,
                            onAction: cubit.open,
                          ),
                        ),
                      ),
                    ],
                  ),
                _ => counting == null
                    ? const Center(child: CircularProgressIndicator())
                    : _content(context, counting),
              },
            ),
          ),
        );
      },
    );
  }

  Widget _content(BuildContext context, StockCountCounting state) {
    final l10n = context.l10n;
    final c = context.palette;
    final total = state.totalProducts;
    final done = state.countedProducts;
    final percent = (state.progress * 100).round();
    final differences = state.differences;
    final listed = showDifferences
        ? differences.map((d) => d.productUuid).toList()
        : state.lines.reversed.map((e) => e.key).toList();
    final elapsed = state.elapsed;
    final minutes = elapsed.inMinutes.toString().padLeft(2, '0');
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    final current = state.current == null ? null : state.products[state.current];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TopBar(
          leadingIcon: AppIcons.close,
          leadingTooltip: l10n.close,
          onLeading: leave,
          padding: const EdgeInsetsDirectional.only(start: 8, end: 12),
          title: TopBar.titleText(l10n.stockCount),
          actions: [
            Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: BorderRadius.circular(18)),
              child: Row(
                children: [
                  AppIcon(AppIcons.clock, size: 18, color: c.textStrong),
                  const SizedBox(width: 6),
                  Text(
                    elapsed.inHours > 0 ? '${elapsed.inHours}:$minutes:$seconds' : '$minutes:$seconds',
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      fontFeatures: tabularFigures,
                      color: c.textStrong,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: CardBox(
            radius: 22,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$done',
                      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w600, fontFeatures: tabularFigures),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(l10n.countedOf(total), style: TextStyle(fontSize: 16, color: c.textSecondary)),
                    ),
                    Text('$percent%', style: TextStyle(fontSize: 14, color: c.textSecondary)),
                  ],
                ),
                const SizedBox(height: 10),
                ProgressBar(value: state.progress, color: c.primary),
              ],
            ),
          ),
        ),
        if (current != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _CurrentItem(
              name: current.name,
              expected: state.expectedOf(current.uuid),
              counted: state.countedOf(current.uuid),
              onMinus: () => cubit.changeCounted(current.uuid, -1),
              onPlus: () => cubit.changeCounted(current.uuid, 1),
              onSet: (value) => cubit.setCounted(current.uuid, value),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: SegmentedTabs<bool>(
            values: const [true, false],
            selected: showDifferences,
            height: 50,
            radius: 16,
            onChanged: (value) => setState(() => showDifferences = value),
            labelBuilder: (value, selected) => value
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          l10n.differences,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 15, color: selected ? c.text : c.textSecondary),
                        ),
                      ),
                      if (differences.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          constraints: const BoxConstraints(minWidth: 22),
                          height: 22,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: c.error, borderRadius: BorderRadius.circular(11)),
                          child: Text(
                            '${differences.length}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFFFFF8F2)),
                          ),
                        ),
                      ],
                    ],
                  )
                : Text(
                    l10n.allCounted,
                    style: TextStyle(fontSize: 15, color: selected ? c.text : c.textSecondary),
                  ),
          ),
        ),
        Expanded(
          child: listed.isEmpty
              ? Center(
                  child: MessageView(title: showDifferences && done > 0 ? l10n.noDifferences : l10n.nothingCounted),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: listed.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, index) {
                    final uuid = listed[index];
                    return _CountRow(
                      name: state.products[uuid]?.name ?? '—',
                      expected: state.expectedOf(uuid),
                      counted: state.countedOf(uuid),
                      onTap: () => cubit.select(uuid),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Row(
            children: [
              Expanded(
                child: Tappable(
                  onTap: done == 0 ? null : cubit.finish,
                  height: 62,
                  radius: 20,
                  color: c.card,
                  border: BorderSide(color: c.borderStrong, width: 1.5),
                  child: Center(
                    child: Text(
                      l10n.finishCount,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: done == 0 ? c.hint : c.text,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Tappable(
                  onTap: scanNext,
                  height: 62,
                  radius: 20,
                  color: c.primary,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppIcon(AppIcons.scan, color: c.onPrimary),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          l10n.scanNext,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: c.onPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CurrentItem extends StatelessWidget {
  final String name;
  final int expected;
  final int counted;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final ValueChanged<int> onSet;

  const _CurrentItem({
    required this.name,
    required this.expected,
    required this.counted,
    required this.onMinus,
    required this.onPlus,
    required this.onSet,
  });

  Future<void> type(BuildContext context) async {
    final l10n = context.l10n;
    final controller = TextEditingController(text: '$counted');
    final value = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(name),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          textDirection: TextDirection.ltr,
          onSubmitted: (text) => Navigator.pop(dialogContext, int.tryParse(text)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, int.tryParse(controller.text)),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null) onSet(value);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(18, 14, 14, 14),
      decoration: BoxDecoration(color: c.primarySoft, borderRadius: BorderRadius.circular(22)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.justScanned, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: c.primaryDark)),
                const SizedBox(height: 2),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(l10n.expectedQty(expected), style: TextStyle(fontSize: 13, color: c.textStrong)),
              ],
            ),
          ),
          CircleIconButton(
            icon: AppIcons.minus,
            size: 44,
            iconSize: 20,
            strokeWidth: 2.2,
            background: c.card,
            tooltip: l10n.oneLess,
            onTap: onMinus,
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: () => type(context),
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 52,
              child: Text(
                '$counted',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, fontFeatures: tabularFigures),
              ),
            ),
          ),
          const SizedBox(width: 6),
          CircleIconButton(
            icon: AppIcons.plus,
            size: 44,
            iconSize: 20,
            strokeWidth: 2.2,
            background: c.card,
            tooltip: l10n.oneMore,
            onTap: onPlus,
          ),
        ],
      ),
    );
  }
}

class _CountRow extends StatelessWidget {
  final String name;
  final int expected;
  final int counted;
  final VoidCallback onTap;

  const _CountRow({required this.name, required this.expected, required this.counted, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = StatusColors.of(context);
    final c = context.palette;
    final diff = counted - expected;
    final (Color fg, Color bg) = diff < 0
        ? (status.onSoldOutContainer, status.soldOutContainer)
        : diff > 0
            ? (status.onReceivedContainer, status.receivedContainer)
            : (c.textStrong, c.surfaceMuted);

    return CardBox(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 3),
                Text(
                  context.l10n.expectedCounted(expected, counted),
                  style: TextStyle(fontSize: 13, color: c.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            constraints: const BoxConstraints(minWidth: 56),
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
            child: Text(
              signed(diff),
              textDirection: TextDirection.ltr,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, fontFeatures: tabularFigures, color: fg),
            ),
          ),
        ],
      ),
    );
  }
}
