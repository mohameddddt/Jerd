// End-to-end: sign in, open a product, record a sale, and watch the list and
// the alert badge update together.
//
//   flutter test integration_test -d windows      (or an Android device)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jerd/app.dart';
import 'package:jerd/di/service_locator.dart';
import 'package:jerd/presentation/widgets/product_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('login → sell the last olive oil → it shows as out of stock', (tester) async {
    SharedPreferences.setMockInitialValues({'language': 'en', 'theme': 'light'});
    await resetServiceLocator();
    await initMyApp(source: DataSource.dummy);

    await tester.pumpWidget(const JerdApp());
    await tester.pumpAndSettle();

    // The login form is pre-filled with the demo owner in offline builds.
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('Products'), findsWidgets);
    final oil = find.widgetWithText(ProductCard, 'Olive oil 1L');
    expect(oil, findsOneWidget);
    expect(find.descendant(of: oil, matching: find.text('Low · reorder at 6')), findsOneWidget);

    await tester.tap(oil);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sold'));
    await tester.pumpAndSettle();

    // Three in stock: + twice from 1 makes 3.
    await tester.tap(find.byTooltip('Increase'));
    await tester.tap(find.byTooltip('Increase'));
    await tester.pump();
    await tester.tap(find.text('Save · sold 3'));
    await tester.pumpAndSettle();

    expect(find.text('Movement recorded.'), findsOneWidget);
    expect(find.text('Out of stock'), findsWidgets);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.widgetWithText(ProductCard, 'Olive oil 1L'), matching: find.text('Out of stock')),
        findsOneWidget);
  });
}
