import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../logic/cubits/auth/auth_cubit.dart';
import '../../../logic/cubits/settings/locale_cubit.dart';
import '../../../logic/cubits/settings/theme_cubit.dart';
import '../../../logic/cubits/sync/sync_cubit.dart';
import '../../l10n_helpers.dart';
import '../../themes/app_palette.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/progress_button.dart';
import '../../widgets/ui.dart';
import 'staff_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _languageNames = {'ar': 'العربية', 'fr': 'Français', 'en': 'English'};

  Future<void> signOut(BuildContext context) async {
    final l10n = context.l10n;
    final auth = context.read<AuthCubit>();
    final pending = context.read<SyncCubit>().state.overview.pending.length;
    await showDialog(
      context: context,
      builder: (_) => MyConfirmationDialog(
        dialogType: pending > 0 ? 'danger' : 'confirm',
        title: l10n.signOutTitle,
        message: pending > 0 ? '${l10n.signOutBody}\n\n${l10n.signOutPending(pending)}' : l10n.signOutBody,
        confirmLabel: l10n.signOut,
        onConfirm: () async {
          await auth.logout();
          return const ReturnResult(state: true, message: '');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.palette;
    final locale = context.watch<LocaleCubit>().state;
    final themeMode = context.watch<ThemeCubit>().state;
    final user = context.watch<AuthCubit>().user;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(title: l10n.settingsTitle),
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SectionLabel(icon: AppIcons.globe, label: l10n.language),
                      const SizedBox(height: 10),
                      SegmentedTabs<Locale>(
                        values: LocaleCubit.supported,
                        selected: locale,
                        onChanged: context.read<LocaleCubit>().setLocale,
                        labelBuilder: (value, _) => Text(_languageNames[value.languageCode]!),
                      ),
                      const SizedBox(height: 22),
                      _SectionLabel(icon: AppIcons.moon, label: l10n.theme),
                      const SizedBox(height: 10),
                      SegmentedTabs<ThemeMode>(
                        values: const [ThemeMode.light, ThemeMode.dark, ThemeMode.system],
                        selected: themeMode,
                        onChanged: context.read<ThemeCubit>().setMode,
                        labelBuilder: (value, _) => Text(switch (value) {
                          ThemeMode.light => l10n.themeLight,
                          ThemeMode.dark => l10n.themeDark,
                          ThemeMode.system => l10n.themeSystem,
                        }),
                      ),
                      const SizedBox(height: 22),
                      if (user != null)
                        Tappable(
                          color: c.card,
                          radius: 22,
                          border: BorderSide(color: c.borderSubtle),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  border: Border(bottom: BorderSide(color: c.borderSubtle)),
                                ),
                                child: Row(
                                  children: [
                                    _Circle(
                                      color: c.primaryContainer,
                                      child: Text(
                                        user.initial,
                                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: c.primaryDark),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    _Texts(user.name, '${user.email} · ${l10n.roleName(user.role)}'),
                                  ],
                                ),
                              ),
                              InkWell(
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const StaffScreen()),
                                ),
                                child: Container(
                                  constraints: const BoxConstraints(minHeight: 64),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  child: Row(
                                    children: [
                                      _Circle(
                                        color: c.surfaceMuted,
                                        child: AppIcon(AppIcons.users, size: 22, color: c.textStrong),
                                      ),
                                      const SizedBox(width: 14),
                                      _Texts(l10n.staffAccounts, user.shopName.isEmpty ? l10n.myShop : user.shopName),
                                      AppIcon(AppIcons.chevronRight, size: 22, color: c.textSecondary, mirrorInRtl: true),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 22),
                      Tappable(
                        onTap: () => signOut(context),
                        height: 56,
                        radius: 20,
                        border: BorderSide(color: c.borderDanger, width: 1.5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppIcon(AppIcons.signOut, size: 20, color: c.error, mirrorInRtl: true),
                            const SizedBox(width: 8),
                            Text(
                              l10n.signOut,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.error),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Spacer(),
                      FutureBuilder<PackageInfo>(
                        future: PackageInfo.fromPlatform(),
                        builder: (context, snapshot) => Text(
                          l10n.appVersion(snapshot.data?.version ?? ''),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: c.hint),
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

class _SectionLabel extends StatelessWidget {
  final String icon;
  final String label;

  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          AppIcon(icon, size: 18, color: c.textStrong),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.textStrong)),
        ],
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  final Color color;
  final Widget child;

  const _Circle({required this.color, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: child,
      );
}

class _Texts extends StatelessWidget {
  final String title;
  final String subtitle;

  const _Texts(this.title, this.subtitle);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(fontSize: 13, color: context.palette.textSecondary)),
          ],
        ),
      );
}
