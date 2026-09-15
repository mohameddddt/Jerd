import 'package:flutter/material.dart';
import '../../data/models/product.dart';
import '../l10n_helpers.dart';
import '../themes/app_palette.dart';
import '../themes/status_colors_extensions.dart';
import 'ui.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final int stock;
  final VoidCallback onTap;

  const ProductCard({
    super.key,
    required this.product,
    required this.stock,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = StatusColors.of(context);
    final c = context.palette;
    final l10n = context.l10n;
    final level = stockLevel(stock, product.reorderPoint);

    return Semantics(
      button: true,
      label: '${product.name}, $stock ${product.unit}',
      excludeSemantics: true,
      child: CardBox(
        onTap: onTap,
        child: Row(
          children: [
            ProductAvatar(uuid: product.uuid, name: product.name, imageUrl: product.imageUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  switch (level) {
                    StockLevel.low => StatusBadge(
                        label: l10n.badgeLow(product.reorderPoint),
                        foreground: status.onLowStockContainer,
                        background: status.lowStockContainer,
                      ),
                    StockLevel.out => StatusBadge(
                        label: l10n.outOfStock,
                        foreground: status.onSoldOutContainer,
                        background: status.soldOutContainer,
                      ),
                    StockLevel.ok => Text(
                        product.barcode,
                        style: TextStyle(fontSize: 13, color: c.textSecondary, fontFeatures: tabularFigures),
                      ),
                  },
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$stock',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    fontFeatures: tabularFigures,
                    color: stockNumberColor(context, level),
                  ),
                ),
                Text(product.unit, style: TextStyle(fontSize: 12, color: c.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
