// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Billing",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "Orders"),
        .target(name: "Invoices"),
        .target(name: "Customers"),
        .testTarget(name: "OrdersTests", dependencies: ["Orders"]),
        .testTarget(name: "InvoicesTests", dependencies: ["Invoices"]),
    ]
)
