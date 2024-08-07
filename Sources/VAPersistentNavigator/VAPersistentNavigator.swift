//
//  Navigator.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 30.07.2024.
//

import Foundation
import Combine

public final class Navigator<Destination: Codable & Hashable, TabItemTag: Codable & Hashable>: Codable, Identifiable, Equatable {
    public static func == (lhs: Navigator, rhs: Navigator) -> Bool {
        lhs.id == rhs.id
    }

    public private(set) var id: UUID

    public var onReplaceInitialNavigator: ((_ newNavigator: Navigator) -> Void)? {
        get { parent == nil ? _onReplaceInitialNavigator : parent?.onReplaceInitialNavigator }
        set {
            if parent == nil {
                _onReplaceInitialNavigator = newValue
            } else {
                parent?.onReplaceInitialNavigator = newValue
            }
        }
    }
    private var _onReplaceInitialNavigator: ((_ newNavigator: Navigator) -> Void)?

    public var root: Destination? { rootSubj.value }
    let rootSubj: CurrentValueSubject<Destination?, Never>

    public var currentTab: TabItemTag? {
        get { kind.isTabView ? selectedTabSubj.value : parent?.currentTab }
        set {
            if kind.isTabView {
                selectedTabSubj.send(newValue)
            } else {
                parent?.currentTab = newValue
            }
        }
    }
    let selectedTabSubj: CurrentValueSubject<TabItemTag?, Never>
    private(set) var tabItem: TabItemTag?
    let tabs: [Navigator]

    let storeSubj = PassthroughSubject<Void, Never>()
    let destinationsSubj: CurrentValueSubject<[Destination], Never>
    let childSubj: CurrentValueSubject<Navigator?, Never>
    let kind: NavigatorKind
    let presentation: NavigatorPresentation
    private(set) weak var parent: Navigator?

    private var childCancellable: AnyCancellable?
    private var bag: Set<AnyCancellable> = []

    public convenience init(
        id: UUID = .init(),
        root: Destination,
        destinations: [Destination] = [],
        presentation: NavigatorPresentation = .sheet,
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

    public convenience init(
        id: UUID = .init(),
        tabs: [Navigator] = [],
        presentation: NavigatorPresentation = .sheet,
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
        presentation: NavigatorPresentation = .sheet,
        tabItem: TabItemTag? = nil,
        kind: NavigatorKind = .flow,
        tabs: [Navigator] = [],
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

    public func push(destination: Destination) {
        var destinationsValue = destinationsSubj.value
        destinationsValue.append(destination)
        destinationsSubj.send(destinationsValue)
    }

    public func pop() {
        var destinationsValue = destinationsSubj.value
        _ = destinationsValue.popLast()
        destinationsSubj.send(destinationsValue)
    }

    @discardableResult
    public func pop(to destination: Destination, isFirst: Bool = true) -> Bool {
        var destinationsValue = destinationsSubj.value
        if let index = isFirst ? destinationsValue.firstIndex(of: destination) : destinationsValue.lastIndex(of: destination), index + 1 < destinationsValue.count {
            destinationsValue.removeSubrange(index + 1..<destinationsValue.count)
            destinationsSubj.send(destinationsValue)

            return true
        } else {
            return false
        }
    }

    public func popToRoot() {
        destinationsSubj.send([])
    }

    public func present(_ child: Navigator?) {
        childSubj.send(child)
    }

    public func replace(root: Destination, isPopToRoot: Bool = true) {
        if isPopToRoot {
            popToRoot()
        }
        rootSubj.send(root)
    }

    public func dismissTop() {
        parent?.present(nil)
    }

    public func closeToInitial() {
        var firstNavigator: Navigator? = self
        while firstNavigator?.parent != nil {
            firstNavigator = firstNavigator?.parent
        }

        switch firstNavigator?.kind {
        case .tabView:
            firstNavigator?.tabs.forEach {
                $0.popToRoot()
                $0.present(nil)
            }
        case .flow:
            firstNavigator?.popToRoot()
            firstNavigator?.present(nil)
        case .none:
            break
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
        self.childSubj = .init(try container.decodeIfPresent(Navigator.self, forKey: .navigator))
        self.tabItem = try container.decodeIfPresent(TabItemTag.self, forKey: .tabItem)
        self.selectedTabSubj = .init(try container.decodeIfPresent(TabItemTag.self, forKey: .selectedTab))
        self.kind = try container.decode(NavigatorKind.self, forKey: .kind)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.tabs = try container.decode([Navigator].self, forKey: .tabs)
        self.presentation = try container.decode(NavigatorPresentation.self, forKey: .presentation)

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

    private func rebindChild(child: Navigator?) {
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
}
