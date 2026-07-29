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
>: @MainActor BaseNavigator, Identifiable, Equatable, CustomDebugStringConvertible {
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
    public let childSubj: NavigatorChildSubject<TypedViewNavigator>
    public let isAnimatedSubj: CurrentValueSubject<Bool, Never> = .init(true)
    public let kind: NavigatorKind
    public let presentation: TypedNavigatorPresentation<SheetTag>
    private weak var _parent: TypedViewNavigator?
    public var parent: TypedViewNavigator? {
        get { _parent }
        set {
            guard Self.canSet(parent: newValue, for: self) else {
                navigatorLog?(
                    "parent update rejected invalid hierarchy",
                    "navigator id: \(id)",
                    "parent id: \(newValue?.id.uuidString ?? "nil")"
                )

                return
            }

            _parent = newValue
        }
    }
    public var debugDescription: String {
        let root = if let root { String(describing: root) } else { "nil" }
        let tabItem = if let tabItem { String(describing: tabItem) } else { "nil" }

        return "\(Self.self), kind: \(kind), root: \(root), tabs: \(tabs), presentation: \(presentation), tabItem: \(tabItem)"
    }
    public var onDeinit: (() -> Void)?
    public let environmentPubl: PassthroughSubject<EnvironmentAction, Never> = .init()

    private let _storeSubj = PassthroughSubject<Void, Never>()

    private static func canSet(parent: TypedViewNavigator?, for navigator: TypedViewNavigator) -> Bool {
        if let parent {
            guard parent.childSubj.value === navigator
                || parent.tabs.contains(where: { $0 === navigator })
            else {
                return false
            }
        } else if let currentParent = navigator._parent {
            guard currentParent.childSubj.value !== navigator,
                !currentParent.tabs.contains(where: { $0 === navigator })
            else {
                return false
            }
        }

        var parent = parent
        var visited: Set<ObjectIdentifier> = []
        while let candidate = parent {
            guard visited.insert(ObjectIdentifier(candidate)).inserted,
                candidate !== navigator
            else {
                return false
            }

            parent = candidate._parent
        }

        return true
    }

    private static func validatedInitialChildren(
        tabs: [TypedViewNavigator],
        child: TypedViewNavigator?,
        parentID: UUID
    ) -> (tabs: [TypedViewNavigator], child: TypedViewNavigator?) {
        var visited: Set<ObjectIdentifier> = []
        var validatedTabs = tabs
        for tab in tabs {
            guard isValidHierarchy(
                rootedAt: tab,
                expectedParent: nil,
                visited: &visited
            ) else {
                navigatorLog?(
                    "initial tabs rejected invalid ownership",
                    "parent id: \(parentID)",
                    "tab id: \(tab.id)"
                )
                validatedTabs = []
                visited = []

                break
            }
        }

        var validatedChild: TypedViewNavigator?
        if let child {
            if isValidHierarchy(
                rootedAt: child,
                expectedParent: nil,
                visited: &visited
            ) {
                validatedChild = child
            } else {
                navigatorLog?(
                    "initial child rejected invalid ownership",
                    "parent id: \(parentID)",
                    "child id: \(child.id)"
                )
            }
        }

        return (validatedTabs, validatedChild)
    }

    private static func isValidHierarchy(
        rootedAt navigator: TypedViewNavigator,
        expectedParent: TypedViewNavigator?,
        visited: inout Set<ObjectIdentifier>
    ) -> Bool {
        guard navigator.parent === expectedParent,
            visited.insert(ObjectIdentifier(navigator)).inserted
        else {
            return false
        }

        for tab in navigator.tabs {
            guard isValidHierarchy(
                rootedAt: tab,
                expectedParent: navigator,
                visited: &visited
            ) else {
                return false
            }
        }
        if let child = navigator.childSubj.value {
            guard isValidHierarchy(
                rootedAt: child,
                expectedParent: navigator,
                visited: &visited
            ) else {
                return false
            }
        }

        return true
    }

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
    /// - Important: Initial tabs and children must be unowned roots of internally consistent
    ///   navigator hierarchies. An invalid tabs array is rejected as a whole, and an invalid
    ///   child is ignored, so an existing hierarchy is never reparented.
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
        let validatedChildren = Self.validatedInitialChildren(
            tabs: tabs,
            child: child,
            parentID: id
        )
        self.id = id
        self.rootSubj = .init(root)
        self.destinationsSubj = .init(destinations)
        self.tabItem = tabItem
        self.kind = kind
        self.tabs = validatedChildren.tabs
        self.presentation = presentation
        self.childSubj = .init(validatedChildren.child)
        self.selectedTabSubj = .init(selectedTab)

        bind()
    }

    isolated deinit {
        NavigatorBindingStateStore.remove(for: self)
        onDeinit?()
        navigatorLog?(#function, debugDescription, id)
    }
}

extension TypedViewNavigator: @MainActor PersistentNavigator, Codable
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
