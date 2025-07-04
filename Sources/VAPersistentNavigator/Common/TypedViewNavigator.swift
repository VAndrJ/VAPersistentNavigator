//
//  TypedViewNavigator.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 4/5/25.
//

import Combine
import Foundation

/// A concrete implementation of `BaseNavigator` for managing navigation state in a SwiftUI application.
///
/// `TypedViewNavigator` handles view-based navigation by keeping track of the root view, child navigators, presentation state,
/// navigation destinations, and tab configurations. It is fully generic over destination types, tab tags, and sheet tags,
/// providing strong type safety across navigation flows.
///
/// - Parameters:
///   - Destination: A type representing the navigable destinations in the app.
///   - TabItemTag: A type representing unique identifiers for tab items.
///   - SheetTag: A type used to differentiate between different sheet presentations.
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
    public let environmentPubl: PassthroughSubject<EnvironmentAction, Never> = .init()

    private let _storeSubj = PassthroughSubject<Void, Never>()

    /// Initializes a new instance of `TypedViewNavigator` with all required state for navigation.
    ///
    /// - Parameters:
    ///   - id: A unique identifier for the navigator instance.
    ///   - root: The initial root destination of the navigator.
    ///   - destinations: The current stack of pushed destinations.
    ///   - presentation: Presentation information such as sheet tags or full-screen cover state.
    ///   - tabItem: The tab identifier this navigator represents (if part of a tab view).
    ///   - kind: The kind of navigator (e.g., `.singleView`, `.tabView`, `.flow`).
    ///   - tabs: The list of child navigators used in a tab-based navigation setup.
    ///   - selectedTab: The currently selected tab identifier (if applicable).
    ///   - child: A reference to a currently presented child navigator (for modals or sheets).
    public required init(
        id: UUID,
        root: Destination?,
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

    deinit {
        guard Thread.isMainThread else { return }

        MainActor.assumeIsolated {
            onDeinit?()
            navigatorLog?(#function, debugDescription, id)
        }
    }
}

extension TypedViewNavigator: PersistentNavigator, @preconcurrency Codable
where Destination: PersistentDestination, TabItemTag: PersistentTabItemTag, SheetTag: PersistentSheetTag {
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
