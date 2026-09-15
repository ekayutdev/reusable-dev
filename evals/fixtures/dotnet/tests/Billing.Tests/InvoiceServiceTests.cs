namespace Billing.Tests;

public class InvoiceServiceTests
{
    [Fact]
    public void SumsAmounts() =>
        Assert.Equal("Amount due: $3.50", new InvoiceService().AmountDueLabel([100, 250]));
}
