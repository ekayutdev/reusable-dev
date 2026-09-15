namespace Billing;

public sealed class InvoiceService
{
    public string AmountDueLabel(IEnumerable<long> amounts) => $"Amount due: {FormatMoney(amounts.Sum())}";

    private static string FormatMoney(long cents) => $"${cents / 100}.{cents % 100:00}";
}