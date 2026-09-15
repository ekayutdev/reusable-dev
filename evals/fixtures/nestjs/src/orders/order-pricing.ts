function formatMoney(cents: number): string {
  return `$${(cents / 100).toFixed(2)}`;
}

export function orderTotalLabel(lines: { cents: number; qty: number }[]): string {
  const total = lines.reduce((sum, line) => sum + line.cents * line.qty, 0);
  return `Order total: ${formatMoney(total)}`;
}
