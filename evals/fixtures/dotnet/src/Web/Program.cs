using Billing;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddSingleton<OrderService>();
builder.Services.AddRazorComponents();

var app = builder.Build();
app.MapGet("/orders/total", (OrderService orders) => orders.OrderTotalLabel([(1000, 2), (500, 1)]));
app.Run();