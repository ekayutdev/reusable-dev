# Reuse Registry

## Functions · Domain
| Name | Path | Purpose | API | Used by | Notes |
|---|---|---|---|---|---|
| order_total_label | crates/billing/src/orders.rs | Label an order total | `(&[(i64, i64)]) -> String` | 1 | pure |
| amount_due_label | crates/billing/src/invoices.rs | Label an invoice amount due | `(&[i64]) -> String` | 0 | pure |
