//
//  Navigator.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 30.07.2024.
//

import Foundation
import Combine

public class Navigator<Destination: Codable & Hashable>: Codable, Identifiable {
    public private(set) var id = UUID()

    public var onReplaceWindow: ((Navigator<Destination>) -> Void)? {
        get { parent == nil ? _onReplaceWindow : parent?.onReplaceWindow }
        set {
            if parent == nil {
                _onReplaceWindow = newValue
            } else {
                parent?.onReplaceWindow = newValue
            }
        }
    }
    private var _onReplaceWindow: ((Navigator<Destination>) -> Void)?

    public var root: Destination { rootSubj.value }
    let rootSubj: CurrentValueSubject<Destination, Never>

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
    let tabs: [Navigator<Destination>]
    private(set) var tabItem: NavigatorTabItem?

    let storeSubj = PassthroughSubject<Void, Never>()
    let destinationsSubj: CurrentValueSubject<[Destination], Never>
    let childSubj: CurrentValueSubject<Navigator<Destination>?, Never>
    let kind: NavigatorKind
    let presentation: NavigatorPresentation
    private(set) weak var parent: Navigator<Destination>?

    private var childCancellable: AnyCancellable?
    private var bag: Set<AnyCancellable> = []

    public init(
        root: Destination,
        destinations: [Destination] = [],
        kind: NavigatorKind = .flow,
        tabItem: NavigatorTabItem? = nil,
        tabs: [Navigator<Destination>] = [],
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

    public func present(_ child: Navigator<Destination>?) {
        self.childSubj.send(child)
        rebindChild()
    }

    public func replace(root: Destination) {
        self.rootSubj.send(root)
    }

    public func dismissTop() {
        parent?.present(nil)
    }

    public func closeToRoot() {
        var firstNavigator: Navigator<Destination>? = self
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
        self.rootSubj = .init(try container.decode(Destination.self, forKey: .root))
        self.destinationsSubj = .init(try container.decode([Destination].self, forKey: .destinations))
        self.childSubj = .init(try? container.decode(Navigator<Destination>.self, forKey: .navigator))
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

        rebindChild()
    }

    private func rebindChild() {
        childCancellable?.cancel()
        if let child = childSubj.value {
            child.parent = self
            childCancellable = child.storeSubj
                .sink(receiveValue: storeSubj.send)
            storeSubj.send(())
        } else {
            childCancellable = nil
        }
    }
}
