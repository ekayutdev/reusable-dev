# Reuse Registry

## Functions · Domain
| Name | Path | Purpose | API | Used by | Notes |
|---|---|---|---|---|---|
| orderTotalLabel | Sources/Orders/OrderLabel.swift | Label an order total | `(_ lines: [(cents: Int, quantity: Int)]) -> String` | 1 | pure |
| amountDueLabel | Sources/Invoices/InvoiceLabel.swift | Label an invoice amount due | `(_ amounts: [Int]) -> String` | 1 | pure |
