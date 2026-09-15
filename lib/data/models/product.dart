import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final String uuid;
  final String barcode;
  final String name;
  final String unit;
  final int reorderPoint;

  /// Remote URL once uploaded; a local file path while the photo waits for sync.
  final String? imageUrl;
  final DateTime updatedAt;

  /// Display name of whoever made the last change — shown in conflict reports.
  final String updatedBy;
  final bool deleted;

  const Product({
    required this.uuid,
    required this.barcode,
    required this.name,
    required this.unit,
    required this.reorderPoint,
    this.imageUrl,
    required this.updatedAt,
    this.updatedBy = '',
    this.deleted = false,
  });

  bool get hasLocalImage =>
      imageUrl != null && imageUrl!.isNotEmpty && !imageUrl!.startsWith('http');

  Product copyWith({
    String? uuid,
    String? barcode,
    String? name,
    String? unit,
    int? reorderPoint,
    String? imageUrl,
    bool clearImage = false,
    DateTime? updatedAt,
    String? updatedBy,
    bool? deleted,
  }) {
    return Product(
      uuid: uuid ?? this.uuid,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      reorderPoint: reorderPoint ?? this.reorderPoint,
      imageUrl: clearImage ? null : imageUrl ?? this.imageUrl,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      deleted: deleted ?? this.deleted,
    );
  }

  /// SQLite row.
  Map<String, Object?> toMap() => {
        'uuid': uuid,
        'barcode': barcode,
        'name': name,
        'unit': unit,
        'reorder_point': reorderPoint,
        'image_url': imageUrl,
        'updated_at': updatedAt.toUtc().toIso8601String(),
        'updated_by': updatedBy,
        'deleted': deleted ? 1 : 0,
      };

  factory Product.fromMap(Map<String, Object?> map) => Product(
        uuid: map['uuid'] as String,
        barcode: map['barcode'] as String,
        name: map['name'] as String,
        unit: map['unit'] as String,
        reorderPoint: (map['reorder_point'] as num).toInt(),
        imageUrl: map['image_url'] as String?,
        updatedAt: DateTime.parse(map['updated_at'] as String).toLocal(),
        updatedBy: (map['updated_by'] as String?) ?? '',
        deleted: map['deleted'] == 1 || map['deleted'] == true,
      );

  /// API payload. Same keys as the table so the backend mirrors it.
  Map<String, Object?> toJson() => {
        ...toMap(),
        'deleted': deleted,
      };

  factory Product.fromJson(Map<String, dynamic> json) => Product.fromMap(json);

  @override
  List<Object?> get props => [
        uuid,
        barcode,
        name,
        unit,
        reorderPoint,
        imageUrl,
        updatedAt,
        updatedBy,
        deleted,
      ];
}
