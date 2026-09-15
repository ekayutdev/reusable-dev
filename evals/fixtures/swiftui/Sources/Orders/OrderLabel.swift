import SwiftUI

func formatMoney(_ cents: Int) -> String {
    let sign = cents < 0 ? "-" : ""
    let value = abs(cents)
    return "\(sign)$\(value / 100).\(String(format: "%02d", value % 100))"
}

public func orderTotalLabel(_ lines: [(cents: Int, quantity: Int)]) -> String {
    let total = lines.reduce(0) { $0 + $1.cents * $1.quantity }
    return "Order total: \(formatMoney(total))"
}

public struct OrderTotalView: View {
    let lines: [(cents: Int, quantity: Int)]

    public init(lines: [(cents: Int, quantity: Int)]) {
        self.lines = lines
    }

    public var body: some View {
        Text(orderTotalLabel(lines))
    }
}
