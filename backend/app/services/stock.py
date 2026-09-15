"""Stock is the sum of the ledger — here exactly as in the app."""

from sqlalchemy import func, select

from ..db import movements, products


def stock_for(conn, shop_id: str, product_uuids=None) -> dict[str, int]:
    query = (
        select(movements.c.product_uuid, func.coalesce(func.sum(movements.c.delta), 0))
        .where(movements.c.shop_id == shop_id)
        .group_by(movements.c.product_uuid)
    )
    if product_uuids is not None:
        query = query.where(movements.c.product_uuid.in_(list(product_uuids)))
    return {uuid: int(total) for uuid, total in conn.execute(query)}


def low_stock(conn, shop_id: str) -> list[dict]:
    """Items at or below their reorder point, most urgent first."""
    stocks = stock_for(conn, shop_id)
    rows = conn.execute(
        select(products).where(products.c.shop_id == shop_id, products.c.deleted.is_(False))
    ).mappings()
    items = []
    for row in rows:
        stock = stocks.get(row["uuid"], 0)
        if stock <= 0 or stock <= row["reorder_point"]:
            urgency = 0 if stock <= 0 else stock / max(row["reorder_point"], 1)
            items.append({"product": dict(row), "stock": stock, "urgency": urgency})
    items.sort(key=lambda item: (item["urgency"], item["product"]["name"].lower()))
    return items


def crossed_reorder_point(before: int, after: int, reorder_point: int) -> bool:
    """True only on the transition, so a shop gets one push per item, not one per sale."""
    return before > reorder_point and after <= reorder_point
