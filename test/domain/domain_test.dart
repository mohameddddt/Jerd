import 'package:flutter_test/flutter_test.dart';
import 'package:jerd/data/models/movement.dart';
import 'package:jerd/data/models/product.dart';
import 'package:jerd/logic/domain/daily_summary.dart';
import 'package:jerd/logic/domain/low_stock.dart';
import 'package:jerd/logic/domain/product_conflict.dart';
import 'package:jerd/logic/domain/product_filter.dart';
import 'package:jerd/logic/domain/reconcile_count.dart';
import 'package:jerd/logic/domain/stock_from_ledger.dart';
import 'package:jerd/logic/domain/sync_backoff.dart';
import 'package:jerd/logic/domain/validators.dart';

Movement move(String product, int delta,
        {MovementReason reason = MovementReason.adjusted, DateTime? at, String uuid = ''}) =>
    Movement(
      uuid: uuid.isEmpty ? '$product-$delta-${at?.millisecondsSinceEpoch}' : uuid,
      productUuid: product,
      delta: delta,
      reason: reason,
      createdAt: at ?? DateTime(2026, 9, 14, 10),
      userId: 'u1',
    );

Product product(String uuid,
        {String name = 'Item', int reorder = 5, DateTime? updatedAt, String barcode = '1234'}) =>
    Product(
      uuid: uuid,
      barcode: barcode,
      name: name,
      unit: 'pcs',
      reorderPoint: reorder,
      updatedAt: updatedAt ?? DateTime(2026, 9, 14),
    );

