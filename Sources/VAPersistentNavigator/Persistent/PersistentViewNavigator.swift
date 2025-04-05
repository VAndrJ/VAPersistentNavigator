//
//  PersistentViewNavigator.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 4/3/25.
//

import Foundation
import Combine

/// A class representing a navigator that manages navigation states and presentations and can also be persisted.
@MainActor
public final class PersistentViewNavigator<
    Destination: PersistentDestination,
    TabItemTag: PersistentTabItemTag,
    SheetTag: PersistentSheetTag
>: PersistentNavigator, @preconcurrency Codable, @preconcurrency Equatable, @preconcurrency CustomDebugStringConvertible {
    public static func == (lhs: PersistentViewNavigator, rhs: PersistentViewNavigator) -> Bool {
        return lhs.id == rhs.id
    }

    public let id: UUID
    public var _onReplaceInitialNavigator: ((_ newNavigator: PersistentViewNavigator) -> Void)?
    public let rootSubj: CurrentValueSubject<Destination?, Never>
    public let selectedTabSubj: CurrentValueSubject<TabItemTag?, Never>
    public private(set) var tabItem: TabItemTag?
    public let tabs: [PersistentViewNavigator]
    public let storeSubj = PassthroughSubject<Void, Never>()
    public let destinationsSubj: CurrentValueSubject<[Destination], Never>
    public let childSubj: CurrentValueSubject<PersistentViewNavigator?, Never>
    public let kind: NavigatorKind
    public let presentation: TypedNavigatorPresentation<SheetTag>
    public weak var parent: PersistentViewNavigator?
    public var debugDescription: String {
        let root = if let root { String(describing: root) } else { "nil" }
        let tabItem = if let tabItem { String(describing: tabItem) } else { "nil" }

        return "\(Self.self), kind: \(kind), root: \(root), tabs: \(tabs), presentation: \(presentation), tabItem: \(tabItem)"
    }
    public var childCancellable: AnyCancellable?
    public var bag: Set<AnyCancellable> = []
    public var onDeinit: (() -> Void)?

    public init(
        id: UUID = .init(),
        root: Destination?, // ignored when kind == .tabView
        destinations: [Destination] = [],
        presentation: TypedNavigatorPresentation<SheetTag> = .sheet,
        tabItem: TabItemTag? = nil,
        kind: NavigatorKind = .flow,
        tabs: [PersistentViewNavigator] = [],
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

        bind()
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
        self.childSubj = .init(try container.decodeIfPresent(PersistentViewNavigator.self, forKey: .navigator))
        self.tabItem = try container.decodeIfPresent(TabItemTag.self, forKey: .tabItem)
        self.selectedTabSubj = .init(try container.decodeIfPresent(TabItemTag.self, forKey: .selectedTab))
        self.kind = try container.decode(NavigatorKind.self, forKey: .kind)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.tabs = try container.decode([PersistentViewNavigator].self, forKey: .tabs)
        self.presentation = try container.decode(TypedNavigatorPresentation.self, forKey: .presentation)

        bind()
    }

#if DEBUG
    deinit {
        guard Thread.isMainThread else { return }

        MainActor.assumeIsolated {
            onDeinit?()
            navigatorLog?(#function, debugDescription, id)
        }
    }
#endif
}
