import 'package:equatable/equatable.dart';
import '../../data/models/product.dart';

class ProductResolution extends Equatable {
  final Product winner;

  /// Set only when both sides really differ, so the loss is worth reporting.
  final Product? loser;

  const ProductResolution(this.winner, [this.loser]);

  @override
  List<Object?> get props => [winner, loser];
}

/// Last-write-wins on `updatedAt`. Ties go to the server so every device
/// converges on the same row.
///
/// Safe for product metadata because a rename is a whole value: the later one
/// is what the shop meant. It would not be safe for quantities — two devices
/// each selling one item would overwrite each other and lose a sale — which is
/// why stock lives in the append-only movement ledger instead.
ProductResolution resolveProductConflict({required Product local, required Product remote}) {
  final localWins = local.updatedAt.isAfter(remote.updatedAt);
  final winner = localWins ? local : remote;
  final loser = localWins ? remote : local;
  return ProductResolution(winner, _sameContent(local, remote) ? null : loser);
}

bool _sameContent(Product a, Product b) =>
    a.name == b.name &&
    a.barcode == b.barcode &&
    a.unit == b.unit &&
    a.reorderPoint == b.reorderPoint &&
    a.imageUrl == b.imageUrl &&
    a.deleted == b.deleted;
