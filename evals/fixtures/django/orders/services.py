def format_money(cents: int) -> str:
    return f"${cents / 100:.2f}"


def order_total_label(lines: list[tuple[int, int]]) -> str:
    total = sum(cents * qty for cents, qty in lines)
    return f"Order total: {format_money(total)}"
