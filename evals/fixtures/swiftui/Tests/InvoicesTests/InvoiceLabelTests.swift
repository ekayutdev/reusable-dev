import Testing
@testable import Invoices

@Test func sumsAmounts() {
    #expect(amountDueLabel([100, 250]) == "Amount due: $3.50")
}
