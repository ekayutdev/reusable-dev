import SwiftUI

func formatMoney(_ cents: Int) -> String {
    let sign = cents < 0 ? "-" : ""
    let value = abs(cents)
    return "\(sign)$\(value / 100).\(String(format: "%02d", value % 100))"
}

public func amountDueLabel(_ amounts: [Int]) -> String {
    "Amount due: \(formatMoney(amounts.reduce(0, +)))"
}

public struct AmountDueView: View {
    let amounts: [Int]

    public init(amounts: [Int]) {
        self.amounts = amounts
    }

    public var body: some View {
        Text(amountDueLabel(amounts))
    }
}
