import SwiftUI

public func probe() -> String {
    "ok"
}

public struct ProbeView: View {
    public init() {}

    public var body: some View {
        Text(probe())
    }
}
