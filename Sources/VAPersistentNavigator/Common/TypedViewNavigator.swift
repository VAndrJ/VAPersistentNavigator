//
//  TypedViewNavigator.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 4/5/25.
//

import Combine
import Foundation

/// A class representing a navigator that manages navigation states and presentations.
@MainActor
public final class TypedViewNavigator<
    Destination: Hashable,
    TabItemTag: Hashable,
    SheetTag: Hashable
>: BaseNavigator, Identifiable, @preconcurrency Equatable, @preconcurrency CustomDebugStringConvertible {
    public static func == (lhs: TypedViewNavigator, rhs: TypedViewNavigator) -> Bool {
        return lhs.id == rhs.id
    }

    public let id: UUID
    public var _onReplaceInitialNavigator: ((_ newNavigator: TypedViewNavigator) -> Void)?
    public let rootSubj: CurrentValueSubject<Destination?, Never>
    public let selectedTabSubj: CurrentValueSubject<TabItemTag?, Never>
    public private(set) var tabItem: TabItemTag?
    public let tabs: [TypedViewNavigator]
    public let destinationsSubj: CurrentValueSubject<[Destination], Never>
    public let childSubj: CurrentValueSubject<TypedViewNavigator?, Never>
    public let kind: NavigatorKind
    public let presentation: TypedNavigatorPresentation<SheetTag>
    public weak var parent: TypedViewNavigator?
    public var debugDescription: String {
        let root = if let root { String(describing: root) } else { "nil" }
        let tabItem = if let tabItem { String(describing: tabItem) } else { "nil" }

        return "\(Self.self), kind: \(kind), root: \(root), tabs: \(tabs), presentation: \(presentation), tabItem: \(tabItem)"
    }
    public var childCancellable: AnyCancellable?
    public var bag: Set<AnyCancellable> = []
    public var onDeinit: (() -> Void)?

    private let _storeSubj = PassthroughSubject<Void, Never>()

    public required init(
        id: UUID,
        root: Destination?, // ignored when kind == .tabView
        destinations: [Destination],
        presentation: TypedNavigatorPresentation<SheetTag>,
        tabItem: TabItemTag?,
        kind: NavigatorKind,
        tabs: [TypedViewNavigator],
        selectedTab: TabItemTag?,
        child: TypedViewNavigator?
    ) {
        self.id = id
        self.rootSubj = .init(root)
        self.destinationsSubj = .init(destinations)
        self.tabItem = tabItem
        self.kind = kind
        self.tabs = tabs
        self.presentation = presentation
        self.childSubj = .init(child)
        self.selectedTabSubj = .init(selectedTab)

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

extension TypedViewNavigator: PersistentNavigator, @preconcurrency Codable where Destination: PersistentDestination, TabItemTag: PersistentTabItemTag, SheetTag: PersistentSheetTag {
    public var storeSubj: PassthroughSubject<Void, Never> { _storeSubj }

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

    public convenience init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.init(
            id: try container.decode(UUID.self, forKey: .id),
            root: try container.decodeIfPresent(Destination.self, forKey: .root),
            destinations: try container.decode([Destination].self, forKey: .destinations),
            presentation: try container.decode(TypedNavigatorPresentation.self, forKey: .presentation),
            tabItem: try container.decodeIfPresent(TabItemTag.self, forKey: .tabItem),
            kind: try container.decode(NavigatorKind.self, forKey: .kind),
            tabs: try container.decode([TypedViewNavigator].self, forKey: .tabs),
            selectedTab: try container.decodeIfPresent(TabItemTag.self, forKey: .selectedTab),
            child: try container.decodeIfPresent(TypedViewNavigator.self, forKey: .navigator)
        )
    }
}
