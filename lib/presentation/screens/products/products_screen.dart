import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/product.dart';
import '../../../logic/cubits/auth/auth_cubit.dart';
import '../../../logic/cubits/products/products_cubit.dart';
import '../../../logic/cubits/products/products_state.dart';
import '../../../logic/domain/product_filter.dart';
import '../../l10n_helpers.dart';
import '../../themes/app_palette.dart';
import '../../themes/status_colors_extensions.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/my_snackbar.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/product_card.dart';
import '../../widgets/ui.dart';
import '../scan/scan_screen.dart';
import 'product_detail_screen.dart';
import 'product_form_screen.dart';

class ProductsScreen extends StatefulWidget {
  final VoidCallback? onOpenCount;

  const ProductsScreen({super.key, this.onOpenCount});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  late final TextEditingController search;

  @override
  void initState() {
    super.initState();
    final state = context.read<ProductsCubit>().state;
    search = TextEditingController(text: state is ProductsLoaded ? state.query : '');
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> openProduct(Product product) async {
    final deleted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: product.uuid)),
    );
    if (deleted == true && mounted) MySnackBar.success(context, context.l10n.productDeleted);
  }

  Future<void> addProduct() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ProductFormScreen()),
    );
    if (created == true && mounted) MySnackBar.success(context, context.l10n.productCreated);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.palette;
    final user = context.read<AuthCubit>().user;

    return Stack(
      children: [
        BlocBuilder<ProductsCubit, ProductsState>(
          builder: (context, state) {
            final loaded = state is ProductsLoaded ? state : null;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageHeader(
                  subtitle: l10n.shopItems(
                    (user?.shopName.isNotEmpty ?? false) ? user!.shopName : l10n.myShop,
                    loaded?.products.length ?? 0,
                  ),
                  title: l10n.productsTitle,
                  trailing: Tooltip(
                    message: l10n.openMenu,
                    child: Tappable(
                      onTap: () => Scaffold.of(context).openDrawer(),
                      color: c.primaryContainer,
                      radius: 22,
                      width: 44,
                      height: 44,
                      child: Center(
                        child: Text(
                          user?.initial ?? '?',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: c.primaryDark),
                        ),
                      ),
                    ),
                  ),
                ),
                const OfflineBanner(),
                if (loaded != null) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _SearchField(
                      controller: search,
                      onChanged: context.read<ProductsCubit>().setQuery,
                    ),
                  ),
                  _FilterRow(state: loaded),
                ],
                Expanded(child: _body(context, state)),
              ],
            );
          },
        ),
        PositionedDirectional(
          end: 16,
          bottom: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Tooltip(
                message: l10n.addProduct,
                child: Tappable(
                  onTap: addProduct,
                  color: c.primaryContainer,
                  radius: 18,
                  width: 52,
                  height: 52,
                  semanticLabel: l10n.addProduct,
                  shadow: const [BoxShadow(color: Color(0x26502D14), blurRadius: 6, offset: Offset(0, 2))],
                  child: Center(child: AppIcon(AppIcons.plus, color: c.primaryDark)),
                ),
              ),
              const SizedBox(height: 12),
              Tappable(
                onTap: () => ScanScreen.open(context),
                color: c.primary,
                radius: 22,
                height: 64,
                padding: const EdgeInsetsDirectional.only(start: 22, end: 26),
                shadow: const [BoxShadow(color: Color(0x4D8C3C19), blurRadius: 16, offset: Offset(0, 6))],
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIcon(AppIcons.scan, size: 26, color: c.onPrimary),
                    const SizedBox(width: 10),
                    Text(
                      l10n.scan,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: c.onPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _body(BuildContext context, ProductsState state) {
    final l10n = context.l10n;
    final cubit = context.read<ProductsCubit>();
    return switch (state) {
      ProductsLoading() => const Center(child: CircularProgressIndicator()),
      ProductsError(:final failure) => Center(
          child: MessageView(
            icon: AppIcons.warning,
            title: l10n.loadFailed,
            body: l10n.failure(failure),
            actionLabel: l10n.retry,
            onAction: cubit.load,
          ),
        ),
      ProductsEmpty() => RefreshIndicator(
          onRefresh: cubit.load,
          child: ListView(
            children: [
              MessageView(icon: AppIcons.box, title: l10n.emptyProductsTitle, body: l10n.emptyProductsBody),
            ],
          ),
        ),
      ProductsLoaded() => RefreshIndicator(
          onRefresh: () => cubit.load(silent: true),
          child: Builder(builder: (context) {
            final visible = state.visible;
            if (visible.isEmpty) {
              return ListView(children: [MessageView(title: l10n.noProductsFound)]);
            }
            // builder keeps 2,000 products smooth: only visible cards are built.
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 180),
              itemCount: visible.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, index) => ProductCard(
                key: ValueKey(visible[index].uuid),
                product: visible[index],
                stock: state.stockOf(visible[index].uuid),
                onTap: () => openProduct(visible[index]),
              ),
            );
          }),
        ),
    };
  }
}

class _FilterRow extends StatelessWidget {
  final ProductsLoaded state;

  const _FilterRow({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final status = StatusColors.of(context);
    final cubit = context.read<ProductsCubit>();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          _FilterChip(
            label: l10n.filterAll,
            count: state.products.length,
            selected: state.filter == ProductFilter.all,
            onTap: () => cubit.setFilter(ProductFilter.all),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: l10n.filterLow,
            count: state.lowCount,
            dot: status.lowStock,
            selected: state.filter == ProductFilter.low,
            onTap: () => cubit.setFilter(ProductFilter.low),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: l10n.filterOut,
            count: state.outCount,
            dot: status.soldOut,
            selected: state.filter == ProductFilter.out,
            onTap: () => cubit.setFilter(ProductFilter.out),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.controller, required this.onChanged});

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final l10n = context.l10n;
    final pill = OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(26)),
      borderSide: BorderSide(color: c.border),
    );
    return SizedBox(
      height: 52,
      child: TextField(
        controller: widget.controller,
        onChanged: (value) {
          setState(() {});
          widget.onChanged(value);
        },
        textAlignVertical: TextAlignVertical.center,
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          hintText: l10n.searchHint,
          hintStyle: TextStyle(fontSize: 16, color: c.hint),
          contentPadding: EdgeInsets.zero,
          prefixIcon: Padding(
            padding: const EdgeInsetsDirectional.only(start: 18, end: 10),
            child: AppIcon(AppIcons.search, size: 22, color: c.hint),
          ),
          prefixIconConstraints: const BoxConstraints(),
          suffixIcon: widget.controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: l10n.clear,
                  onPressed: () {
                    widget.controller.clear();
                    setState(() {});
                    widget.onChanged('');
                  },
                  icon: AppIcon(AppIcons.close, size: 20, color: c.textSecondary),
                ),
          border: pill,
          enabledBorder: pill,
          focusedBorder: pill.copyWith(borderSide: BorderSide(color: c.primary, width: 1.5)),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final Color? dot;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    this.dot,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final foreground = selected ? c.background : c.text;
    return Semantics(
      selected: selected,
      child: Tappable(
        onTap: onTap,
        height: 38,
        radius: 19,
        color: selected ? c.text : c.card,
        border: selected ? BorderSide.none : BorderSide(color: c.border),
        padding: EdgeInsets.symmetric(horizontal: dot == null ? 16 : 14),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dot != null) ...[Dot(color: dot!), const SizedBox(width: 8)],
            Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: foreground)),
            SizedBox(width: dot == null ? 6 : 8),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: selected ? c.background.withValues(alpha: 0.7) : c.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
