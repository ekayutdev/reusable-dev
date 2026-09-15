function formatMoney(cents: number): string {
  return `$${(cents / 100).toFixed(2)}`;
}

export function amountDueLabel(amountsCents: number[]): string {
  return `Amount due: ${formatMoney(amountsCents.reduce((sum, cents) => sum + cents, 0))}`;
}
