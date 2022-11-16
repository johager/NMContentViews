import ComposableArchitecture
import Foundation
import SwiftUI

// MARK: - WithStateStore

public struct WithStateStore<ViewState, ViewAction, Content> {
    private let content: (ViewStore<ViewState, ViewAction>) -> Content
    #if DEBUG
    private let file: StaticString
    private let line: UInt
    private var prefix: String?
    private var previousState: (ViewState) -> ViewState?
    #endif
    @StateObject private var viewStore: ViewStore<ViewState, ViewAction>

    init(
        store: @autoclosure @escaping () -> Store<ViewState, ViewAction>,
        removeDuplicates isDuplicate: @escaping (ViewState, ViewState) -> Bool,
        content: @escaping (ViewStore<ViewState, ViewAction>) -> Content,
        file: StaticString = #fileID,
        line: UInt = #line)
    {
        self.content = content
        #if DEBUG
        self.file = file
        self.line = line
        var previousState: ViewState? = nil
        self.previousState = { currentState in
            defer { previousState = currentState }
            return previousState
        }
        #endif
        _viewStore = .init(wrappedValue: ViewStore(store(), removeDuplicates: isDuplicate))
    }

    /// Prints debug information to the console whenever the view is computed.
    ///
    /// - Parameter prefix: A string with which to prefix all debug messages.
    /// - Returns: A structure that prints debug messages for all computations.
    public func debug(_ prefix: String = "") -> Self {
        var view = self
        #if DEBUG
        view.prefix = prefix
        #endif
        return view
    }

    public var body: Content {
        #if DEBUG
        if let prefix = prefix {
            var stateDump = ""
            customDump(viewStore.state, to: &stateDump, indent: 2)
            let difference =
                previousState(viewStore.state)
                .map {
                    diff($0, self.viewStore.state).map { "(Changed state)\n\($0)" }
                        ?? "(No difference in state detected)"
                }
                ?? "(Initial state)\n\(stateDump)"
            func typeName(_ type: Any.Type) -> String {
                var name = String(reflecting: type)
                if let index = name.firstIndex(of: ".") {
                    name.removeSubrange(...index)
                }
                return name
            }
            print(
                """
                \(prefix.isEmpty ? "" : "\(prefix): ")\
                WithStateStore<\(typeName(ViewState.self)), \(typeName(ViewAction.self)), _>\
                @\(file):\(line) \(difference)
                """)
        }
        #endif
        return content(viewStore)
    }
}

// MARK: View

extension WithStateStore: View where Content: View {
    /// Initializes a structure that transforms a store into an observable view store in order to
    /// compute views from state.
    ///
    /// - Parameters:
    ///   - store: A store.
    ///   - toViewState: A function that transforms store state into observable view state.
    ///   - fromViewAction: A function that transforms view actions into store action.
    ///   - isDuplicate: A function to determine when two `ViewState` values are equal. When values
    ///     are equal, repeat view computations are removed,
    ///   - content: A function that can generate content from a view store.
    public init<State, Action>(
        _ store: Store<State, Action>,
        observe toViewState: @escaping (State) -> ViewState,
        send fromViewAction: @escaping (ViewAction) -> Action,
        removeDuplicates isDuplicate: @escaping (ViewState, ViewState) -> Bool,
        @ViewBuilder content: @escaping (ViewStore<ViewState, ViewAction>) -> Content,
        file: StaticString = #fileID,
        line: UInt = #line)
    {
        self.init(
            store: store.scope(state: toViewState, action: fromViewAction),
            removeDuplicates: isDuplicate,
            content: content,
            file: file,
            line: line)
    }

    /// Initializes a structure that transforms a store into an observable view store in order to
    /// compute views from state.
    ///
    /// - Parameters:
    ///   - store: A store.
    ///   - toViewState: A function that transforms store state into observable view state.
    ///   - isDuplicate: A function to determine when two `ViewState` values are equal. When values
    ///     are equal, repeat view computations are removed,
    ///   - content: A function that can generate content from a view store.
    public init<State>(
        _ store: Store<State, ViewAction>,
        observe toViewState: @escaping (State) -> ViewState,
        removeDuplicates isDuplicate: @escaping (ViewState, ViewState) -> Bool,
        @ViewBuilder content: @escaping (ViewStore<ViewState, ViewAction>) -> Content,
        file: StaticString = #fileID,
        line: UInt = #line)
    {
        self.init(
            store: store.scope(state: toViewState),
            removeDuplicates: isDuplicate,
            content: content,
            file: file,
            line: line)
    }

    /// Initializes a structure that transforms a store into an observable view store in order to
    /// compute views from store state.
    ///
    /// - Parameters:
    ///   - store: A store.
    ///   - isDuplicate: A function to determine when two `ViewState` values are equal. When values
    ///     are equal, repeat view computations are removed,
    ///   - content: A function that can generate content from a view store.
    @available(
        iOS,
        deprecated: 9999.0,
        message: "Use 'init(_:observe:removeDuplicates:content:)' to make state observation explicit.")
    @available(
        macOS,
        deprecated: 9999.0,
        message: "Use 'init(_:observe:removeDuplicates:content:)' to make state observation explicit.")
    @available(
        tvOS,
        deprecated: 9999.0,
        message: "Use 'init(_:observe:removeDuplicates:content:)' to make state observation explicit.")
    @available(
        watchOS,
        deprecated: 9999.0,
        message: "Use 'init(_:observe:removeDuplicates:content:)' to make state observation explicit.")
    public init(
        _ store: Store<ViewState, ViewAction>,
        removeDuplicates isDuplicate: @escaping (ViewState, ViewState) -> Bool,
        @ViewBuilder content: @escaping (ViewStore<ViewState, ViewAction>) -> Content,
        file: StaticString = #fileID,
        line: UInt = #line)
    {
        self.init(
            store: store,
            removeDuplicates: isDuplicate,
            content: content,
            file: file,
            line: line)
    }
}

extension WithStateStore where ViewState: Equatable, Content: View {
    /// Initializes a structure that transforms a store into an observable view store in order to
    /// compute views from equatable state.
    ///
    /// - Parameters:
    ///   - store: A store.
    ///   - toViewState: A function that transforms store state into observable view state.
    ///   - fromViewAction: A function that transforms view actions into store action.
    ///   - isDuplicate: A function to determine when two `ViewState` values are equal. When values
    ///     are equal, repeat view computations are removed,
    ///   - content: A function that can generate content from a view store.
    public init<State, Action>(
        _ store: Store<State, Action>,
        observe toViewState: @escaping (State) -> ViewState,
        send fromViewAction: @escaping (ViewAction) -> Action,
        @ViewBuilder content: @escaping (ViewStore<ViewState, ViewAction>) -> Content,
        file: StaticString = #fileID,
        line: UInt = #line)
    {
        self.init(
            store: store.scope(state: toViewState, action: fromViewAction),
            removeDuplicates: ==,
            content: content,
            file: file,
            line: line)
    }

    /// Initializes a structure that transforms a store into an observable view store in order to
    /// compute views from equatable state.
    ///
    /// - Parameters:
    ///   - store: A store.
    ///   - toViewState: A function that transforms store state into observable view state.
    ///   - isDuplicate: A function to determine when two `ViewState` values are equal. When values
    ///     are equal, repeat view computations are removed,
    ///   - content: A function that can generate content from a view store.
    public init<State>(
        _ store: Store<State, ViewAction>,
        observe toViewState: @escaping (State) -> ViewState,
        @ViewBuilder content: @escaping (ViewStore<ViewState, ViewAction>) -> Content,
        file: StaticString = #fileID,
        line: UInt = #line)
    {
        self.init(
            store: store.scope(state: toViewState),
            removeDuplicates: ==,
            content: content,
            file: file,
            line: line)
    }

    /// Initializes a structure that transforms a store into an observable view store in order to
    /// compute views from equatable store state.
    ///
    /// - Parameters:
    ///   - store: A store of equatable state.
    ///   - content: A function that can generate content from a view store.
    @available(
        iOS,
        deprecated: 9999.0,
        message: "Use 'init(_:observe:content:)' to make state observation explicit.")
    @available(
        macOS,
        deprecated: 9999.0,
        message: "Use 'init(_:observe:content:)' to make state observation explicit.")
    @available(
        tvOS,
        deprecated: 9999.0,
        message: "Use 'init(_:observe:content:)' to make state observation explicit.")
    @available(
        watchOS,
        deprecated: 9999.0,
        message: "Use 'init(_:observe:content:)' to make state observation explicit.")
    public init(
        _ store: Store<ViewState, ViewAction>,
        @ViewBuilder content: @escaping (ViewStore<ViewState, ViewAction>) -> Content,
        file: StaticString = #fileID,
        line: UInt = #line)
    {
        self.init(store, removeDuplicates: ==, content: content, file: file, line: line)
    }
}

extension WithStateStore where ViewState == Void, Content: View {
    /// Initializes a structure that transforms a store into an observable view store in order to
    /// compute views from void store state.
    ///
    /// - Parameters:
    ///   - store: A store of equatable state.
    ///   - content: A function that can generate content from a view store.
    @available(
        iOS,
        deprecated: 9999.0,
        message: "Use 'ViewStore(store).send(action)' instead of observing stateless stores.")
    @available(
        macOS,
        deprecated: 9999.0,
        message: "Use 'ViewStore(store).send(action)' instead of observing stateless stores.")
    @available(
        tvOS,
        deprecated: 9999.0,
        message: "Use 'ViewStore(store).send(action)' instead of observing stateless stores.")
    @available(
        watchOS,
        deprecated: 9999.0,
        message: "Use 'ViewStore(store).send(action)' instead of observing stateless stores.")
    public init(
        _ store: Store<ViewState, ViewAction>,
        @ViewBuilder content: @escaping (ViewStore<ViewState, ViewAction>) -> Content,
        file: StaticString = #fileID,
        line: UInt = #line)
    {
        self.init(store, removeDuplicates: ==, content: content, file: file, line: line)
    }
}

// MARK: DynamicViewContent

extension WithStateStore: DynamicViewContent
    where
    ViewState: Collection,
    Content: DynamicViewContent
{
    public typealias Data = ViewState

    public var data: ViewState {
        viewStore.state
    }
}
