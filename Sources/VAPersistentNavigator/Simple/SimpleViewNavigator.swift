//
//  SimpleViewNavigator.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 4/3/25.
//

import Combine
import Foundation

public typealias SimpleViewNavigator = TypedViewNavigator<AnyHashable, AnyHashable, AnyHashable>

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
    public private(set) weak var parent: TypedViewNavigator?
    public var debugDescription: String {
        let root = if let root { String(describing: root) } else { "nil" }
        let tabItem = if let tabItem { String(describing: tabItem) } else { "nil" }

        return "\(Self.self), kind: \(kind), root: \(root), tabs: \(tabs), presentation: \(presentation), tabItem: \(tabItem)"
    }
    public var childCancellable: AnyCancellable?
    public var bag: Set<AnyCancellable> = []

    public init(
        id: UUID = .init(),
        root: Destination?, // ignored when kind == .tabView
        destinations: [Destination] = [],
        presentation: TypedNavigatorPresentation<SheetTag> = .sheet,
        tabItem: TabItemTag? = nil,
        kind: NavigatorKind = .flow,
        tabs: [TypedViewNavigator] = [],
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

    private func rebind() {
        tabs.forEach { $0.parent = self }
        childSubj
            .sink { [weak self] in
                self?.rebindChild(child: $0)
            }
            .store(in: &bag)
    }

    private func rebindChild(child: TypedViewNavigator?) {
        if let child = childSubj.value {
            child.parent = self
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
