import SwiftUI

/// Waits to load view until it is presented.

public struct LazyView<Content: View>: View {
    private var content: () -> Content

    public init(_ content: @autoclosure @escaping () -> Content) {
        self.content = content
    }

    public init(@ViewBuilder _ content: @escaping () -> Content) {
        self.content = content
    }

    public var body: Content {
        content()
    }
}
