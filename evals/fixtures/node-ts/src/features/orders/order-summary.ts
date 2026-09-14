import { formatCurrency } from "../../shared/lib/money.ts";

export function orderSummary(items: { price: number; qty: number }[]): string {
  const total = items.reduce((sum, i) => sum + i.price * i.qty, 0);
  return `Total: ${formatCurrency(total, "USD")}`;
}
