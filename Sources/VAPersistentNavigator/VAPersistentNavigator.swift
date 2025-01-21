//
//  Navigator.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 30.07.2024.
//

import Foundation
import Combine

/// A class representing a navigator that manages navigation states and presentations.
@MainActor
public final class CodablePersistentNavigator<
    Destination: PersistentDestination,
    TabItemTag: PersistentTabItemTag,
    SheetTag: PersistentSheetTag
>: @preconcurrency Codable, @preconcurrency Identifiable, @preconcurrency Equatable, PersistentNavigator {
    public static func == (lhs: CodablePersistentNavigator, rhs: CodablePersistentNavigator) -> Bool {
        lhs.id == rhs.id
    }

    public private(set) var id: UUID

    /// A closure that is called when the initial navigator needs to be replaced.
    public var onReplaceInitialNavigator: ((_ newNavigator: CodablePersistentNavigator) -> Void)? {
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
    private var _onReplaceInitialNavigator: ((_ newNavigator: CodablePersistentNavigator) -> Void)?

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
    let tabs: [CodablePersistentNavigator]

    let storeSubj = PassthroughSubject<Void, Never>()

    public var isRootView: Bool { destinationsSubj.value.isEmpty }
    let destinationsSubj: CurrentValueSubject<[Destination], Never>
    var orTabChild: CodablePersistentNavigator { tabChild ?? self }
    public var topNavigator: CodablePersistentNavigator {
        var navigator: CodablePersistentNavigator! = self
        while navigator?.topChild != nil {
            navigator = navigator?.topChild
        }

        return navigator
    }
    public var tabChild: CodablePersistentNavigator? {
        tabs.first(where: { $0.tabItem == selectedTabSubj.value }) ?? tabs.first
    }
    public var topChild: CodablePersistentNavigator? {
        switch kind {
        case .tabView: tabChild
        case .flow, .singleView: childSubj.value
        }
    }
    let childSubj: CurrentValueSubject<CodablePersistentNavigator?, Never>
    let kind: NavigatorKind
    let presentation: NavigatorPresentation<SheetTag>
    private(set) weak var parent: CodablePersistentNavigator?
#if DEBUG
    var logDescription: String {
        let root = if let root { String(describing: root) } else { "nil" }
        let tabItem = if let tabItem { String(describing: tabItem) } else { "nil" }

        return "\(Self.self), kind: \(kind), root: \(root), tabs: \(tabs), presentation: \(presentation), tabItem: \(tabItem)"
    }
#endif

    private var childCancellable: AnyCancellable?
    private var bag: Set<AnyCancellable> = []

    /// Initializer for a single `View` navigator.
    public convenience init(
        id: UUID = .init(),
        view: Destination,
        presentation: NavigatorPresentation<SheetTag> = .sheet,
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
        presentation: NavigatorPresentation<SheetTag> = .sheet,
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
        presentation: NavigatorPresentation<SheetTag> = .sheet,
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
        presentation: NavigatorPresentation<SheetTag> = .sheet,
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

    @discardableResult
    public func push(_ destination: any PersistentDestination) -> Bool {
        guard let destination = destination as? Destination else {
            assertionFailure("Push only the specified `Destination` type.")
            return false
        }

        return push(destination: destination)
    }

    /// Pushes a new destination onto the navigation stack.
    @discardableResult
    public func push(destination: Destination) -> Bool {
#if DEBUG
        navigatorLog?("push", "destination: \(destination)")
#endif
        let topNavigator = self.topNavigator.orTabChild
        switch topNavigator.kind {
        case .flow:
            var destinationsValue = topNavigator.destinationsSubj.value
            destinationsValue.append(destination)
            topNavigator.destinationsSubj.send(destinationsValue)

            return true
        case .singleView, .tabView:
            return false
        }
    }

    /// Pops the top destination from the navigation stack.
    public func pop() {
        guard !isRootView else {
#if DEBUG
            navigatorLog?("pop", "not possible, isRootView: \(isRootView)")
#endif
            return
        }

        var destinationsValue = destinationsSubj.value
        let destination = destinationsValue.popLast()
#if DEBUG
        navigatorLog?("pop", "destination: \(String(describing: destination))")
#endif
        destinationsSubj.send(destinationsValue)
    }

    public func pop(to destination: any PersistentDestination, isFirst: Bool) -> Bool {
        guard let destination = destination as? Destination else {
            assertionFailure("Pop only the specified `Destination` type.")
            return false
        }

        return pop(to: destination, isFirst: isFirst)
    }

    /// Pops the navigation stack to a specific destination.
    ///
    /// - Parameters:
    ///   - destination: The destination to pop to.
    ///   - isFirst: If `true`, pops to the first occurrence of the destination; otherwise, pops to the last occurrence.
    /// - Returns: `true` if the destination was found and popped to, otherwise `false`.
    @discardableResult
    public func pop(to destination: Destination, isFirst: Bool = true) -> Bool {
        var destinationsValue = destinationsSubj.value
        if let index = isFirst ? destinationsValue.firstIndex(of: destination) : destinationsValue.lastIndex(of: destination), index + 1 < destinationsValue.count {
#if DEBUG
            navigatorLog?("pop", "destination: \(destination)")
#endif
            destinationsValue.removeSubrange(index + 1..<destinationsValue.count)
            destinationsSubj.send(destinationsValue)

            return true
        } else {
#if DEBUG
            navigatorLog?("pop", "not possible, destination: \(destination) not found")
#endif
            return false
        }
    }

    /// Pops the navigation stack to the root destination.
    public func popToRoot() {
        guard !isRootView else {
#if DEBUG
            navigatorLog?("popToRoot", "not possible, isRootView: \(isRootView)")
#endif
            return
        }

#if DEBUG
        navigatorLog?("popToRoot")
#endif
        destinationsSubj.send([])
    }

    /// Presents a child navigator.
    ///
    /// - Parameters:
    ///   - child: The child navigator to present.
    ///   - strategy: Defines strategy for presenting a new navigator.
    public func present(
        _ child: CodablePersistentNavigator?,
        strategy: PresentationStrategy = .onTop
    ) {
#if DEBUG
        navigatorLog?("present", "child: \(child?.logDescription ?? "nil")", "strategy: \(strategy)")
#endif
        switch strategy {
        case .onTop:
            topNavigator.childSubj.send(child)
        case .replaceCurrent:
            let subj = orTabChild.childSubj
            subj.send(nil)
            //: To avoid presented iOS 16 issue
            Task { @MainActor [subj] in
                try? await Task.sleep(for: .milliseconds(100))
                subj.send(child)
            }
        case .fromCurrent:
            orTabChild.childSubj.send(child)
        }
    }

    public func present(_ data: NavigatorData, strategy: PresentationStrategy) {
        present(getNavigator(data: data), strategy: strategy)
    }

    private func getNavigator(data: NavigatorData) -> CodablePersistentNavigator? {
        switch data {
        case let .view(view, id, presentation, tabItem):
            guard let destination = view as? Destination else {
                assertionFailure("Present only the specified `Destination` type.")
                return nil
            }

            let presentation = NavigatorPresentation<SheetTag>(from: presentation)
            let tabItem = tabItem as? TabItemTag

            return .init(
                id: id,
                view: destination,
                presentation: presentation,
                tabItem: tabItem
            )
        case let .stack(root, id, destinations, presentation, tabItem):
            guard let destination = root as? Destination else {
                assertionFailure("Present only the specified `Destination` type.")
                return nil
            }

            let destinations = destinations.compactMap { $0 as? Destination }
            let presentation = NavigatorPresentation<SheetTag>(from: presentation)
            let tabItem = tabItem as? TabItemTag

            return .init(
                id: id,
                root: destination,
                destinations: destinations,
                presentation: presentation,
                tabItem: tabItem
            )
        case let .tab(tabs, id, presentation, selectedTab):
            let presentation = NavigatorPresentation<SheetTag>(from: presentation)
            let selectedTab = selectedTab as? TabItemTag

            return .init(
                id: id,
                tabs: tabs.compactMap { getNavigator(data: $0) },
                presentation: presentation,
                selectedTab: selectedTab
            )
        }
    }

    @discardableResult
    public func dismiss(to destination: any PersistentDestination) -> Bool {
        guard let destination = destination as? Destination else {
            assertionFailure("Pop only the specified `Destination` type.")
            return false
        }

        return dismiss(to: destination)
    }

    /// Dismisses to a specific destination.
    ///
    /// - Parameter destination: The destination to dismiss to.
    /// - Returns: `true` if the destination was found and dismissed to, otherwise `false`.
    @discardableResult
    public func dismiss(to destination: Destination) -> Bool {
        var topNavigator: CodablePersistentNavigator? = self
        while topNavigator != nil {
            if topNavigator?.root == destination {
#if DEBUG
                navigatorLog?("dismiss to", "destination: \(destination)")
#endif
                topNavigator?.present(nil, strategy: .fromCurrent)

                return true
            }

            topNavigator = topNavigator?.parent
        }
#if DEBUG
        navigatorLog?("dismiss to", "not possible, destination: \(destination) not found")
#endif

        return false
    }

    /// Dismisses to a specific navigator by ID.
    ///
    /// - Parameter id: The ID of the navigator to dismiss to.
    /// - Returns: `true` if the navigator was found and dismissed to, otherwise `false`.
    @discardableResult
    public func dismiss(to id: UUID) -> Bool {
        var topNavigator: CodablePersistentNavigator? = self
        while topNavigator != nil {
            if topNavigator?.id == id {
#if DEBUG
                navigatorLog?("dismiss to", "id: \(id)")
#endif
                topNavigator?.present(nil, strategy: .fromCurrent)

                return true
            }

            topNavigator = topNavigator?.parent
        }
#if DEBUG
        navigatorLog?("dismiss to", "not possible, id: \(id) not found")
#endif

        return false
    }

    public func replace(root: any PersistentDestination, isPopToRoot: Bool) {
        guard let destination = root as? Destination else {
            assertionFailure("Pop only the specified `Destination` type.")
            return
        }

        replace(root: destination, isPopToRoot: isPopToRoot)
    }

    /// Replaces the root destination.
    ///
    /// - Parameters:
    ///   - root: The new root destination.
    ///   - isPopToRoot: If `true`, pops to the root before replacing it.
    public func replace(root: Destination, isPopToRoot: Bool = true) {
        if isPopToRoot {
#if DEBUG
            navigatorLog?("replace root", "pop to root")
#endif
            popToRoot()
        }
#if DEBUG
        navigatorLog?("replace root", "destination: \(root)")
#endif
        rootSubj.send(root)
    }

    /// Dismisses the current top navigator.
    public func dismissTop() {
#if DEBUG
        navigatorLog?("dismiss top")
#endif
        parent?.present(nil, strategy: .fromCurrent)
    }

    /// Attempts to navigate to a specified target destination by traversing
    /// up the hierarchy of navigators.
    ///
    /// - Parameter target: The destination to which the method attempts to navigate.
    /// - Returns: `true` if navigation to the target destination is successful, `false` otherwise.
    @discardableResult
    public func closeTo(destination: any PersistentDestination) -> Bool {
        guard let destination = destination as? Destination else {
            assertionFailure("Close only the specified `Destination` type.")
            return false
        }

        return close(to: destination)
    }

    /// Attempts to navigate to a specified target destination by traversing
    /// up the hierarchy of navigators.
    ///
    /// - Parameter target: The destination to which the method attempts to navigate.
    /// - Returns: `true` if navigation to the target destination is successful, `false` otherwise.
    @discardableResult
    public func close(to target: Destination) -> Bool {
        var navigator: CodablePersistentNavigator? = topNavigator
        while navigator != nil {
            if navigator?.closeIn(where: { $0 == target }) == true {
                return true
            }
            navigator = navigator?.parent
        }

        return false
    }

    /// Attempts to navigate to a destination that satisfies the given predicate by traversing
    /// up the hierarchy of navigators.
    ///
    /// - Parameter predicate: A closure that takes a `Destination` as its argument and returns `true` if the destination satisfies the condition.
    /// - Returns: `true` if a destination satisfying the predicate is found and navigation is successfully performed, `false` otherwise.
    public func closeTo(where predicate: (any PersistentDestination) -> Bool) -> Bool {
        close(where: predicate)
    }

    /// Attempts to navigate to a destination that satisfies the given predicate by traversing
    /// up the hierarchy of navigators.
    ///
    /// - Parameter predicate: A closure that takes a `Destination` as its argument and returns `true` if the destination satisfies the condition.
    /// - Returns: `true` if a destination satisfying the predicate is found and navigation is successfully performed, `false` otherwise.
    public func close(where predicate: (Destination) -> Bool) -> Bool {
        var navigator: CodablePersistentNavigator? = topNavigator
        while navigator != nil {
            if navigator?.closeIn(where: predicate) == true {
                return true
            }
            navigator = navigator?.parent
        }

        return false
    }

    private func closeIn(where predicate: (Destination) -> Bool) -> Bool {
        for destination in destinationsSubj.value.reversed() {
            if predicate(destination) {
                present(nil, strategy: .fromCurrent)
                pop(to: destination)

                return true
            }
        }
        if let destination = root, predicate(destination) {
            present(nil, strategy: .fromCurrent)
            popToRoot()

            return true
        }

        return false
    }

    /// Closes the navigator to the initial first navigator.
    public func closeToInitial() {
#if DEBUG
        navigatorLog?("close to initial")
#endif
        var firstNavigator: CodablePersistentNavigator! = self
        while firstNavigator.parent != nil {
            firstNavigator = firstNavigator.parent
        }
        switch firstNavigator.kind {
        case .tabView:
            firstNavigator.tabs.forEach {
                dismissIfNeeded(in: $0)
                popToRootIfNeeded(in: $0)
            }
        case .flow:
            dismissIfNeeded(in: firstNavigator)
            popToRootIfNeeded(in: firstNavigator)
        case .singleView:
            dismissIfNeeded(in: firstNavigator)
        }
    }

    private func popToRootIfNeeded(in navigator: CodablePersistentNavigator) {
        if !navigator.destinationsSubj.value.isEmpty {
            navigator.popToRoot()
        }
    }

    private func dismissIfNeeded(in navigator: CodablePersistentNavigator) {
        if navigator.childSubj.value != nil {
            navigator.present(nil, strategy: .fromCurrent)
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
            navigatorLog?(#function, logDescription, id)
        }
    }
#endif
}
