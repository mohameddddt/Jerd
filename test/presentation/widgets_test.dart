import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jerd/data/models/movement.dart';
import 'package:jerd/data/repositories/auth_demo.dart';
import 'package:jerd/data/repositories/movements_dummy.dart';
import 'package:jerd/data/repositories/movements_repo.dart';
import 'package:jerd/data/repositories/products_dummy.dart';
import 'package:jerd/data/repositories/stock_count_dummy.dart';
import 'package:jerd/data/services/data_change_bus.dart';
import 'package:jerd/di/service_locator.dart';
import 'package:jerd/infrastructure/app_prefs.dart';
import 'package:jerd/l10n/gen/app_localizations.dart';
import 'package:jerd/logic/cubits/auth/auth_cubit.dart';
import 'package:jerd/logic/cubits/products/products_cubit.dart';
import 'package:jerd/presentation/screens/auth/login_screen.dart';
import 'package:jerd/presentation/screens/movement/movement_screen.dart';
import 'package:jerd/presentation/themes/app_themes.dart';
import 'package:jerd/presentation/widgets/product_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers.dart';

Widget harness(Widget child, {Locale locale = const Locale('en'), ThemeMode mode = ThemeMode.light}) =>
    MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: mode,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: child),
    );

void main() {
  group('ProductCard', () {
    testWidgets('shows stock, unit and the low-stock badge', (tester) async {
      await tester.pumpWidget(harness(ProductCard(product: aProduct(reorder: 6), stock: 3, onTap: () {})));
      expect(find.text('Olive oil 1L'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('bottles'), findsOneWidget);
      expect(find.text('Low · reorder at 6'), findsOneWidget);
    });

    testWidgets('out of stock and healthy stock', (tester) async {
      await tester.pumpWidget(harness(Column(children: [
        ProductCard(product: aProduct(uuid: 'a'), stock: 0, onTap: () {}),
        ProductCard(product: aProduct(uuid: 'b', barcode: '6130000100099'), stock: 40, onTap: () {}),
      ])));
      expect(find.text('Out of stock'), findsOneWidget);
      expect(find.text('6130000100099'), findsOneWidget, reason: 'healthy stock shows the barcode');
    });

    testWidgets('taps are reported', (tester) async {
      var taps = 0;
      await tester.pumpWidget(harness(ProductCard(product: aProduct(), stock: 10, onTap: () => taps++)));
      await tester.tap(find.byType(ProductCard));
      expect(taps, 1);
    });

    testWidgets('Arabic lays out right-to-left and renders in dark mode', (tester) async {
      await tester.pumpWidget(harness(
        ProductCard(product: aProduct(reorder: 6), stock: 0, onTap: () {}),
        locale: const Locale('ar'),
        mode: ThemeMode.dark,
      ));
      expect(find.text('نفد المخزون'), findsOneWidget);
      final context = tester.element(find.byType(ProductCard));
      expect(Directionality.of(context), TextDirection.rtl);
      expect(Theme.of(context).brightness, Brightness.dark);
      // The name sits on the right of the number in RTL.
      expect(tester.getCenter(find.text('Olive oil 1L')).dx, greaterThan(tester.getCenter(find.text('0')).dx));
    });
  });

  group('LoginScreen', () {
    testWidgets('validates before calling the server', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = AppPrefs(await SharedPreferences.getInstance());
      await tester.pumpWidget(BlocProvider(
        create: (_) => AuthCubit(repo: AuthDemo(currentUser: () => null), prefs: prefs),
        child: harness(const LoginScreen()),
      ));
      await tester.enterText(find.byType(TextFormField).at(0), 'karim@');
      await tester.enterText(find.byType(TextFormField).at(1), '123');
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pump();
      expect(find.text('Enter a valid email.'), findsOneWidget);
      expect(find.text('Password must contain at least 6 characters.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
    });
  });

  group('MovementScreen', () {
    late MovementsDummy movements;

    setUp(() async {
      await getIt.reset();
      movements = MovementsDummy(seed: [aMovement(delta: 12)]);
      getIt.registerSingleton<MovementsRepo>(movements);
    });

    tearDown(() => getIt.reset());

    testWidgets('recording a sale writes the ledger and previews the new stock', (tester) async {
      final products = ProductsDummy(seed: [aProduct()], latency: Duration.zero);
      final cubit = ProductsCubit(
        products: products,
        movements: movements,
        counts: StockCountDummy(movements),
        bus: DataChangeBus(),
        currentUser: () => owner,
      );
      await tester.pumpWidget(BlocProvider.value(
        value: cubit,
        child: harness(MovementScreen(product: aProduct(), initialReason: MovementReason.sold)),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Now in stock: 12 bottles'), findsOneWidget);

      await tester.tap(find.text('−6'));
      await tester.pump();
      expect(find.text('Save · sold 6'), findsOneWidget);
      expect(find.text('6'), findsWidgets, reason: 'stock after saving previews 12 → 6');

      await tester.tap(find.text('Save · sold 6'));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      final stock = await tester.runAsync(() => movements.getStock('p1'));
      expect(stock, 6);
      final sale = (await tester.runAsync(() => movements.getForProduct('p1')))!.first;
      expect(sale.reason, MovementReason.sold);
      expect(sale.userName, 'Karim');
      await tester.runAsync(cubit.close);
    });
  });
}
