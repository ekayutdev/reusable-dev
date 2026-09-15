namespace Billing;

public sealed class OrderService
{
    public string OrderTotalLabel(IEnumerable<(long Cents, int Quantity)> lines)
    {
        var total = lines.Sum(line => line.Cents * line.Quantity);
        return $"Order total: {FormatMoney(total)}";
    }

    private static string FormatMoney(long cents) => $"${cents / 100}.{cents % 100:00}";
}