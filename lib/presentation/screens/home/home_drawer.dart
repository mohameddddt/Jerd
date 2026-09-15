import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/movements_repo.dart';
import '../../../di/service_locator.dart';
import '../../../logic/cubits/auth/auth_cubit.dart';
import '../../../logic/domain/daily_summary.dart';
import '../../l10n_helpers.dart';
import '../../themes/app_palette.dart';
import '../../themes/status_colors_extensions.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/ui.dart';
import 'home_screen.dart';

/// Who is signed in, today's simple summary, and shortcuts.
class HomeDrawer extends StatelessWidget {
  final ValueChanged<HomeTab> onSelect;

  const HomeDrawer({super.key, required this.onSelect});

  Future<DailySummary> _today() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final movements = await getIt<MovementsRepo>().getBetween(start, start.add(const Duration(days: 1)));
    return summarizeDay(movements, now);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.palette;
    final status = StatusColors.of(context);
    final user = context.read<AuthCubit>().user;

    void go(HomeTab tab) {
      Navigator.of(context).pop();
      onSelect(tab);
    }

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          children: [
            if (user != null)
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: c.primaryContainer, shape: BoxShape.circle),
                    child: Text(
                      user.initial,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: c.primaryDark),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        Text(
                          '${user.shopName.isEmpty ? l10n.myShop : user.shopName} · ${l10n.roleName(user.role)}',
                          style: TextStyle(fontSize: 13, color: c.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 24),
            Text(l10n.todaySummary, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.textStrong)),
            const SizedBox(height: 10),
            FutureBuilder<DailySummary>(
              future: _today(),
              builder: (context, snapshot) {
                final summary = snapshot.data ?? const DailySummary();
                Widget tile(String label, String value, Color color) => Expanded(
                      child: CardBox(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              value,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                fontFeatures: tabularFigures,
                                color: color,
                              ),
                            ),
                            Text(label, style: TextStyle(fontSize: 12, color: c.textSecondary)),
                          ],
                        ),
                      ),
                    );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        tile(l10n.summaryReceived, '${summary.received}', status.receivedText),
                        const SizedBox(width: 8),
                        tile(l10n.summarySold, '${summary.sold}', status.soldOutText),
                        const SizedBox(width: 8),
                        tile(l10n.summaryAdjusted, signed(summary.adjusted), c.textStrong),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.summaryMovements(summary.movements),
                      style: TextStyle(fontSize: 13, color: c.textSecondary),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            const Divider(),
            for (final (tab, icon, label) in [
              (HomeTab.products, AppIcons.box, l10n.navProducts),
              (HomeTab.count, AppIcons.clipboard, l10n.stockCount),
              (HomeTab.alerts, AppIcons.bell, l10n.navAlerts),
              (HomeTab.sync, AppIcons.sync, l10n.navSync),
              (HomeTab.settings, AppIcons.sliders, l10n.navSettings),
            ])
              ListTile(
                leading: AppIcon(icon, size: 22, color: c.textStrong),
                title: Text(label, style: const TextStyle(fontSize: 16)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                onTap: () => go(tab),
              ),
          ],
        ),
      ),
    );
  }
}
