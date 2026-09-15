def format_money(cents: int) -> str:
    return f"${cents / 100:.2f}"


def amount_due_label(amounts: list[int]) -> str:
    return f"Amount due: {format_money(sum(amounts))}"
