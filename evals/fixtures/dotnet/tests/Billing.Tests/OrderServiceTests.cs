namespace Billing.Tests;

public class OrderServiceTests
{
    [Fact]
    public void SumsLines() =>
        Assert.Equal("Order total: $25.00", new OrderService().OrderTotalLabel([(1000, 2), (500, 1)]));
}