void main() {
  group('stockFromLedger', () {
    test('an empty ledger is zero', () {
      expect(stockFromLedger(const []), 0);
    });

    test('sums received, sold and adjustments', () {
      final ledger = [
        move('p', 12, reason: MovementReason.received),
        move('p', -1, reason: MovementReason.sold),
        move('p', -2),
      ];
      expect(stockFromLedger(ledger), 9);
    });

    test('merging two devices keeps both sales (no lost update)', () {
      final base = [move('p', 10, reason: MovementReason.received, uuid: 'a')];
      final deviceA = [...base, move('p', -1, reason: MovementReason.sold, uuid: 'b')];
      final deviceB = [...base, move('p', -1, reason: MovementReason.sold, uuid: 'c')];
      final merged = {for (final m in [...deviceA, ...deviceB]) m.uuid: m}.values;
      expect(stockFromLedger(merged), 8);
    });

    test('stockByProduct splits a mixed ledger', () {
      final ledger = [move('a', 3), move('b', 5), move('a', -1)];
      expect(stockByProduct(ledger), {'a': 2, 'b': 5});
    });

    test('runningBalances walks back from current stock', () {
      final newestFirst = [move('p', -1), move('p', -4), move('p', 10)];
      expect(runningBalances(newestFirst, 5), [5, 6, 10]);
    });
  });

  group('lowStock', () {
    test('stockLevel boundaries', () {
      expect(stockLevel(0, 5), StockLevel.out);
      expect(stockLevel(-2, 5), StockLevel.out);
      expect(stockLevel(5, 5), StockLevel.low);
      expect(stockLevel(6, 5), StockLevel.ok);
      expect(stockLevel(1, 0), StockLevel.ok);
    });

    test('lists only items at or below the reorder point, most urgent first', () {
      final products = [
        product('oil', name: 'Olive oil', reorder: 6),
        product('tea', name: 'Green tea', reorder: 8),
        product('semolina', name: 'Semolina', reorder: 10),
        product('water', name: 'Water', reorder: 5),
      ];
      final stocks = {'oil': 3, 'tea': 5, 'semolina': 0, 'water': 48};
      final items = lowStockItems(products, stocks);
      expect(items.map((i) => i.product.uuid), ['semolina', 'oil', 'tea']);
    });

    test('deleted products never alert', () {
      final items = lowStockItems([product('x').copyWith(deleted: true)], {'x': 0});
      expect(items, isEmpty);
    });
  });

  group('reconcileCount', () {
    test('returns only differences, in counting order', () {
      final diffs = reconcileCount(
        expected: {'sugar': 21, 'water': 48, 'tea': 5, 'pasta': 36},
        counted: {'sugar': 18, 'pasta': 36, 'water': 50, 'tea': 4},
      );
      expect(diffs.map((d) => (d.productUuid, d.delta)), [
        ('sugar', -3),
        ('water', 2),
        ('tea', -1),
      ]);
    });

    test('uncounted products are untouched; unknown products expect zero', () {
      final diffs = reconcileCount(expected: {'a': 4}, counted: {'b': 2});
      expect(diffs.single.productUuid, 'b');
      expect(diffs.single.delta, 2);
    });

    test('adjustments bring the ledger to the counted quantity', () {
      final ledger = [move('sugar', 21, reason: MovementReason.received)];
      final diffs = reconcileCount(expected: stockByProduct(ledger), counted: {'sugar': 18});
      var n = 0;
      final batch = adjustmentsForCount(
        differences: diffs,
        newUuid: () => 'adj-${n++}',
        now: DateTime(2026, 9, 14),
        userId: 'u1',
        userName: 'Karim',
      );
      expect(batch.single.reason, MovementReason.counted);
      expect(stockFromLedger([...ledger, ...batch]), 18);
    });
  });

  group('syncBackoff', () {
    test('grows exponentially and caps', () {
      expect(backoffFor(0), Duration.zero);
      expect(backoffFor(1), const Duration(seconds: 30));
      expect(backoffFor(2), const Duration(minutes: 1));
      expect(backoffFor(4), const Duration(minutes: 4));
      expect(backoffFor(20), maxBackoff);
      expect(backoffFor(1000), maxBackoff);
    });

    test('isRetryDue respects the wait', () {
      final last = DateTime(2026, 9, 14, 10);
      expect(isRetryDue(attempts: 0, lastAttemptAt: null, now: last), isTrue);
      expect(isRetryDue(attempts: 2, lastAttemptAt: last, now: last.add(const Duration(seconds: 59))), isFalse);
      expect(isRetryDue(attempts: 2, lastAttemptAt: last, now: last.add(const Duration(minutes: 1))), isTrue);
    });
  });

  group('resolveProductConflict', () {
    test('later updatedAt wins and the loser is reported', () {
      final local = product('p', name: 'Spaghetti 500g', updatedAt: DateTime(2026, 9, 14, 10, 58));
      final remote = product('p', name: 'Pasta 500g', updatedAt: DateTime(2026, 9, 14, 11, 2));
      final result = resolveProductConflict(local: local, remote: remote);
      expect(result.winner.name, 'Pasta 500g');
      expect(result.loser?.name, 'Spaghetti 500g');
    });

    test('ties go to the server', () {
      final at = DateTime(2026, 9, 14);
      final result = resolveProductConflict(
        local: product('p', name: 'A', updatedAt: at),
        remote: product('p', name: 'B', updatedAt: at),
      );
      expect(result.winner.name, 'B');
    });

    test('identical content is not a conflict', () {
      final result = resolveProductConflict(
        local: product('p', updatedAt: DateTime(2026, 9, 14, 12)),
        remote: product('p', updatedAt: DateTime(2026, 9, 14, 9)),
      );
      expect(result.loser, isNull);
    });
  });

  group('validators', () {
    test('email and password', () {
      expect(validateEmail(''), FieldError.required);
      expect(validateEmail('karim@'), FieldError.invalidEmail);
      expect(validateEmail(' karim@example.com '), isNull);
      expect(validatePassword('12345'), FieldError.passwordTooShort);
      expect(validatePassword('123456'), isNull);
    });

    test('product fields', () {
      expect(validateProductName('  '), FieldError.required);
      expect(validateProductName('x' * 81), FieldError.tooLong);
      expect(validateBarcode('61300A'), FieldError.invalidBarcode);
      expect(validateBarcode('6130000100034'), isNull);
      expect(validateReorderPoint('-1'), FieldError.negative);
      expect(validateReorderPoint('abc'), FieldError.invalidNumber);
      expect(validateReorderPoint('0'), isNull);
    });

    test('quantities', () {
      expect(validateQuantity(0, allowNegative: true), FieldError.zeroQuantity);
      expect(validateQuantity(-2, allowNegative: false), FieldError.negative);
      expect(validateQuantity(-2, allowNegative: true), isNull);
    });
  });

  group('filterProducts', () {
    final products = [
      product('a', name: 'Olive oil', barcode: '6130001', reorder: 6),
      product('b', name: 'Sugar', barcode: '6130002'),
      product('c', name: 'Semolina', barcode: '6130003', reorder: 10),
    ];
    final stocks = {'a': 3, 'b': 21, 'c': 0};

    test('search matches name or barcode', () {
      expect(filterProducts(products: products, stocks: stocks, query: 'OIL', filter: ProductFilter.all).single.uuid, 'a');
      expect(filterProducts(products: products, stocks: stocks, query: '0002', filter: ProductFilter.all).single.uuid, 'b');
    });

    test('filters by level and counts', () {
      expect(filterProducts(products: products, stocks: stocks, query: '', filter: ProductFilter.out).single.uuid, 'c');
      expect(countLevel(products, stocks, StockLevel.low), 1);
    });
  });

  test('summarizeDay only counts that day', () {
    final day = DateTime(2026, 9, 14);
    final summary = summarizeDay([
      move('p', 12, reason: MovementReason.received, at: DateTime(2026, 9, 14, 8)),
      move('p', -3, reason: MovementReason.sold, at: DateTime(2026, 9, 14, 12)),
      move('p', -1, reason: MovementReason.counted, at: DateTime(2026, 9, 14, 18)),
      move('p', -9, reason: MovementReason.sold, at: DateTime(2026, 9, 13, 18)),
    ], day);
    expect(summary, const DailySummary(received: 12, sold: 3, adjusted: -1, movements: 3));
  });
}
