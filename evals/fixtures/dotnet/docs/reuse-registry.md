# Reuse Registry

## Functions · Domain
| Name | Path | Purpose | API | Used by | Notes |
|---|---|---|---|---|---|
| OrderService.OrderTotalLabel | src/Billing/OrderService.cs | Label an order total | `(IEnumerable<(long Cents, int Quantity)>) -> string` | 2 | pure |
| InvoiceService.AmountDueLabel | src/Billing/InvoiceService.cs | Label an invoice amount due | `(IEnumerable<long>) -> string` | 0 | pure |