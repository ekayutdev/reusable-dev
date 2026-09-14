import { formatCurrency } from "../../shared/lib/money.ts";

export function invoiceTotal(lines: number[], currency: string): string {
  return formatCurrency(lines.reduce((a, b) => a + b, 0), currency);
}
