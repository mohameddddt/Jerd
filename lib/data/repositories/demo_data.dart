import '../models/app_user.dart';
import '../models/movement.dart';
import '../models/product.dart';

/// Sample shop used by the dummy repositories and the offline demo login.
abstract final class DemoData {
  static const shopId = 'demo-shop';
  static const password = '123456';

  static const owner = AppUser(
    id: 'demo-karim',
    name: 'Karim',
    email: 'karim@example.com',
    role: UserRole.owner,
    shopId: shopId,
    shopName: 'My shop',
  );

  static const staff = AppUser(
    id: 'demo-amina',
    name: 'Amina',
    email: 'amina@example.com',
    role: UserRole.staff,
    shopId: shopId,
    shopName: 'My shop',
  );

  static const users = [owner, staff];

  static List<Product> products() {
    final at = DateTime.now().subtract(const Duration(days: 3));
    Product item(String uuid, String barcode, String name, String unit, int reorder) => Product(
          uuid: uuid,
          barcode: barcode,
          name: name,
          unit: unit,
          reorderPoint: reorder,
          updatedAt: at,
          updatedBy: owner.name,
        );
    return [
      item('0b7c1c9e-0001-4a55-9a53-000000000001', '6130000100010', 'Olive oil 1L', 'bottles', 6),
      item('0b7c1c9e-0002-4a55-9a53-000000000002', '6130000100027', 'Mineral water 1.5L', 'bottles', 12),
      item('0b7c1c9e-0003-4a55-9a53-000000000003', '6130000100034', 'Sugar 1kg', 'pcs', 8),
      item('0b7c1c9e-0004-4a55-9a53-000000000004', '6130000100041', 'Green tea 250g', 'boxes', 8),
      item('0b7c1c9e-0005-4a55-9a53-000000000005', '6130000100058', 'Pasta 500g', 'pcs', 10),
      item('0b7c1c9e-0006-4a55-9a53-000000000006', '6130000100065', 'Semolina 1kg', 'bags', 10),
    ];
  }

  static List<Movement> movements() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final ids = products().map((p) => p.uuid).toList();
    var n = 0;
    Movement m(int product, int delta, MovementReason reason, DateTime at,
            {AppUser user = owner, String? note}) =>
        Movement(
          uuid: '5d1e0a7f-0000-4000-8000-${(++n).toString().padLeft(12, '0')}',
          productUuid: ids[product],
          delta: delta,
          reason: reason,
          note: note,
          createdAt: at,
          userId: user.id,
          userName: user.name,
          synced: true,
        );
    final monday = today.subtract(const Duration(days: 3));
    final yesterday = today.subtract(const Duration(days: 1));
    return [
      m(0, 10, MovementReason.received, monday.add(const Duration(hours: 9, minutes: 12))),
      m(0, -2, MovementReason.adjusted, yesterday.add(const Duration(hours: 17, minutes: 20)),
          note: '2 bottles broken'),
      m(0, -4, MovementReason.sold, today.add(const Duration(hours: 8, minutes: 40))),
      m(0, -1, MovementReason.sold, today.add(const Duration(hours: 10, minutes: 5)), user: staff),
      m(1, 60, MovementReason.received, monday.add(const Duration(hours: 9))),
      m(1, -12, MovementReason.sold, yesterday.add(const Duration(hours: 18))),
      m(2, 30, MovementReason.received, monday.add(const Duration(hours: 9, minutes: 30))),
      m(2, -9, MovementReason.sold, yesterday.add(const Duration(hours: 12))),
      m(3, 12, MovementReason.received, monday.add(const Duration(hours: 10))),
      m(3, -7, MovementReason.sold, today.add(const Duration(hours: 9)), user: staff),
      m(4, 40, MovementReason.received, monday.add(const Duration(hours: 10, minutes: 30))),
      m(4, -4, MovementReason.sold, yesterday.add(const Duration(hours: 16))),
      m(5, 15, MovementReason.received, monday.add(const Duration(hours: 11))),
      m(5, -15, MovementReason.sold, yesterday.add(const Duration(hours: 19))),
    ];
  }
}
