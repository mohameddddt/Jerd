import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/cubits/connectivity/connectivity_cubit.dart';
import '../l10n_helpers.dart';
import '../themes/app_palette.dart';
import '../themes/status_colors_extensions.dart';
import 'app_icon.dart';

/// Shown while the radio is off; disappears on its own when it returns.
class OfflineBanner extends StatelessWidget {
  final EdgeInsetsGeometry margin;

  const OfflineBanner({super.key, this.margin = const EdgeInsets.fromLTRB(16, 8, 16, 0)});

  @override
  Widget build(BuildContext context) {
    final online = context.watch<ConnectivityCubit>().state;
    final status = StatusColors.of(context);
    final c = context.palette;
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: online
          ? const SizedBox(width: double.infinity)
          : Semantics(
              liveRegion: true,
              child: Container(
                margin: margin,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: status.lowStockContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    AppIcon(AppIcons.offline, size: 20, color: c.offlineBannerText),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.l10n.offlineBanner,
                        style: TextStyle(fontSize: 13, height: 1.35, color: c.offlineBannerText),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
