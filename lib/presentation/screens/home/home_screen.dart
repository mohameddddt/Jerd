import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/repositories/stock_count_repo.dart';
import '../../../data/services/data_change_bus.dart';
import '../../../data/services/messaging_service.dart';
import '../../../data/services/upgrade_service.dart';
import '../../../di/service_locator.dart';
import '../../../logic/cubits/products/products_cubit.dart';
import '../../../logic/cubits/products/products_state.dart';
import '../../l10n_helpers.dart';
import '../../themes/app_palette.dart';
import '../../widgets/app_icon.dart';
import '../alerts/alerts_screen.dart';
import '../count/stock_count_screen.dart';
import '../products/product_detail_screen.dart';
import '../products/products_screen.dart';
import '../settings/settings_screen.dart';
import '../sync/sync_screen.dart';
import 'home_drawer.dart';

enum HomeTab { products, count, alerts, sync, settings }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  HomeTab tab = HomeTab.products;
  bool countActive = false;
  StreamSubscription<String>? _pushTaps;
  StreamSubscription<DataChange>? _changes;

  @override
  void initState() {
    super.initState();
    refreshCountStatus();
    _changes = getIt<DataChangeBus>().stream.listen((_) => refreshCountStatus());
    // A tapped low-stock notification opens that product.
    final messaging = getIt<MessagingService>();
    _pushTaps = messaging.productTaps.listen(openProduct);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final launchedFrom = messaging.takePendingTap();
      if (launchedFrom != null) openProduct(launchedFrom);
      checkForUpdate();
    });
  }

  @override
  void dispose() {
    _pushTaps?.cancel();
    _changes?.cancel();
    super.dispose();
  }

  Future<void> refreshCountStatus() async {
    final active = await getIt<StockCountRepo>().getActive() != null;
    if (mounted && active != countActive) setState(() => countActive = active);
  }

  void openProduct(String uuid) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: uuid)),
    );
  }

  Future<void> openCount() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StockCountScreen()));
    await refreshCountStatus();
  }

  Future<void> checkForUpdate() async {
    final info = await getIt<UpgradeService>().check();
    if (info == null || !mounted) return;
    final l10n = context.l10n;
    await showDialog<void>(
      context: context,
      barrierDismissible: !info.required,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.updateAvailable(info.latestVersion)),
        content: Text(info.required ? l10n.updateRequired : info.notes),
        actions: [
          if (!info.required)
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.later)),
          TextButton(
            onPressed: () => launchUrl(Uri.parse(info.apkUrl), mode: LaunchMode.externalApplication),
            child: Text(l10n.updateNow),
          ),
        ],
      ),
    );
  }

  void select(HomeTab value) {
    // Stock count is a full-screen session, not a tab.
    if (value == HomeTab.count) {
      openCount();
      return;
    }
    setState(() => tab = value);
  }

  @override
  Widget build(BuildContext context) {
    final body = switch (tab) {
      HomeTab.products => ProductsScreen(onOpenCount: openCount),
      HomeTab.alerts => const AlertsScreen(),
      HomeTab.sync => const SyncScreen(),
      HomeTab.settings => const SettingsScreen(),
      HomeTab.count => const SizedBox.shrink(),
    };

    return PopScope(
      canPop: tab == HomeTab.products,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => tab = HomeTab.products);
      },
      child: Scaffold(
        drawer: HomeDrawer(onSelect: select),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              if (countActive) _CountBanner(onResume: openCount),
              Expanded(child: KeyedSubtree(key: ValueKey(tab), child: body)),
            ],
          ),
        ),
        bottomNavigationBar: BlocSelector<ProductsCubit, ProductsState, int>(
          // The same state feeds the list and this badge, so both update together.
          selector: (state) => state is ProductsLoaded ? state.alerts.length : 0,
          builder: (context, alertCount) => _BottomNav(
            selected: tab,
            alertCount: alertCount,
            onSelect: select,
          ),
        ),
      ),
    );
  }
}

class _CountBanner extends StatelessWidget {
  final VoidCallback onResume;

  const _CountBanner({required this.onResume});

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Material(
      color: c.primarySoft,
      child: InkWell(
        onTap: onResume,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 8, 10),
          child: Row(
            children: [
              AppIcon(AppIcons.clipboard, size: 20, color: c.primaryDark),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.l10n.countInProgressBanner,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: c.text),
                ),
              ),
              Text(
                context.l10n.resumeCount,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.primary),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final HomeTab selected;
  final int alertCount;
  final ValueChanged<HomeTab> onSelect;

  const _BottomNav({required this.selected, required this.alertCount, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.palette;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final items = [
      (HomeTab.products, AppIcons.box, l10n.navProducts),
      (HomeTab.count, AppIcons.clipboard, l10n.navCount),
      (HomeTab.alerts, AppIcons.bell, l10n.navAlerts),
      (HomeTab.sync, AppIcons.sync, l10n.navSync),
      (HomeTab.settings, AppIcons.sliders, l10n.navSettings),
    ];
    return Container(
      height: 80 + bottomInset,
      padding: EdgeInsets.fromLTRB(6, 0, 6, bottomInset),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: Row(
        children: [
          for (final (value, icon, label) in items)
            Expanded(
              child: _NavItem(
                icon: icon,
                label: label,
                selected: value == selected,
                badge: value == HomeTab.alerts && alertCount > 0 && value != selected ? alertCount : null,
                onTap: () => onSelect(value),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String icon;
  final String label;
  final bool selected;
  final int? badge;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Semantics(
      button: true,
      selected: selected,
      label: badge == null ? label : '$label, $badge',
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        highlightShape: BoxShape.rectangle,
        containedInkWell: true,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 32,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: selected ? c.primaryContainer : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: AppIcon(icon, size: 22, color: selected ? c.primaryDark : c.textSecondary),
                      ),
                    ),
                  ),
                  if (badge != null)
                    PositionedDirectional(
                      top: 0,
                      end: 12,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 18),
                        height: 18,
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: c.error, borderRadius: BorderRadius.circular(9)),
                        child: Text(
                          '$badge',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFFFF8F2)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? c.text : c.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
