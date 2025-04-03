//
//  SimpleViewNavigator.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 4/3/25.
//

import Foundation
import Combine

/// A class representing a navigator that manages navigation states and presentations.
@MainActor
public final class SimpleViewNavigator: @preconcurrency Identifiable, @preconcurrency Equatable, SimpleNavigator, @preconcurrency CustomDebugStringConvertible {
    public typealias Tab = AnyHashable
    public typealias Destiantion = AnyHashable

    public static func == (lhs: SimpleViewNavigator, rhs: SimpleViewNavigator) -> Bool {
        return lhs.id == rhs.id
    }

    public private(set) var id: UUID
    /// A closure that is called when the initial navigator needs to be replaced.
    public var onReplaceInitialNavigator: ((_ newNavigator: SimpleViewNavigator) -> Void)? {
        get { parent == nil ? _onReplaceInitialNavigator : parent?.onReplaceInitialNavigator }
        set {
            if parent == nil {
                _onReplaceInitialNavigator = { [weak self] navigator in
                    self?.closeToInitial()
                    //: To avoid presented TabView issue
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(100))
                        newValue?(navigator)
                    }
                }
            } else {
                parent?.onReplaceInitialNavigator = newValue
            }
        }
    }
    private var _onReplaceInitialNavigator: ((_ newNavigator: SimpleViewNavigator) -> Void)?
    public let rootSubj: CurrentValueSubject<AnyHashable?, Never>
    public let selectedTabSubj: CurrentValueSubject<AnyHashable?, Never>
    public private(set) var tabItem: AnyHashable?
    public let tabs: [SimpleViewNavigator]
    public var isRootView: Bool { destinationsSubj.value.isEmpty }
    public let destinationsSubj: CurrentValueSubject<[AnyHashable], Never>
    public let childSubj: CurrentValueSubject<SimpleViewNavigator?, Never>
    public let kind: NavigatorKind
    public let presentation: TypedNavigatorPresentation<AnyHashable>
    public private(set) weak var parent: SimpleViewNavigator?
    public var debugDescription: String {
        let root = if let root { String(describing: root) } else { "nil" }
        let tabItem = if let tabItem { String(describing: tabItem) } else { "nil" }

        return "\(Self.self), kind: \(kind), root: \(root), tabs: \(tabs), presentation: \(presentation), tabItem: \(tabItem)"
    }

    /// Initializer for a single `View` navigator.
    public convenience init(
        id: UUID = .init(),
        view: any Hashable,
        presentation: TypedNavigatorPresentation<AnyHashable> = .sheet,
        tabItem: (any Hashable)? = nil
    ) {
        self.init(
            id: id,
            root: view,
            destinations: [],
            presentation: presentation,
            tabItem: tabItem,
            kind: .singleView,
            tabs: [],
            selectedTab: nil
        )
    }

    /// Initializer for a `NavigationStack` navigator.
    public convenience init(
        id: UUID = .init(),
        root: any Hashable,
        destinations: [any Hashable] = [],
        presentation: TypedNavigatorPresentation<AnyHashable> = .sheet,
        tabItem: (any Hashable)? = nil
    ) {
        self.init(
            id: id,
            root: root,
            destinations: destinations,
            presentation: presentation,
            tabItem: tabItem,
            kind: .flow,
            tabs: [],
            selectedTab: nil
        )
    }

    /// Initializer for a `TabView` navigator.
    public convenience init(
        id: UUID = .init(),
        tabs: [SimpleViewNavigator] = [],
        presentation: TypedNavigatorPresentation<AnyHashable> = .sheet,
        selectedTab: (any Hashable)? = nil
    ) {
        self.init(
            id: id,
            root: nil,
            destinations: [],
            presentation: presentation,
            tabItem: nil,
            kind: .tabView,
            tabs: tabs,
            selectedTab: selectedTab
        )
    }

    init(
        id: UUID = .init(),
        root: (any Hashable)?, // ignored when kind == .tabView
        destinations: [any Hashable] = [],
        presentation: TypedNavigatorPresentation<AnyHashable> = .sheet,
        tabItem: (any Hashable)? = nil,
        kind: NavigatorKind = .flow,
        tabs: [SimpleViewNavigator] = [],
        selectedTab: (any Hashable)? = nil
    ) {
        self.id = id
        self.rootSubj = .init(root?.anyHashable)
        self.destinationsSubj = .init(destinations.map(\.anyHashable))
        self.tabItem = tabItem?.anyHashable
        self.kind = kind
        self.tabs = tabs
        self.presentation = presentation
        self.childSubj = .init(nil)
        self.selectedTabSubj = .init(selectedTab?.anyHashable)
    }

    public func getNavigator(data: NavigatorData) -> SimpleViewNavigator? {
        switch data {
        case let .view(view, id, presentation, tabItem):
            return SimpleViewNavigator(
                id: id,
                view: view,
                presentation: TypedNavigatorPresentation(from: presentation),
                tabItem: tabItem
            )
        case let .stack(root, id, destinations, presentation, tabItem):
            return SimpleViewNavigator(
                id: id,
                root: root,
                destinations: destinations,
                presentation: TypedNavigatorPresentation(from: presentation),
                tabItem: tabItem
            )
        case let .tab(tabs, id, presentation, selectedTab):
            return SimpleViewNavigator(
                id: id,
                tabs: tabs.compactMap { getNavigator(data: $0) },
                presentation: TypedNavigatorPresentation(from: presentation),
                selectedTab: selectedTab
            )
        }
    }

#if DEBUG
    deinit {
        guard Thread.isMainThread else { return }

        MainActor.assumeIsolated {
            navigatorLog?(#function, debugDescription, id)
        }
    }
#endif
}

extension Hashable {
    var anyHashable: AnyHashable { self }
}
