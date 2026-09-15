import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/movement.dart';
import '../../../data/models/product.dart';
import '../../../data/repositories/movements_repo.dart';
import '../../../data/repositories/products_repo.dart';
import '../../../data/services/data_change_bus.dart';
import '../../../di/service_locator.dart';
import '../../../logic/cubits/auth/auth_cubit.dart';
import '../../../logic/cubits/product_detail/product_detail_cubit.dart';
import '../../../logic/cubits/product_detail/product_detail_state.dart';
import '../../../logic/cubits/products/products_cubit.dart';
import '../../l10n_helpers.dart';
import '../../themes/app_palette.dart';
import '../../themes/app_themes.dart';
import '../../themes/status_colors_extensions.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/my_snackbar.dart';
import '../../widgets/ui.dart';
import '../movement/movement_screen.dart';
import 'product_form_screen.dart';

class ProductDetailScreen extends StatelessWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProductDetailCubit(
        productUuid: productId,
        products: getIt<ProductsRepo>(),
        movements: getIt<MovementsRepo>(),
        bus: getIt<DataChangeBus>(),
      )..load(),
      child: const _ProductDetailView(),
    );
  }
}

class _ProductDetailView extends StatefulWidget {
  const _ProductDetailView();

  @override
  State<_ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends State<_ProductDetailView> {
  static const previewCount = 4;
  bool showAll = false;

  Future<void> edit(Product product) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ProductFormScreen(product: product)),
    );
    if (result == true && mounted) MySnackBar.success(context, context.l10n.productUpdated);
  }

  Future<void> record(Product product, MovementReason reason) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => MovementScreen(product: product, initialReason: reason)),
    );
    if (saved == true && mounted) MySnackBar.success(context, context.l10n.movementRecorded);
  }

  Future<void> delete(Product product) async {
    final l10n = context.l10n;
    final products = context.read<ProductsCubit>();
    final result = await showDialog(
      context: context,
      builder: (_) => MyConfirmationDialog(
        dialogType: 'delete',
        title: l10n.deleteProductTitle,
        message: l10n.deleteProductBody(product.name),
        onConfirm: () async => toReturnResult(l10n, await products.deleteProduct(product.uuid)),
      ),
    );
    if (result != null && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isOwner = context.read<AuthCubit>().user?.isOwner ?? false;

    return BlocConsumer<ProductDetailCubit, ProductDetailState>(
      listenWhen: (_, current) => current is ProductDetailGone,
      listener: (context, _) {
        MySnackBar.error(context, l10n.productGone);
        Navigator.of(context).maybePop();
      },
      builder: (context, state) {
        final loaded = state is ProductDetailLoaded ? state : null;
        return Scaffold(
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TopBar(
                  leadingIcon: AppIcons.back,
                  actions: [
                    if (loaded != null) ...[
                      CircleIconButton(
                        icon: AppIcons.edit,
                        iconSize: 22,
                        tooltip: l10n.edit,
                        onTap: () => edit(loaded.product),
                      ),
                      if (isOwner)
                        PopupMenuButton<String>(
                          tooltip: l10n.more,
                          onSelected: (_) => delete(loaded.product),
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(l10n.deleteProduct, style: TextStyle(color: context.palette.error)),
                            ),
                          ],
                          child: const SizedBox(
                            width: 48,
                            height: 48,
                            child: Center(child: AppIcon(AppIcons.more, size: 22)),
                          ),
                        ),
                    ],
                  ],
                ),
                Expanded(
                  child: switch (state) {
                    ProductDetailLoaded() => _content(context, state),
                    ProductDetailError(:final failure) => Center(
                        child: MessageView(
                          icon: AppIcons.warning,
                          title: l10n.failure(failure),
                          actionLabel: l10n.retry,
                          onAction: context.read<ProductDetailCubit>().load,
                        ),
                      ),
                    _ => const Center(child: CircularProgressIndicator()),
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _content(BuildContext context, ProductDetailLoaded state) {
    final l10n = context.l10n;
    final c = context.palette;
    final status = StatusColors.of(context);
    final p = state.product;
    final stock = state.stock;
    final (String badge, Color badgeFg, Color badgeBg, Color bar) = switch (state.level) {
      StockLevel.out => (l10n.outOfStock, status.onSoldOutContainer, status.soldOutContainer, status.soldOut),
      StockLevel.low => (l10n.lowStock, status.onLowStockContainer, status.lowStockContainer, status.lowStock),
      StockLevel.ok => (l10n.inStock, status.onReceivedContainer, status.receivedContainer, status.received),
    };
    final history = state.movements;
    final balances = state.balances;
    final visibleCount = showAll ? history.length : history.length.clamp(0, previewCount);
    final (tintBg, tintFg) = ProductAvatar.tintFor(context, p.uuid);
    final image = productImageProvider(p.imageUrl);

    return RefreshIndicator(
      onRefresh: context.read<ProductDetailCubit>().load,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  alignment: Alignment.center,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: tintBg,
                    borderRadius: BorderRadius.circular(26),
                    image: image == null ? null : DecorationImage(image: image, fit: BoxFit.cover),
                  ),
                  child: image != null
                      ? null
                      : AppIcon(AppIcons.image, size: 36, strokeWidth: 1.6, color: tintFg.withValues(alpha: 0.8)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600, letterSpacing: -0.3)),
                      const SizedBox(height: 6),
                      Text(
                        p.barcode,
                        style: TextStyle(fontSize: 14, fontFeatures: tabularFigures, color: c.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
            child: CardBox(
              radius: 24,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.inStock, style: TextStyle(fontSize: 14, color: c.textSecondary)),
                            const SizedBox(height: 2),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '$stock',
                                  style: TextStyle(
                                    fontSize: 56,
                                    height: 1,
                                    fontWeight: FontWeight.w600,
                                    fontFeatures: tabularFigures,
                                    color: stockNumberColor(context, state.level),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(p.unit, style: TextStyle(fontSize: 18, color: c.textSecondary)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      StatusBadge(
                        label: badge,
                        foreground: badgeFg,
                        background: badgeBg,
                        fontSize: 13,
                        radius: 12,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ProgressBar(value: p.reorderPoint <= 0 ? 1 : stock / (p.reorderPoint * 2), color: bar),
                  const SizedBox(height: 12),
                  Text.rich(
                    TextSpan(
                      text: l10n.reorderWhen,
                      children: [
                        TextSpan(
                          text: '${p.reorderPoint}',
                          style: TextStyle(fontWeight: FontWeight.w600, color: c.text),
                        ),
                      ],
                    ),
                    style: TextStyle(fontSize: 14, color: c.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: _ActionTile(
                    icon: AppIcons.plus,
                    label: l10n.reasonReceived,
                    foreground: status.receivedText,
                    background: status.receivedContainer,
                    onTap: () => record(p, MovementReason.received),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionTile(
                    icon: AppIcons.minus,
                    label: l10n.reasonSold,
                    foreground: status.onSoldOutContainer,
                    background: status.soldOutContainer,
                    onTap: () => record(p, MovementReason.sold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionTile(
                    icon: AppIcons.edit,
                    iconSize: 22,
                    strokeWidth: 2,
                    label: l10n.reasonAdjust,
                    foreground: c.textStrong,
                    background: c.surfaceMuted,
                    onTap: () => record(p, MovementReason.adjusted),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 12, 6),
            child: Row(
              children: [
                Expanded(child: Text(l10n.history, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
                if (history.length > previewCount)
                  TextButton(
                    onPressed: () => setState(() => showAll = !showAll),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      textStyle: const TextStyle(fontFamily: AppTheme.fontFamily, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    child: Text(showAll ? l10n.showLess : l10n.seeAll),
                  ),
              ],
            ),
          ),
          if (history.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(l10n.noMovements, style: TextStyle(fontSize: 15, color: c.textSecondary)),
            ),
          for (var i = 0; i < visibleCount; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _HistoryRow(movement: history[i], balance: balances[i], divider: i < visibleCount - 1),
            ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String icon;
  final String label;
  final Color foreground;
  final Color background;
  final VoidCallback onTap;
  final double iconSize;
  final double strokeWidth;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.foreground,
    required this.background,
    required this.onTap,
    this.iconSize = 24,
    this.strokeWidth = 2.2,
  });

  @override
  Widget build(BuildContext context) {
    return Tappable(
      onTap: onTap,
      color: background,
      radius: 20,
      height: 72,
      semanticLabel: label,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppIcon(icon, size: iconSize, strokeWidth: strokeWidth, color: foreground),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: foreground)),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final Movement movement;
  final int balance;
  final bool divider;

  const _HistoryRow({required this.movement, required this.balance, required this.divider});

  @override
  Widget build(BuildContext context) {
    final status = StatusColors.of(context);
    final c = context.palette;
    final l10n = context.l10n;
    final note = movement.note?.trim();
    final title = l10n.movementTitle(movement.reason, movement.delta);
    final (String icon, Color fg, Color bg) = switch (movement.reason) {
      MovementReason.received => (AppIcons.plus, status.receivedText, status.receivedContainer),
      MovementReason.sold => (AppIcons.minus, status.onSoldOutContainer, status.soldOutContainer),
      MovementReason.adjusted => (AppIcons.edit, c.textStrong, c.surfaceMuted),
      MovementReason.counted => (AppIcons.clipboard, c.textStrong, c.surfaceMuted),
    };
    final small = movement.reason == MovementReason.adjusted || movement.reason == MovementReason.counted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      decoration: BoxDecoration(
        border: divider ? Border(bottom: BorderSide(color: c.borderSubtle)) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: AppIcon(icon, size: small ? 18 : 20, strokeWidth: small ? 2 : 2.2, color: fg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note == null || note.isEmpty ? title : '$title · $note',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  [formatWhen(context, movement.createdAt), if (movement.userName.isNotEmpty) movement.userName]
                      .join(' · '),
                  style: TextStyle(fontSize: 13, color: c.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (!movement.synced) ...[
            Tooltip(message: context.l10n.waitingToUpload(1), child: Dot(color: status.lowStock, size: 6)),
            const SizedBox(width: 6),
          ],
          Text(
            '→ $balance',
            textDirection: TextDirection.ltr,
            style: TextStyle(fontSize: 14, fontFeatures: tabularFigures, color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}
