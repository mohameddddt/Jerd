import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'data/databases/db_sync_queue.dart';
import 'data/repositories/auth_repo.dart';
import 'data/repositories/movements_repo.dart';
import 'data/repositories/products_repo.dart';
import 'data/repositories/stock_count_repo.dart';
import 'data/services/connectivity_service.dart';
import 'data/services/data_change_bus.dart';
import 'data/services/sync_service.dart';
import 'di/background_sync.dart';
import 'di/service_locator.dart';
import 'infrastructure/app_config.dart';
import 'infrastructure/app_prefs.dart';
import 'l10n/gen/app_localizations.dart';
import 'logic/cubits/auth/auth_cubit.dart';
import 'logic/cubits/auth/auth_state.dart';
import 'logic/cubits/connectivity/connectivity_cubit.dart';
import 'logic/cubits/products/products_cubit.dart';
import 'logic/cubits/settings/locale_cubit.dart';
import 'logic/cubits/settings/theme_cubit.dart';
import 'logic/cubits/sync/sync_cubit.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/themes/app_themes.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class JerdApp extends StatelessWidget {
  const JerdApp({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = getIt<AppPrefs>();
    final connectivity = getIt<ConnectivityService>();

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AuthCubit(
            repo: getIt<AuthRepo>(),
            prefs: prefs,
            afterLogin: onSignedIn,
            beforeLogout: onSigningOut,
          )..restoreSession(),
        ),
        BlocProvider(
          create: (_) => ConnectivityCubit(changes: connectivity.changes, check: connectivity.isOnline),
        ),
        BlocProvider(
          create: (_) => ProductsCubit(
            products: getIt<ProductsRepo>(),
            movements: getIt<MovementsRepo>(),
            counts: getIt<StockCountRepo>(),
            bus: getIt<DataChangeBus>(),
            currentUser: () => prefs.user,
          ),
        ),
        BlocProvider(
          create: (_) => SyncCubit(
            service: getIt<SyncService>(),
            queue: getIt<SyncQueueDb>(),
            products: getIt<ProductsRepo>(),
            prefs: prefs,
            bus: getIt<DataChangeBus>(),
            connectivity: connectivity.changes,
          ),
        ),
        BlocProvider(create: (_) => ThemeCubit(prefs)),
        BlocProvider(
          create: (_) => LocaleCubit(prefs, deviceLocale: PlatformDispatcher.instance.locale),
        ),
      ],
      child: Builder(
        builder: (context) {
          final themeMode = context.watch<ThemeCubit>().state;
          final locale = context.watch<LocaleCubit>().state;
          return MaterialApp(
            navigatorKey: navigatorKey,
            onGenerateTitle: (context) => AppLocalizations.of(context).appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            locale: locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}

/// Shows login or the app, and starts per-session work when a user signs in.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    // A restored session is already Authenticated before this widget
    // subscribes, so the listener below never sees the transition.
    if (context.read<AuthCubit>().state is Authenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _startSession(context);
      });
    }
  }

  void _startSession(BuildContext context) {
    context.read<ProductsCubit>().load();
    final sync = context.read<SyncCubit>();
    sync.refresh();
    if (AppConfig.hasBackend) sync.syncNow();
    BackgroundSync.register();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listenWhen: (previous, current) =>
          (current is Authenticated) != (previous is Authenticated),
      listener: (context, state) {
        if (state is Authenticated) {
          _startSession(context);
        } else {
          BackgroundSync.cancel();
          navigatorKey.currentState?.popUntil((route) => route.isFirst);
        }
      },
      buildWhen: (previous, current) =>
          current is Authenticated || current is Unauthenticated || previous is AuthInitial,
      builder: (context, state) => switch (state) {
        Authenticated() => const HomeScreen(),
        AuthInitial() => const Scaffold(body: SizedBox.shrink()),
        _ => const LoginScreen(),
      },
    );
  }
}
