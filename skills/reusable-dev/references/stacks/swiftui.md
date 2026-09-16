<!-- researched 2026-09-15: SwiftUI (developer.apple.com/documentation/swiftui: View, ViewModifier, ButtonStyle, ViewBuilder, Binding, State, Environment, Observable, FocusState), Swift 6.3.3 toolchain arm64-apple-macosx28.0 (typed throws, SE-0413), swift-testing 1902 (developer.apple.com/documentation/testing), SwiftPM (docs.swift.org/package-manager) -->
# Stack: swiftui

SwiftUI views plus SwiftPM targets on Apple platforms. No language core file — the general rules plus this reference apply.

## Detection
`Package.swift` or `*.xcodeproj` present and `import SwiftUI` in a source file (detection row 8). Swift without SwiftUI → ecosystem `swift` (general rules).

## Reuse units
- Small `View` struct: one view per file, `Sources/<Target>/ShipmentRowView.swift` (PascalCase, `View` suffix).
- `ViewModifier` + `View` extension: a reusable modifier chain, applied as `.cardStyle()` (developer.apple.com/documentation/swiftui, ViewModifier).
- `ButtonStyle` / `LabelStyle`: shared look applied via `.buttonStyle(...)` (developer.apple.com/documentation/swiftui, View styles).
- `@Observable` model: a plain class with the `@Observable` macro, one concern per file (developer.apple.com/documentation/swiftui, Managing model data in your app).
- Swift Package target: `DesignSystem`, `Shared` declared in `Package.swift`, imported by feature targets (docs.swift.org/package-manager, Targets and Products).

## Paths
- Shared views, styles, modifiers: `Sources/DesignSystem`; pure functions: `Sources/Shared` (no SwiftUI import); feature targets per domain (`Sources/Shipments`, `Sources/Reports`).
- Xcode apps: local packages under `Packages/` with the same target layout.
- Skip `.build/` and `DerivedData/` — build output, never a reuse source.

## Component idioms
- C3 variants: an `enum` passed to a style — one component, no per-look copies (developer.apple.com/documentation/swiftui, ButtonStyle):
```swift
struct BrandButtonStyle: ButtonStyle {
    enum Variant { case primary, destructive }
    let variant: Variant
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline)
            .foregroundStyle(variant == .destructive ? Color.red : Color.blue)
    }
}
extension ButtonStyle where Self == BrandButtonStyle {
    static func brand(_ variant: BrandButtonStyle.Variant) -> Self { .init(variant: variant) }
}
// .buttonStyle(.brand(.destructive))
```
- C4 content: `@ViewBuilder` closure parameters, never a label string:
```swift
struct ReportCard<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View { VStack(alignment: .leading) { content }.padding() }
}
```
- C5: no refs — callers apply modifiers to the returned view. Focus: take a `FocusState<...>.Binding` parameter the caller passes as `$focus`.
- C6: controlled = `Binding<Value>` parameter; uncontrolled = internal `@State` with an initial value:
```swift
struct ShipmentFilter: View {
    let query: Binding<String>        // controlled
    // @State private var query = "" // uncontrolled
}
```

## Logic idioms
- F2: inject dependencies via the initializer, or a custom `EnvironmentValues` entry with `@Entry` (developer.apple.com/documentation/swiftui, Environment):
```swift
extension EnvironmentValues {
    @Entry var shipmentGateway: ShipmentGateway = .default
}
// in a view: @Environment(\.shipmentGateway) private var gateway
```
- F6: `throws` with typed domain errors — `throws(ShipmentError)` in Swift 6 (docs.swift.org, Error Handling; SE-0413); views map errors to UI state:
```swift
enum ShipmentError: Error { case lateDelivery }
func loadShipment() throws(ShipmentError) -> Shipment { /* ... */ }
// view: do { model.shipment = try loadShipment() } catch { model.status = .failed }
```
- Shared targets export `public` API only; `Sources/Shared` keeps pure functions with no SwiftUI import.

## Testing
- Swift Testing: `@Test`, `#expect`, `@Suite` (developer.apple.com/documentation/testing, Defining test functions).
- One suite or test: `swift test --filter <Suite or test>` (docs.swift.org/package-manager). Xcode projects: `xcodebuild test -scheme <scheme> -destination <dest>` (iOS simulators need `-destination`).
- Test view logic through models and pure functions, not view bodies.
- Use exactly what config `commands.test` specifies; if it is empty, run no test command and report `T2 skipped (no command)` (commands above are examples for filling the config).

## Stack-specific anti-patterns
- Logic in `body` — move to a model or pure function; body renders.
- Copy-pasted modifier chains — extract a `ViewModifier` + `View` extension.
- Creating an `@ObservedObject` or `@Observable` model in a view's init or body without `@StateObject` / `@State` — the view does not own it and it is recreated on redraw; own it with `@StateObject` / `@State`, or inject it from a parent.
- Massive views — split into small `View` structs and `@ViewBuilder` sections.
- A shared target importing feature targets — dependencies point feature → shared, never back.
