//
//  BaseNavigator.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 4/3/25.
//

import Foundation
import Combine

/// A placeholder type representing the absence of a specific tab item tag.
///
/// Used when no tab item identification is needed.
public struct EmptyTabItemTag: PersistentTabItemTag {}

/// A placeholder type representing the absence of a specific sheet tag.
///
/// Used when no sheet differentiation is required.
public struct EmptySheetTag: PersistentSheetTag {}

/// A protocol defining a type-safe abstraction for handling navigation logic.
///
/// `BaseNavigator` supports multiple navigation styles, including single views,
/// navigation stacks, and tabbed views. It manages hierarchical relationships
/// and tracks navigation state.
@MainActor
public protocol BaseNavigator: AnyObject, CustomDebugStringConvertible, Identifiable {
    associatedtype Destination: Hashable
    associatedtype TabItemTag: Hashable
    associatedtype SheetTag: Hashable

    var id: UUID { get }
    var kind: NavigatorKind { get }
    var tabs: [Self] { get }
    var presentation: TypedNavigatorPresentation<SheetTag> { get }
    var tabItem: TabItemTag? { get }
    var selectedTabSubj: CurrentValueSubject<TabItemTag?, Never> { get }
    var childSubj: CurrentValueSubject<Self?, Never> { get }
    var rootSubj: CurrentValueSubject<Destination?, Never> { get }
    var destinationsSubj: CurrentValueSubject<[Destination], Never> { get }
    var parent: Self? { get set }
    var _onReplaceInitialNavigator: ((_ newNavigator: Self) -> Void)? { get set }
    var childCancellable: AnyCancellable? { get set }
    var bag: Set<AnyCancellable> { get set }
    var onDeinit: (() -> Void)? { get set }

    /// Designated initializer for creating a navigator instance with full configuration.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for the navigator.
    ///   - root: The initial root destination.
    ///   - destinations: List of additional destinations (used in `.flow` kind).
    ///   - presentation: Presentation options for modals and sheets.
    ///   - tabItem: Tab identifier if used inside a tab view.
    ///   - kind: The navigation kind this instance represents.
    ///   - tabs: Child navigators if this is a tab view.
    ///   - selectedTab: The currently selected tab item tag.
    ///   - child: A presented child navigator, if any.
    init(
        id: UUID,
        root: Destination?, // ignored when kind == .tabView
        destinations: [Destination],
        presentation: TypedNavigatorPresentation<SheetTag>,
        tabItem: TabItemTag?,
        kind: NavigatorKind,
        tabs: [Self],
        selectedTab: TabItemTag?,
        child: Self?
    )
}

public extension BaseNavigator {

