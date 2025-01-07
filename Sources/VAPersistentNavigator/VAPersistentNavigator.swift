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

    public func push(_ destination: any PersistentDestination) {
        guard let destination = destination as? Destination else {
            assertionFailure("Push only the specified `Destination` type.")
            return
        }

        push(destination: destination)
    }

    /// Pushes a new destination onto the navigation stack.
    public func push(destination: Destination) {
#if DEBUG
        navigatorLogger.log("push", "destination: \(destination)")
#endif
        assert(kind == .flow, "Pushing a destination supported only for `.flow` kind.")

        var destinationsValue = destinationsSubj.value
        destinationsValue.append(destination)
        destinationsSubj.send(destinationsValue)
    }

    /// Pops the top destination from the navigation stack.
    public func pop() {
        guard !isRootView else {
#if DEBUG
            navigatorLogger.log("pop", "not possible, isRootView: \(isRootView)")
#endif
            return
        }

        var destinationsValue = destinationsSubj.value
        let destination = destinationsValue.popLast()
#if DEBUG
        navigatorLogger.log("pop", "destination: \(String(describing: destination))")
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
            navigatorLogger.log("pop", "destination: \(destination)")
#endif
            destinationsValue.removeSubrange(index + 1..<destinationsValue.count)
            destinationsSubj.send(destinationsValue)

            return true
        } else {
#if DEBUG
            navigatorLogger.log("pop", "not possible, destination: \(destination) not found")
#endif
            return false
        }
    }

    /// Pops the navigation stack to the root destination.
    public func popToRoot() {
        guard !isRootView else {
#if DEBUG
            navigatorLogger.log("popToRoot", "not possible, isRootView: \(isRootView)")
#endif
            return
        }

#if DEBUG
        navigatorLogger.log("popToRoot")
#endif
        destinationsSubj.send([])
    }

    /// Presents a child navigator.
    ///
    /// - Parameter child: The child navigator to present.
    public func present(_ child: CodablePersistentNavigator?) {
        assert(kind != .tabView, "Cannot present a child navigator from a TabView.")
#if DEBUG
        navigatorLogger.log("present", "child: \(child?.logDescription ?? "nil")")
#endif

        childSubj.send(child)
    }

    public func present(_ data: NavigatorData) {
        present(getNavigator(data: data))
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
                navigatorLogger.log("dismiss to", "destination: \(destination)")
#endif
                topNavigator?.present(nil)

                return true
            }

            topNavigator = topNavigator?.parent
        }
#if DEBUG
        navigatorLogger.log("dismiss to", "not possible, destination: \(destination) not found")
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
                navigatorLogger.log("dismiss to", "id: \(id)")
#endif
                topNavigator?.present(nil)

                return true
            }

            topNavigator = topNavigator?.parent
        }
#if DEBUG
        navigatorLogger.log("dismiss to", "not possible, id: \(id) not found")
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
            navigatorLogger.log("replace root", "pop to root")
#endif
            popToRoot()
        }
#if DEBUG
            navigatorLogger.log("replace root", "destination: \(root)")
#endif
        rootSubj.send(root)
    }

    /// Dismisses the current top navigator.
    public func dismissTop() {
#if DEBUG
        navigatorLogger.log("dismiss top")
#endif
        parent?.present(nil)
    }

    /// Closes the navigator to the initial first navigator.
    public func closeToInitial() {
#if DEBUG
        navigatorLogger.log("close to initial")
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
            navigator.present(nil)
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
            navigatorLogger.log(#function, logDescription, id)
        }
    }
#endif
}
