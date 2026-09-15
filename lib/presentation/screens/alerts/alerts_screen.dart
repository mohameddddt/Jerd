import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/movement.dart';
import '../../../data/models/product.dart';
import '../../../data/services/ai_service.dart';
import '../../../di/service_locator.dart';
import '../../../logic/cubits/products/products_cubit.dart';
import '../../../logic/cubits/products/products_state.dart';
import '../../../logic/domain/low_stock.dart';
import '../../l10n_helpers.dart';
import '../../themes/app_palette.dart';
import '../../themes/status_colors_extensions.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/my_snackbar.dart';
import '../../widgets/ui.dart';
import '../movement/movement_screen.dart';
import '../products/product_detail_screen.dart';

/// Items at or below their reorder point. Derived from the product list by a
/// pure function — nothing here is stored.
class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  Future<void> recordReceived(BuildContext context, Product product) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => MovementScreen(product: product, initialReason: MovementReason.received),
      ),
    );
    if (saved == true && context.mounted) MySnackBar.success(context, context.l10n.movementRecorded);
  }

  Future<void> showReorderIdeas(BuildContext context) async {
    final l10n = context.l10n;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: FutureBuilder<String>(
            future: getIt<AiService>().reorderSuggestions(),
            builder: (context, snapshot) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.reorderIdeas, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                if (snapshot.connectionState != ConnectionState.done)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  Flexible(
                    child: SingleChildScrollView(
                      child: Text(
                        snapshot.hasError || (snapshot.data ?? '').isEmpty
                            ? l10n.reorderIdeasFailed
                            : snapshot.data!,
                        style: TextStyle(fontSize: 15, height: 1.5, color: context.palette.textStrong),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<ProductsCubit, ProductsState>(
      builder: (context, state) {
        final alerts = state is ProductsLoaded ? state.alerts : const <LowStockItem>[];
        final loading = state is ProductsLoading;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              subtitle: l10n.mostUrgentFirst,
              title: loading
                  ? l10n.navAlerts
                  : alerts.isEmpty
                      ? l10n.allStockedUp
                      : l10n.itemsToRestock(alerts.length),
              trailing: getIt<AiService>().isAvailable && alerts.isNotEmpty
                  ? CircleIconButton(
                      icon: AppIcons.clipboard,
                      tooltip: l10n.reorderIdeas,
                      background: context.palette.surfaceMuted,
                      onTap: () => showReorderIdeas(context),
                    )
                  : null,
            ),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: () => context.read<ProductsCubit>().load(silent: true),
                      child: alerts.isEmpty
                          ? ListView(children: [MessageView(icon: AppIcons.check, title: l10n.noRestockNeeded)])
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              itemCount: alerts.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 12),
                              itemBuilder: (_, index) => _AlertCard(
                                item: alerts[index],
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProductDetailScreen(productId: alerts[index].product.uuid),
                                  ),
                                ),
                                onReceived: () => recordReceived(context, alerts[index].product),
                              ),
                            ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _AlertCard extends StatelessWidget {
  final LowStockItem item;
  final VoidCallback onTap;
  final VoidCallback onReceived;

  const _AlertCard({required this.item, required this.onTap, required this.onReceived});

  @override
  Widget build(BuildContext context) {
    final status = StatusColors.of(context);
    final c = context.palette;
    final l10n = context.l10n;
    final product = item.product;
    final out = item.level == StockLevel.out;
    final accent = out ? status.soldOut : status.lowStockText;

    return CardBox(
      onTap: onTap,
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: out ? status.soldOutContainer : status.lowStockContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: AppIcon(out ? AppIcons.warning : AppIcons.bell, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      out ? l10n.outOfStock : l10n.belowReorderPoint,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: out ? status.onSoldOutContainer : status.onLowStockContainer,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${item.stock}',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, fontFeatures: tabularFigures, color: accent),
                  ),
                  Text(l10n.ofReorder(product.reorderPoint), style: TextStyle(fontSize: 12, color: c.textSecondary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ProgressBar(
            value: product.reorderPoint <= 0 ? 0 : item.stock / product.reorderPoint,
            color: status.lowStock,
            height: 6,
          ),
          const SizedBox(height: 12),
          Tappable(
            onTap: onReceived,
            color: status.receivedContainer,
            radius: 16,
            height: 48,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppIcon(AppIcons.plus, size: 20, strokeWidth: 2.4, color: status.onReceivedContainer),
                const SizedBox(width: 8),
                Text(
                  l10n.recordReceived,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: status.onReceivedContainer),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