    /// Convenience initializer for creating a `.singleView` style navigator.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for the navigator.
    ///   - view: The single view destination.
    ///   - presentation: Presentation options for this navigator (e.g., sheet).
    ///   - tabItem: Optional tab identifier if embedded in a tab view.
    init(
        id: UUID = .init(),
        view: Destination,
        presentation: TypedNavigatorPresentation<SheetTag> = .sheet,
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
            selectedTab: nil,
            child: nil
        )
    }

    /// Convenience initializer for creating a `.flow` style navigator with a stack of destinations.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for the navigator.
    ///   - root: The root view in the navigation stack.
    ///   - destinations: Additional destinations to push.
    ///   - presentation: Presentation options for this navigator.
    ///   - tabItem: Optional tab identifier if embedded in a tab view.
    init(
        id: UUID = .init(),
        root: Destination,
        destinations: [Destination] = [],
        presentation: TypedNavigatorPresentation<SheetTag> = .sheet,
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
            selectedTab: nil,
            child: nil
        )
    }

    /// Convenience initializer for creating a `.tabView` style navigator.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for the navigator.
    ///   - tabs: Child navigators representing each tab.
    ///   - presentation: Presentation options for the entire tab view.
    ///   - selectedTab: Initially selected tab.
    init(
        id: UUID = .init(),
        tabs: [Self] = [],
        presentation: TypedNavigatorPresentation<SheetTag> = .sheet,
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
            selectedTab: selectedTab,
            child: nil
        )
    }

    var root: Destination? { rootSubj.value }
    var isRootView: Bool { destinationsSubj.value.isEmpty }
    var orTabChild: Self { tabChild ?? self }
    var tabChild: Self? {
        tabs.first(where: { $0.tabItem == selectedTabSubj.value }) ?? tabs.first
    }
    var topChild: Self? {
        switch kind {
        case .tabView: tabChild
        case .flow, .singleView: childSubj.value
        }
    }
    var topNavigator: Self {
        var navigator: Self! = self
        while navigator?.topChild != nil {
            navigator = navigator?.topChild
        }

        return navigator
    }
    var currentTab: TabItemTag? {
        get { kind.isTabView ? selectedTabSubj.value : parent?.currentTab }
        set {
            if kind.isTabView {
                selectedTabSubj.send(newValue)
            } else {
                parent?.currentTab = newValue
            }
        }
    }
    /// A closure that is called when the initial navigator needs to be replaced.
    var onReplaceInitialNavigator: ((_ newNavigator: Self) -> Void)? {
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

    /// Pushes a new destination onto the navigation stack if supported by the current navigator.
    ///
    /// This method operates only when the `topNavigator` (or its selected tab child)
    /// is of kind `.flow`. In such cases, the provided `destination` is appended
    /// to the list of current destinations, triggering a UI update.
    ///
    /// - Parameter destination: The destination to be pushed onto the navigation stack.
    /// - Returns: `true` if the destination was successfully pushed; `false` otherwise.
    ///
    /// Example:
    /// ```swift
    /// navigator.push(destination: .detailsView)
    /// ```
    ///
    /// - Note: This method is a no-op for `.singleView` and `.tabView` navigators.
    @discardableResult
    func push(destination: Destination) -> Bool {
        navigatorLog?("push", "destination: \(destination)")
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

    /// Presents a child navigator.
    ///
    /// - Parameters:
    ///   - child: The child navigator to present.
    ///   - strategy: Defines strategy for presenting a new navigator. Defaults to `.onTop`
    func present(_ data: NavigatorData, strategy: NavigatorPresentationStrategy = .onTop) {
        present(getNavigator(data: data), strategy: strategy)
    }

    /// Presents a child navigator.
    ///
    /// - Parameters:
    ///   - child: The child navigator to present.
    ///   - strategy: Defines strategy for presenting a new navigator.
    func present(
        _ child: Self?,
        strategy: NavigatorPresentationStrategy = .onTop
    ) {
        navigatorLog?("present", "child: \(child?.debugDescription ?? "nil")", "strategy: \(strategy)")
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

    /// Pops the top destination from the navigation stack.
    func pop() {
        guard !isRootView else {
            navigatorLog?("pop", "not possible, isRootView: \(isRootView)")

            return
        }

        var destinationsValue = destinationsSubj.value
        let destination = destinationsValue.popLast()
        navigatorLog?("pop", "destination: \(String(describing: destination))")
        destinationsSubj.send(destinationsValue)
    }

    /// Pops the navigation stack to the root destination.
    func popToRoot() {
        guard !isRootView else {
            navigatorLog?("popToRoot", "not possible, isRootView: \(isRootView)")

            return
        }

        navigatorLog?("popToRoot")
        destinationsSubj.send([])
    }

    /// Pops the navigation stack to a specific destination.
    ///
    /// - Parameters:
    ///   - destination: The destination to pop to.
    ///   - isFirst: If `true`, pops to the first occurrence of the destination; otherwise, pops to the last occurrence.
    /// - Returns: `true` if the destination was found and popped to, otherwise `false`.
    @discardableResult
    func pop(target destination: Destination, isFirst: Bool = true) -> Bool {
        var destinationsValue = destinationsSubj.value
        if let index = isFirst ? destinationsValue.firstIndex(of: destination) : destinationsValue.lastIndex(of: destination), index + 1 < destinationsValue.count {
            navigatorLog?("pop", "destination: \(destination)")
            destinationsValue.removeSubrange(index + 1..<destinationsValue.count)
            destinationsSubj.send(destinationsValue)

            return true
        } else {
            navigatorLog?("pop", "not possible, destination: \(destination) not found")

            return false
        }
    }

    /// Dismisses to a specific navigator by ID.
    ///
    /// - Parameter id: The ID of the navigator to dismiss to.
    /// - Returns: `true` if the navigator was found and dismissed to, otherwise `false`.
    @discardableResult
    func dismissTo(id: UUID) -> Bool {
        var topNavigator: Self? = self
        while topNavigator != nil {
            if topNavigator?.id == id {
                navigatorLog?("dismiss to", "id: \(id)")
                topNavigator?.present(nil, strategy: .fromCurrent)

                return true
            }

            topNavigator = topNavigator?.parent
        }
        navigatorLog?("dismiss to", "not possible, id: \(id) not found")

        return false
    }

    /// Dismisses to a specific destination.
    ///
    /// - Parameter destination: The destination to dismiss to.
    /// - Returns: `true` if the destination was found and dismissed to, otherwise `false`.
    @discardableResult
    func dismiss(target destination: Destination) -> Bool {
        var topNavigator: Self? = self
        while topNavigator != nil {
            if topNavigator?.root == destination {
                navigatorLog?("dismiss to", "destination: \(destination)")
                topNavigator?.present(nil, strategy: .fromCurrent)

                return true
            }

            topNavigator = topNavigator?.parent
        }
        navigatorLog?("dismiss to", "not possible, destination: \(destination) not found")

        return false
    }

    /// Replaces the root destination.
    ///
    /// - Parameters:
    ///   - root: The new root destination.
    ///   - isPopToRoot: If `true`, pops to the root before replacing it.
    func replace(_ root: Destination, isPopToRoot: Bool = true) {
        if isPopToRoot {
            navigatorLog?("replace root", "pop to root")
            popToRoot()
        }
        navigatorLog?("replace root", "destination: \(root)")
        rootSubj.send(root)
    }

    /// Dismisses the current top navigator.
    func dismissTop() {
        navigatorLog?("dismiss top")
        parent?.present(nil, strategy: .fromCurrent)
    }

    /// Attempts to navigate to a specified target destination by traversing
    /// up the hierarchy of navigators.
    ///
    /// - Parameter target: The destination to which the method attempts to navigate.
    /// - Returns: `true` if navigation to the target destination is successful, `false` otherwise.
    @discardableResult
    func close(target: Destination) -> Bool {
        var navigator: Self? = topNavigator
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
    func close(predicate: (Destination) -> Bool) -> Bool {
        var navigator: Self? = topNavigator
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
                pop(target: destination)

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
    func closeToInitial() {
        navigatorLog?("close to initial")
        var firstNavigator: Self! = self
        while firstNavigator.parent != nil {
            firstNavigator = firstNavigator.parent
        }
        switch firstNavigator.kind {
        case .tabView:
            firstNavigator.tabs.forEach {
                $0.present(nil, strategy: .fromCurrent)
                $0.popToRoot()
            }
        case .flow:
            firstNavigator.present(nil, strategy: .fromCurrent)
            firstNavigator.popToRoot()
        case .singleView:
            firstNavigator.present(nil, strategy: .fromCurrent)
        }
    }

    func getNavigator(data: NavigatorData) -> Self? {
        switch data {
        case let .view(view, id, presentation, tabItem):
            guard let destination = view as? Destination else {
                navigatorLog?("Present only the specified `Destination` type. Found: \(type(of: view)). Expecting: \(Destination.self)")

                return nil
            }

            return .init(
                id: id,
                view: destination,
                presentation: TypedNavigatorPresentation(presentation: presentation),
                tabItem: tabItem as? TabItemTag
            )
        case let .stack(root, id, destinations, presentation, tabItem):
            guard let destination = root as? Destination else {
                navigatorLog?("Present only the specified `Destination` type. Found: \(type(of: root)). Expecting: \(Destination.self)")

                return nil
            }

            return .init(
                id: id,
                root: destination,
                destinations: destinations.compactMap { $0 as? Destination },
                presentation: TypedNavigatorPresentation(presentation: presentation),
                tabItem: tabItem as? TabItemTag
            )
        case let .tab(tabs, id, presentation, selectedTab):
            return .init(
                id: id,
                tabs: tabs.compactMap { getNavigator(data: $0) },
                presentation: TypedNavigatorPresentation(presentation: presentation),
                selectedTab: selectedTab as? TabItemTag
            )
        }
    }
}

extension BaseNavigator {

    func bind() {
        tabs.forEach { $0.parent = self }
        childSubj
            .sink { [weak self] in
                $0?.parent = self
            }
            .store(in: &bag)
        (self as? any PersistentNavigator)?.bindStoring()
    }
}

// MARK: - Hashable functions

public extension BaseNavigator {

    /// Pushes a new destination onto the navigation stack.
    /// - Returns: `true` if the destination matches base type, otherwise `false`.
    @discardableResult
    func push(_ destination: any Hashable) -> Bool {
        guard let destination = destination as? Destination else {
            navigatorLog?("Push only the specified `Destination` type. Found: \(type(of: destination)). Destination: \(Destination.self)")

            return false
        }

        return push(destination: destination)
    }

    /// Pops the navigation stack to a specific destination.
    ///
    /// - Parameters:
    ///   - destination: The destination to pop to.
    ///   - isFirst: If `true`, pops to the first occurrence of the destination; otherwise, pops to the last occurrence.
    /// - Returns: `true` if the destination was found and popped to, otherwise `false`.
    @discardableResult
    func pop(to destination: any Hashable, isFirst: Bool = true) -> Bool {
        guard let destination = destination as? Destination else {
            navigatorLog?("Pop only the specified `Destination` type. Found: \(type(of: destination)). Destination: \(Destination.self)")

            return false
        }

        return pop(target: destination, isFirst: isFirst)
    }

    /// Replaces the root destination.
    ///
    /// - Parameters:
    ///   - root: The new root destination.
    ///   - isPopToRoot: If `true`, pops to the root before replacing it.
    /// - Returns: `true` if the destination was correct, otherwise `false`.
    @discardableResult
    func replace(root destination: any Hashable, isPopToRoot: Bool = true) -> Bool {
        guard let destination = destination as? Destination else {
            navigatorLog?("Replace only the specified `Destination` type. Found: \(type(of: destination)). Destination: \(Destination.self)")

            return false
        }

        replace(destination, isPopToRoot: isPopToRoot)

        return true
    }

    /// Dismisses to a specific destination.
    ///
    /// - Parameter destination: The destination to dismiss to.
    /// - Returns: `true` if the destination was found and dismissed to, otherwise `false`.
    @discardableResult
    func dismiss(to destination: any Hashable) -> Bool {
        guard let destination = destination as? Destination else {
            navigatorLog?("Dismiss only the specified `Destination` type. Found: \(type(of: destination)). Destination: \(Destination.self)")

            return false
        }

        return dismiss(target: destination)
    }

    /// Attempts to navigate to a specified target destination by traversing
    /// up the hierarchy of navigators.
    ///
    /// - Parameter target: The destination to which the method attempts to navigate.
    /// - Returns: `true` if navigation to the target destination is successful, `false` otherwise.
    @discardableResult
    func close(to destination: any Hashable) -> Bool {
        guard let destination = destination as? Destination else {
            navigatorLog?("Close only the specified `Destination` type. Found: \(type(of: destination)). Destination: \(Destination.self)")

            return false
        }

        return close(target: destination)
    }

    /// Attempts to navigate to a destination that satisfies the given predicate by traversing
    /// up the hierarchy of navigators.
    ///
    /// - Parameter predicate: A closure that takes a `Destination` as its argument and returns `true` if the destination satisfies the condition.
    /// - Returns: `true` if a destination satisfying the predicate is found and navigation is successfully performed, `false` otherwise.
    func close(where predicate: (any Hashable) -> Bool) -> Bool {
        return close(predicate: predicate)
    }
}
