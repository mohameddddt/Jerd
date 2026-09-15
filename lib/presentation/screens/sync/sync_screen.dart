import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/sync_models.dart';
import '../../../logic/cubits/connectivity/connectivity_cubit.dart';
import '../../../logic/cubits/sync/sync_cubit.dart';
import '../../../logic/cubits/sync/sync_state.dart';
import '../../l10n_helpers.dart';
import '../../themes/app_palette.dart';
import '../../themes/status_colors_extensions.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/my_snackbar.dart';
import '../../widgets/ui.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SyncCubit>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<SyncCubit, SyncState>(
      listenWhen: (previous, current) => previous is SyncInProgress && current is! SyncInProgress,
      listener: (context, state) {
        switch (state) {
          case SyncFailed(:final failure):
            MySnackBar.error(context, l10n.failure(failure));
          case SyncIdle():
            MySnackBar.success(context, l10n.syncDone);
          case SyncInProgress():
            break;
        }
      },
      builder: (context, state) {
        final overview = state.overview;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(title: l10n.syncTitle),
            Expanded(
              child: RefreshIndicator(
                onRefresh: context.read<SyncCubit>().refresh,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  children: [
                    _StatusCard(state: state),
                    if (overview.pending.isNotEmpty) ...[
                      _SectionTitle(l10n.waitingToUpload(overview.pending.length)),
                      for (var i = 0; i < overview.pending.length; i++)
                        _PendingRow(change: overview.pending[i], divider: i < overview.pending.length - 1),
                    ],
                    if (overview.conflicts.isNotEmpty) ...[
                      _SectionTitle(l10n.needsALook(overview.conflicts.length)),
                      for (final conflict in overview.conflicts)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ConflictCard(conflict: conflict),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatusCard extends StatelessWidget {
  final SyncState state;

  const _StatusCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.palette;
    final status = StatusColors.of(context);
    final online = context.watch<ConnectivityCubit>().state;
    final overview = state.overview;
    final pending = overview.pending.length;
    final syncing = state is SyncInProgress;
    final configured = overview.serverConfigured;

    final (String title, String icon, Color fg, Color bg) = !configured
        ? (l10n.demoModeTitle, AppIcons.box, c.textStrong, c.surfaceMuted)
        : !online
            ? (l10n.youreOffline, AppIcons.offline, status.lowStockText, status.lowStockContainer)
            : syncing
                ? (l10n.syncing, AppIcons.sync, c.primaryDark, c.primaryContainer)
                : pending == 0
                    ? (l10n.allSynced, AppIcons.check, status.receivedText, status.receivedContainer)
                    : (l10n.youreOnline, AppIcons.sync, c.primaryDark, c.primaryContainer);

    final last = overview.lastSyncAt;
    final subtitle = last == null ? l10n.neverSynced : l10n.lastSynced(formatWhen(context, last));
    final body = !configured
        ? l10n.demoModeBody
        : online
            ? l10n.pendingOnline(pending)
            : l10n.pendingOffline(pending);

    return CardBox(
      radius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                child: syncing
                    ? SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2.6, color: fg))
                    : AppIcon(icon, size: 28, color: fg),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                    if (configured) ...[
                      const SizedBox(height: 2),
                      Text(subtitle, style: TextStyle(fontSize: 14, color: c.textSecondary)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(body, style: TextStyle(fontSize: 15, height: 1.45, color: c.textStrong)),
          if (state is SyncFailed) ...[
            const SizedBox(height: 8),
            Text(context.l10n.syncFailed, style: TextStyle(fontSize: 13, color: c.error)),
          ],
          if (configured) ...[
            const SizedBox(height: 14),
            Tappable(
              onTap: syncing ? null : context.read<SyncCubit>().syncNow,
              color: syncing ? c.surfaceMuted : c.primary,
              radius: 18,
              height: 54,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppIcon(AppIcons.sync, size: 20, color: syncing ? c.hint : c.onPrimary),
                  const SizedBox(width: 8),
                  Text(
                    online ? l10n.syncNow : l10n.trySyncNow,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: syncing ? c.hint : c.onPrimary),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 6),
        child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      );
}

class _PendingRow extends StatelessWidget {
  final PendingChange change;
  final bool divider;

  const _PendingRow({required this.change, required this.divider});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.palette;
    final status = StatusColors.of(context);
    final label = change.entity == SyncEntity.product
        ? l10n.pendingEdited(change.productName)
        : l10n.pendingMovement(l10n.movementTitle(change.reason!, change.delta), change.productName);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      decoration: BoxDecoration(
        border: divider ? Border(bottom: BorderSide(color: c.borderSubtle)) : null,
      ),
      child: Row(
        children: [
          Dot(color: change.attempts > 0 ? status.soldOut : status.lowStock),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 15))),
          Text(formatTime(context, change.createdAt), style: TextStyle(fontSize: 13, color: c.textSecondary)),
        ],
      ),
    );
  }
}

class _ConflictCard extends StatelessWidget {
  final SyncConflict conflict;

  const _ConflictCard({required this.conflict});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.palette;
    final status = StatusColors.of(context);
    return CardBox(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 8, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: AppIcon(AppIcons.warning, size: 20, color: status.lowStockText),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(l10n.conflictTitle(conflict.keptName), style: const TextStyle(fontSize: 15, height: 1.4)),
              ),
              CircleIconButton(
                icon: AppIcons.close,
                size: 36,
                iconSize: 18,
                tooltip: l10n.dismiss,
                onTap: () => context.read<SyncCubit>().dismissConflict(conflict.id!),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: Text(
              l10n.conflictDetail(
                conflict.keptName,
                conflict.keptBy,
                formatTime(context, conflict.keptAt),
                conflict.lostName,
                conflict.lostBy,
                formatTime(context, conflict.lostAt),
              ),
              style: TextStyle(fontSize: 13, height: 1.45, color: c.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
