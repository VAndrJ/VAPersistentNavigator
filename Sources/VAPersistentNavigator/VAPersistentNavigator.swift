//
//  Navigator.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 30.07.2024.
//

import Foundation
import Combine

public class Navigator: Codable, Identifiable {
    public private(set) var id = UUID()

    public var onReplaceWindow: ((Navigator) -> Void)? {
        get { parent == nil ? _onReplaceWindow : parent?.onReplaceWindow }
        set {
            if parent == nil {
                _onReplaceWindow = newValue
            } else {
                parent?.onReplaceWindow = newValue
            }
        }
    }
    private var _onReplaceWindow: ((Navigator) -> Void)?

    public var root: NavigatorDestination { rootSubj.value }
    let rootSubj: CurrentValueSubject<NavigatorDestination, Never>

    public var currentTab: Int? {
        get { kind.isTabView ? selectedTabSubj.value : parent?.currentTab }
        set {
            if kind.isTabView {
                selectedTabSubj.send(newValue)
            } else {
                parent?.currentTab = newValue
            }
        }
    }
    let selectedTabSubj: CurrentValueSubject<Int?, Never>
    let tabs: [Navigator]
    private(set) var tabItem: NavigatorTabItem?

    let storeSubj = PassthroughSubject<Void, Never>()
    let destinationsSubj: CurrentValueSubject<[NavigatorDestination], Never>
    let childSubj: CurrentValueSubject<Navigator?, Never>
    let kind: NavigatorKind
    let presentation: NavigatorPresentation
    private(set) weak var parent: Navigator?

    private var childCancellable: AnyCancellable?
    private var bag: Set<AnyCancellable> = []

    public init(
        root: NavigatorDestination,
        destinations: [NavigatorDestination] = [],
        kind: NavigatorKind = .flow,
        tabItem: NavigatorTabItem? = nil,
        tabs: [Navigator] = [],
        selectedTab: Int = 0,
        presentation: NavigatorPresentation = .sheet
    ) {
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

    public func push(destination: NavigatorDestination) {
        var destinationsValue = destinationsSubj.value
        destinationsValue.append(destination)
        destinationsSubj.send(destinationsValue)
    }

    public func pop() {
        var destinationsValue = destinationsSubj.value
        _ = destinationsValue.popLast()
        destinationsSubj.send(destinationsValue)
    }

    public func present(_ child: Navigator?) {
        self.childSubj.send(child)
        rebindChild()
    }

    public func replace(root: NavigatorDestination) {
        self.rootSubj.send(root)
    }

    public func dismissTop() {
        parent?.present(nil)
    }

    public func closeToRoot() {
        var firstNavigator: Navigator? = self
        while firstNavigator?.parent != nil {
            firstNavigator = firstNavigator?.parent
        }

        switch firstNavigator?.kind {
        case .tabView:
            firstNavigator?.tabs.forEach {
                $0.destinationsSubj.send([])
                $0.present(nil)
            }
        case .flow:
            firstNavigator?.destinationsSubj.send([])
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
        try container.encode(rootSubj.value, forKey: .root)
        try container.encode(destinationsSubj.value, forKey: .destinations)
        try container.encode(childSubj.value, forKey: .navigator)
        try container.encode(tabItem, forKey: .tabItem)
        try container.encode(selectedTabSubj.value, forKey: .selectedTab)
        try container.encode(kind, forKey: .kind)
        try container.encode(id, forKey: .id)
        try container.encode(tabs, forKey: .tabs)
        try container.encode(presentation, forKey: .presentation)
    }

    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.rootSubj = .init(try container.decode(NavigatorDestination.self, forKey: .root))
        self.destinationsSubj = .init(try container.decode([NavigatorDestination].self, forKey: .destinations))
        self.childSubj = .init(try? container.decode(Navigator.self, forKey: .navigator))
        self.tabItem = try? container.decode(NavigatorTabItem.self, forKey: .tabItem)
        self.selectedTabSubj = .init(try? container.decode(Int.self, forKey: .selectedTab))
        self.kind = try container.decode(NavigatorKind.self, forKey: .kind)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.tabs = try container.decode([Navigator].self, forKey: .tabs)
        self.presentation = try container.decode(NavigatorPresentation.self, forKey: .presentation)

        rebind()
    }

    private func rebind() {
        bag.forEach { $0.cancel() }
        bag = []

        destinationsSubj
            .map { _ in }
            .sink(receiveValue: storeSubj.send)
            .store(in: &bag)
        rootSubj
            .map { _ in }
            .sink(receiveValue: storeSubj.send)
            .store(in: &bag)
        selectedTabSubj
            .map { _ in }
            .sink(receiveValue: storeSubj.send)
            .store(in: &bag)
        tabs.forEach { child in
            child.parent = self
            child.storeSubj
                .sink(receiveValue: storeSubj.send)
                .store(in: &bag)
        }

        rebindChild()
    }

    private func rebindChild() {
        childCancellable?.cancel()
        if let child = childSubj.value {
            child.parent = self
            childCancellable = child.storeSubj
                .sink(receiveValue: storeSubj.send)
        } else {
            childCancellable = nil
        }
    }
}
