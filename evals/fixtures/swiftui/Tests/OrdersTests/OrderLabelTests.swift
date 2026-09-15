import Testing
@testable import Orders

@Test func sumsLines() {
    #expect(orderTotalLabel([(cents: 1000, quantity: 2), (cents: 500, quantity: 1)]) == "Order total: $25.00")
}
