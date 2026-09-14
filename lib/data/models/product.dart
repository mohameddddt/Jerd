class Product {
  final String uuid;
  final String barcode;
  final String name;
  final String unit;
  final int reorderPoint;
  final String? imageUrl;
  final DateTime updatedAt;
  final bool deleted;

  const Product({
    required this.uuid,
    required this.barcode,
    required this.name,
    required this.unit,
    required this.reorderPoint,
    this.imageUrl,
    required this.updatedAt,
    this.deleted = false,
  });

  Product copyWith({
    String? uuid,
    String? barcode,
    String? name,
    String? unit,
    int? reorderPoint,
    String? imageUrl,
    DateTime? updatedAt,
    bool? deleted,
  }) {
    return Product(
      uuid: uuid ?? this.uuid,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      reorderPoint: reorderPoint ?? this.reorderPoint,
      imageUrl: imageUrl ?? this.imageUrl,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
    );
  }
}
