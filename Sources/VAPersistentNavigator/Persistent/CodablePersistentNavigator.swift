//
//  CodablePersistentNavigator.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 4/3/25.
//

import Foundation
import Combine

/// A class representing a navigator that manages navigation states and presentations.
@MainActor
public final class CodablePersistentNavigator<
    Destination: PersistentDestination,
    TabItemTag: PersistentTabItemTag,
    SheetTag: PersistentSheetTag
>: PersistentNavigator, @preconcurrency Codable, @preconcurrency Equatable, @preconcurrency CustomDebugStringConvertible {
    public static func == (lhs: CodablePersistentNavigator, rhs: CodablePersistentNavigator) -> Bool {
        return lhs.id == rhs.id
    }

    public let id: UUID
    public var _onReplaceInitialNavigator: ((_ newNavigator: CodablePersistentNavigator) -> Void)?
    public let rootSubj: CurrentValueSubject<Destination?, Never>
    public let selectedTabSubj: CurrentValueSubject<TabItemTag?, Never>
    public private(set) var tabItem: TabItemTag?
    public let tabs: [CodablePersistentNavigator]
    public let storeSubj = PassthroughSubject<Void, Never>()
    public let destinationsSubj: CurrentValueSubject<[Destination], Never>
    public let childSubj: CurrentValueSubject<CodablePersistentNavigator?, Never>
    public let kind: NavigatorKind
    public let presentation: TypedNavigatorPresentation<SheetTag>
    public private(set) weak var parent: CodablePersistentNavigator?
    public var debugDescription: String {
        let root = if let root { String(describing: root) } else { "nil" }
        let tabItem = if let tabItem { String(describing: tabItem) } else { "nil" }

        return "\(Self.self), kind: \(kind), root: \(root), tabs: \(tabs), presentation: \(presentation), tabItem: \(tabItem)"
    }

    private var childCancellable: AnyCancellable?
    private var bag: Set<AnyCancellable> = []

    /// Initializer for a single `View` navigator.
    public convenience init(
        id: UUID = .init(),
        view: Destination,
        presentation: TypedNavigatorPresentation<SheetTag> = .sheet,
        tabItem: TabItemTag? = nil
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
        root: Destination,
        destinations: [Destination] = [],
        presentation: TypedNavigatorPresentation<SheetTag> = .sheet,
        tabItem: TabItemTag? = nil
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
        tabs: [CodablePersistentNavigator] = [],
        presentation: TypedNavigatorPresentation<SheetTag> = .sheet,
        selectedTab: TabItemTag? = nil
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
        root: Destination?, // ignored when kind == .tabView
        destinations: [Destination] = [],
        presentation: TypedNavigatorPresentation<SheetTag> = .sheet,
        tabItem: TabItemTag? = nil,
        kind: NavigatorKind = .flow,
        tabs: [CodablePersistentNavigator] = [],
        selectedTab: TabItemTag? = nil
    ) {
        self.id = id
        self.rootSubj = .init(root)
        self.destinationsSubj = .init(destinations)
        self.tabItem = tabItem
        self.kind = kind
        self.tabs = tabs
        self.presentation = presentation
        self.childSubj = .init(nil)
        self.selectedTabSubj = .init(selectedTab)

        rebind()
    }

    public func getNavigator(data: NavigatorData) -> CodablePersistentNavigator? {
        switch data {
        case let .view(view, id, presentation, tabItem):
            guard let destination = view as? Destination else {
                navigatorLog?("Present only the specified `Destination` type. Found: \(type(of: view)). Expecting: \(Destination.self)")

                return nil
            }

            let presentation = TypedNavigatorPresentation<SheetTag>(from: presentation)
            let tabItem = tabItem as? TabItemTag

            return .init(
                id: id,
                view: destination,
                presentation: presentation,
                tabItem: tabItem
            )
        case let .stack(root, id, destinations, presentation, tabItem):
            guard let destination = root as? Destination else {
                navigatorLog?("Present only the specified `Destination` type. Found: \(type(of: root)). Expecting: \(Destination.self)")

                return nil
            }

            let destinations = destinations.compactMap { $0 as? Destination }
            let presentation = TypedNavigatorPresentation<SheetTag>(from: presentation)
            let tabItem = tabItem as? TabItemTag

            return .init(
                id: id,
                root: destination,
                destinations: destinations,
                presentation: presentation,
                tabItem: tabItem
            )
        case let .tab(tabs, id, presentation, selectedTab):
            let presentation = TypedNavigatorPresentation<SheetTag>(from: presentation)
            let selectedTab = selectedTab as? TabItemTag

            return .init(
                id: id,
                tabs: tabs.compactMap { getNavigator(data: $0) },
                presentation: presentation,
                selectedTab: selectedTab
            )
        }
    }

    enum CodingKeys: String, CodingKey {
        case root
        case destinations
        case navigator
        case tabItem
        case selectedTab
        case kind
        case id
        case tabs
        case presentation
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(rootSubj.value, forKey: .root)
        try container.encode(destinationsSubj.value, forKey: .destinations)
        try container.encodeIfPresent(childSubj.value, forKey: .navigator)
        try container.encodeIfPresent(tabItem, forKey: .tabItem)
        try container.encodeIfPresent(selectedTabSubj.value, forKey: .selectedTab)
        try container.encode(kind, forKey: .kind)
        try container.encode(id, forKey: .id)
        try container.encode(tabs, forKey: .tabs)
        try container.encode(presentation, forKey: .presentation)
    }

    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.rootSubj = .init(try container.decodeIfPresent(Destination.self, forKey: .root))
        self.destinationsSubj = .init(try container.decode([Destination].self, forKey: .destinations))
        self.childSubj = .init(try container.decodeIfPresent(CodablePersistentNavigator.self, forKey: .navigator))
        self.tabItem = try container.decodeIfPresent(TabItemTag.self, forKey: .tabItem)
        self.selectedTabSubj = .init(try container.decodeIfPresent(TabItemTag.self, forKey: .selectedTab))
        self.kind = try container.decode(NavigatorKind.self, forKey: .kind)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.tabs = try container.decode([CodablePersistentNavigator].self, forKey: .tabs)
        self.presentation = try container.decode(TypedNavigatorPresentation.self, forKey: .presentation)

        rebind()
    }

    private func rebind() {
        bag.forEach { $0.cancel() }
        bag = []

        Publishers
            .Merge3(
                destinationsSubj
                    .map { _ in },
                rootSubj
                    .map { _ in },
                selectedTabSubj
                    .map { _ in }
            )
            .sink(receiveValue: storeSubj.send)
            .store(in: &bag)
        tabs.forEach { child in
            child.parent = self
            child.storeSubj
                .sink(receiveValue: storeSubj.send)
                .store(in: &bag)
        }
        childSubj
            .sink { [weak self] in
                self?.rebindChild(child: $0)
            }
            .store(in: &bag)
    }

    private func rebindChild(child: CodablePersistentNavigator?) {
        childCancellable?.cancel()
        if let child = childSubj.value {
            child.parent = self
            childCancellable = child.storeSubj
                .sink(receiveValue: storeSubj.send)
        } else {
            childCancellable = nil
        }
        storeSubj.send(())
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
