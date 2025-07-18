//
//  BaseNavigator.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 4/3/25.
//

import Combine
import Foundation

/// A placeholder type representing the absence of a specific tab item tag.
///
/// Used when no tab item identification is needed.
public struct EmptyTabItemTag: PersistentTabItemTag {}

/// A placeholder type representing the absence of a specific sheet tag.
///
/// Used when no sheet differentiation is required.
public struct EmptySheetTag: PersistentSheetTag {}

#if compiler(<6.2)
public typealias SendableMetatype = Any
#endif

/// A protocol defining a type-safe abstraction for handling navigation logic.
///
/// `BaseNavigator` supports multiple navigation styles, including single views,
/// navigation stacks, and tabbed views. It manages hierarchical relationships
/// and tracks navigation state.
@MainActor
public protocol BaseNavigator: AnyObject, CustomDebugStringConvertible, Identifiable, Equatable, SendableMetatype {
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
    var environmentPubl: PassthroughSubject<EnvironmentAction, Never> { get }

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
        root: Destination?,  // ignored when kind == .tabView
        destinations: [Destination],
        presentation: TypedNavigatorPresentation<SheetTag>,
        tabItem: TabItemTag?,
        kind: NavigatorKind,
        tabs: [Self],
        selectedTab: TabItemTag?,
        child: Self?
    )
}

@MainActor
let isAnimatedSubj = CurrentValueSubject<Bool, Never>(true)

extension BaseNavigator {

    /// Convenience initializer for creating a `.singleView` style navigator.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for the navigator.
    ///   - view: The single view destination.
    ///   - presentation: Presentation options for this navigator (e.g., sheet).
    ///   - tabItem: Optional tab identifier if embedded in a tab view.
    public init(
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
    public init(
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
    public init(
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

    public var root: Destination? { rootSubj.value }
    public var isRootView: Bool { destinationsSubj.value.isEmpty }
    public var orTabChild: Self { tabChild ?? self }
    public var tabChild: Self? {
        tabs.first(where: { $0.tabItem == selectedTabSubj.value }) ?? tabs.first
    }
    public var isPresentedTab: Bool {
        if isTab {
            return parent?.parent != nil
        } else {
            return false
        }
    }
    public var isPresented: Bool {
        if isTab {
            return false
        } else {
            return parent != nil
        }
    }
    public var isTab: Bool { parent?.tabs.isEmpty == false }
    public var orTabParent: Self? {
        if parent?.tabs.isEmpty == false {
            return parent?.parent
        } else {
            return parent
        }
    }
    public var topChild: Self? {
        switch kind {
        case .tabView: tabChild
        case .flow, .singleView: childSubj.value
        }
    }
    public var topNavigator: Self {
        var navigator: Self! = self
        while navigator?.topChild != nil {
            navigator = navigator?.topChild
        }

        return navigator
    }
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
    /// A closure that is called when the initial navigator needs to be replaced.
    public var onReplaceInitialNavigator: ((_ newNavigator: Self) -> Void)? {
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

    /// Opens a given URL
    ///
    /// - Parameter url: The URL to open.
    public func open(url: URL) {
        environmentPubl.send(.openURL(url))
    }

    /// Opens a new window with the specified identifier.
    ///
    /// - Parameter window: The identifier of the window to open.
    @available(iOS 16.0, macOS 13.0, *)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public func open(window: String) {
        environmentPubl.send(.openWindow(id: window))
    }

    /// Dismisses a window with the specified identifier.
    ///
    /// - Parameter window: The identifier of the window to dismiss.
    @available(iOS 17.0, macOS 14.0, visionOS 1.0, *)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public func dismiss(window: String) {
        environmentPubl.send(.dismissWindow(id: window))
    }

    /// Pushes a new destination onto the navigation stack if supported by the current navigator.
    ///
    /// This method operates only when the `topNavigator` (or its selected tab child)
    /// is of kind `.flow`. In such cases, the provided `destination` is appended
    /// to the list of current destinations, triggering a UI update.
    ///
    /// - Parameters:
    ///   - destination: The destination to be pushed onto the navigation stack.
    ///   - animated: A Bool value indicating whether the push should be animated. Defaults to `true`.
    /// - Returns: `true` if the destination was successfully pushed; `false` otherwise.
    ///
    /// Example:
    /// ```swift
    /// navigator.push(destination: .detailsView)
    /// ```
    ///
    /// - Note: This method is a no-op for `.singleView` and `.tabView` navigators.
    @discardableResult
    public func push(destination: Destination, animated: Bool = true) -> Bool {
        navigatorLog?("push", "destination: \(destination)", "animated: \(animated)")
        let topNavigator = self.topNavigator.orTabChild
        switch topNavigator.kind {
        case .flow:
            var destinationsValue = topNavigator.destinationsSubj.value
            destinationsValue.append(destination)
            isAnimatedSubj.send(animated)
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
    ///   - animated: A Bool value indicating whether the push should be animated. Defaults to `true`.
    public func present(
        _ data: NavigatorData,
        strategy: NavigatorPresentationStrategy = .onTop,
        animated: Bool = true
    ) {
        present(
            getNavigator(data: data),
            strategy: strategy,
            animated: animated
        )
    }

    /// Presents a child navigator.
    ///
    /// - Parameters:
    ///   - child: The child navigator to present.
    ///   - strategy: Defines strategy for presenting a new navigator.
    ///   - animated: A Bool value indicating whether the push should be animated. Defaults to `true`.
    public func present(
        _ child: Self?,
        strategy: NavigatorPresentationStrategy = .onTop,
        animated: Bool = true
    ) {
        navigatorLog?("present", "child: \(child?.debugDescription ?? "nil")", "strategy: \(strategy)")
        isAnimatedSubj.send(animated)
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
    ///
    /// This method removes the last destination in the current navigator’s stack,
    /// simulating a back navigation. If the navigator is already at its root
    /// (`isRootView == true`), the operation is skipped and no changes are made.
    ///
    /// - Parameter animated: A Boolean indicating whether the pop transition should be animated. Defaults to `true`.
    public func pop(animated: Bool = true) {
        guard !isRootView else {
            navigatorLog?("pop", "not possible, isRootView: \(isRootView)", "animated: \(animated)")

            return
        }

        var destinationsValue = destinationsSubj.value
        let destination = destinationsValue.popLast()
        navigatorLog?("pop", "destination: \(String(describing: destination))", "animated: \(animated)")
        isAnimatedSubj.send(animated)
        destinationsSubj.send(destinationsValue)
    }

    /// Pops the navigation stack back to the root destination.
    ///
    /// This method clears all destinations in the current navigator’s stack,
    /// returning to the root. If the current navigator represents
    /// a root view (i.e., `isRootView == true`), the operation is skipped.
    ///
    /// - Parameter animated: A Boolean indicating whether the pop transition should be animated. Defaults to `true`.
    public func popToRoot(animated: Bool = true) {
        guard !isRootView else {
            navigatorLog?("popToRoot", "not possible, isRootView: \(isRootView)", "animated: \(animated)")

            return
        }

        navigatorLog?("popToRoot", "animated: \(animated)")
        isAnimatedSubj.send(animated)
        destinationsSubj.send([])
    }

    /// Pops the navigation stack to a specific destination.
    ///
    /// - Parameters:
    ///   - destination: The destination to pop to.
    ///   - animated: A Bool value indicating whether the push should be animated. Defaults to `true`.
    ///   - isFirst: If `true`, pops to the first occurrence of the destination; otherwise, pops to the last occurrence.
    /// - Returns: `true` if the destination was found and popped to, otherwise `false`.
    @discardableResult
    public func pop(target destination: Destination, animated: Bool = true, isFirst: Bool = true) -> Bool {
        return pop(predicate: { $0 == destination }, animated: animated, isFirst: isFirst)
    }

    /// Pops the navigation stack to a specific destination using predicate.
    ///
    /// - Parameters:
    ///   - predicate: A closure that takes a `Destination` as its argument and returns `true` if the destination satisfies the condition.
    ///   - animated: A Bool value indicating whether the push should be animated. Defaults to `true`.
    ///   - isFirst: If `true`, pops to the first occurrence of the destination; otherwise, pops to the last occurrence.
    /// - Returns: `true` if the destination was found and popped to, otherwise `false`.
    @discardableResult
    public func pop(predicate: (Destination) -> Bool, animated: Bool = true, isFirst: Bool = true) -> Bool {
        var destinationsValue = destinationsSubj.value

        if let index = isFirst ? destinationsValue.firstIndex(where: predicate) : destinationsValue.lastIndex(where: predicate),
            index + 1 < destinationsValue.count
        {
            navigatorLog?("pop", "destination: \(destinationsValue[index])", "animated: \(animated)")
            destinationsValue.removeSubrange(index + 1..<destinationsValue.count)
            isAnimatedSubj.send(animated)
            destinationsSubj.send(destinationsValue)

            return true
        } else {
            if let root, predicate(root) {
                popToRoot(animated: animated)

                return true
            }

            navigatorLog?("pop", "not possible, destination not found", "animated: \(animated)")

            return false
        }
    }

    /// Dismisses to a specific navigator by ID.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the navigator to dismiss to.
    ///   - animated: A Boolean indicating whether the dismissal transition should be animated. Defaults to `true`.
    /// - Returns: `true` if the navigator was found and dismissed to, otherwise `false`.
    @discardableResult
    public func dismissTo(id: UUID, animated: Bool = true) -> Bool {
        var topNavigator: Self? = self
        while topNavigator != nil {
            if topNavigator?.id == id {
                navigatorLog?("dismiss to", "id: \(id)")
                topNavigator?.present(nil, strategy: .fromCurrent, animated: animated)

                return true
            }

            topNavigator = topNavigator?.parent
        }
        navigatorLog?("dismiss to", "not possible, id: \(id) not found")

        return false
    }

    /// Dismisses to a specific destination.
    ///
    /// - Parameters:
    ///   - destination: The specific `Destination` to dismiss to.
    ///   - animated: A Boolean indicating whether the dismissal transition should be animated. Defaults to `true`.
    /// - Returns: `true` if the destination was found and dismissed to, otherwise `false`.
    @discardableResult
    public func dismiss(target destination: Destination, animated: Bool = true) -> Bool {
        return dismiss(predicate: { $0 == destination }, animated: animated)
    }

    /// Dismisses to a specific destination.
    ///
    /// - Parameters:
    ///   - predicate: A closure that takes a `Destination` and returns `true` if it matches the target for dismissal.
    ///   - animated: A Boolean indicating whether the dismissal transition should be animated. Defaults to `true`.
    /// - Returns: `true` if the destination was found and dismissed to, otherwise `false`.
    @discardableResult
    public func dismiss(predicate: (Destination) -> Bool, animated: Bool = true) -> Bool {
        var topNavigator: Self? = self
        while topNavigator != nil {
            if let destination = topNavigator?.root, predicate(destination) {
                navigatorLog?("dismiss to", "destination: \(destination)")
                topNavigator?.present(nil, strategy: .fromCurrent, animated: animated)

                return true
            }

            topNavigator = topNavigator?.parent
        }
        navigatorLog?("dismiss to", "not possible, destination not found")

        return false
    }

    /// Replaces the root destination.
    ///
    /// - Parameters:
    ///   - root: The new root destination.
    ///   - animated: A Bool value indicating whether the push should be animated. Defaults to `true`.
    ///   - isPopToRoot: If `true`, pops to the root before replacing it.
    public func replace(_ root: Destination, animated: Bool = true, isPopToRoot: Bool = true) {
        if isPopToRoot {
            navigatorLog?("replace root", "pop to root")
            popToRoot(animated: animated)
        }
        navigatorLog?("replace root", "destination: \(root)")
        isAnimatedSubj.send(animated)
        rootSubj.send(root)
    }

    /// Dismisses the current top navigator from its parent, optionally including tab-based navigators.
    ///
    /// This method removes the current navigator from presentation by asking its parent
    /// to present `nil` using a `.fromCurrent` strategy. If the current navigator is part of a tab view,
    /// and `includingTabView` is `true`, the parent of the tab container will dismiss instead.
    ///
    /// - Parameters:
    ///   - includingTabView: If `true`, and the current navigator is inside a tab view,
    ///     the entire tab container will be dismissed from its parent. Defaults to `false`.
    ///   - animated: A Boolean indicating whether the dismissal should be animated. Defaults to `true`.
    public func dismissTop(includingTabView: Bool = false, animated: Bool = true) {
        navigatorLog?("dismiss top", "animated: \(animated)")
        if parent?.tabs.isEmpty == false && includingTabView {
            parent?.parent?.present(nil, strategy: .fromCurrent, animated: animated)
        } else {
            parent?.present(nil, strategy: .fromCurrent, animated: animated)
        }
    }

    /// Attempts to navigate to a specified target destination by traversing
    /// up the hierarchy of navigators.
    ///
    /// - Parameters:
    ///   - target: The destination to close to. Must match exactly with an existing destination in the hierarchy.
    ///   - animated: A Boolean indicating whether the closing transition should be animated. Defaults to `true`.
    /// - Returns: `true` if navigation to the target destination is successful, `false` otherwise.
    @discardableResult
    public func close(target: Destination, animated: Bool = true) -> Bool {
        var navigator: Self? = topNavigator
        while navigator != nil {
            if navigator?.closeIn(where: { $0 == target }, animated: animated) == true {
                return true
            }
            navigator = navigator?.parent
        }

        return false
    }

    /// Attempts to navigate to a destination that satisfies the given predicate by traversing
    /// up the hierarchy of navigators.
    ///
    /// - Parameters:
    ///   - predicate: A closure that takes a `Destination` as input and returns `true` if the destination matches the desired condition.
    ///   - animated: A Bool indicating whether the closing transition should be animated. Defaults to `true`.
    /// - Returns: `true` if a destination satisfying the predicate is found and navigation is successfully performed, `false` otherwise.
    public func close(predicate: (Destination) -> Bool, animated: Bool = true) -> Bool {
        var navigator: Self? = topNavigator
        while navigator != nil {
            if navigator?.closeIn(where: predicate, animated: animated) == true {
                return true
            }

            navigator = navigator?.parent
        }

        return false
    }

    private func closeIn(where predicate: (Destination) -> Bool, animated: Bool = true) -> Bool {
        for destination in destinationsSubj.value.reversed() {
            if predicate(destination) {
                present(nil, strategy: .fromCurrent, animated: animated)
                pop(predicate: predicate, animated: animated)

                return true
            }
        }
        if let destination = root, predicate(destination) {
            present(nil, strategy: .fromCurrent, animated: animated)
            popToRoot(animated: animated)

            return true
        }

        return false
    }

    /// Closes the navigator to the initial first navigator.
    ///
    /// This method traverses up the navigator hierarchy to find the root navigator (the first created one),
    /// then dismisses any presented views and resets the navigation stack based on the kind of navigator.
    ///
    /// - Parameter animated: Indicates whether the transition should be animated. Defaults to `true`.
    public func closeToInitial(animated: Bool = true) {
        navigatorLog?("close to initial")
        var firstNavigator: Self! = self
        while firstNavigator.parent != nil {
            firstNavigator = firstNavigator.parent
        }
        switch firstNavigator.kind {
        case .tabView:
            firstNavigator.tabs.forEach {
                $0.present(nil, strategy: .fromCurrent, animated: animated)
                $0.popToRoot(animated: animated)
            }
        case .flow:
            firstNavigator.present(nil, strategy: .fromCurrent, animated: animated)
            firstNavigator.popToRoot(animated: animated)
        case .singleView:
            firstNavigator.present(nil, strategy: .fromCurrent, animated: animated)
        }
    }

    /// Dispatches an action to the environment.
    ///
    /// This method sends the provided action, making it available to any view
    /// that has registered an external action handler via `.handle(_)` or `.handle<T>(_)`.
    ///
    /// - Parameter action: The action to dispatch.
    public func pass(action: Any) {
        environmentPubl.send(.external(action))
    }

    public func getNavigator(data: NavigatorData) -> Self? {
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

extension BaseNavigator {

    /// Pushes a new destination onto the navigation stack.
    /// - Parameters:
    ///   - destination: The destination to push onto the navigation stack. Must conform to the navigator’s `Destination` type.
    ///   - animated: A Bool value indicating whether the push transition should be animated. Defaults to `true`.
    /// - Returns: `true` if the destination matches base type, otherwise `false`.
    @discardableResult
    public func push(_ destination: any Hashable, animated: Bool = true) -> Bool {
        guard let destination = destination as? Destination else {
            navigatorLog?("Push only the specified `Destination` type. Found: \(type(of: destination)). Destination: \(Destination.self)")

            return false
        }

        return push(destination: destination, animated: animated)
    }

    /// Pops the navigation stack to a specific destination.
    ///
    /// - Parameters:
    ///   - destination: The destination to pop to.
    ///   - animated: A Bool value indicating whether the push should be animated. Defaults to `true`.
    ///   - isFirst: If `true`, pops to the first occurrence of the destination; otherwise, pops to the last occurrence.
    /// - Returns: `true` if the destination was found and popped to, otherwise `false`.
    @discardableResult
    public func pop(to destination: any Hashable, animated: Bool = true, isFirst: Bool = true) -> Bool {
        guard let destination = destination as? Destination else {
            navigatorLog?("Pop only the specified `Destination` type. Found: \(type(of: destination)). Destination: \(Destination.self)")

            return false
        }

        return pop(target: destination, animated: animated, isFirst: isFirst)
    }

    /// Replaces the root destination.
    ///
    /// - Parameters:
    ///   - root: The new root destination.
    ///   - animated: A Bool value indicating whether the push should be animated. Defaults to `true`.
    ///   - isPopToRoot: If `true`, pops to the root before replacing it.
    /// - Returns: `true` if the destination was correct, otherwise `false`.
    @discardableResult
    public func replace(root destination: any Hashable, animated: Bool = true, isPopToRoot: Bool = true) -> Bool {
        guard let destination = destination as? Destination else {
            navigatorLog?("Replace only the specified `Destination` type. Found: \(type(of: destination)). Destination: \(Destination.self)")

            return false
        }

        replace(destination, animated: animated, isPopToRoot: isPopToRoot)

        return true
    }

    /// Dismisses to a specific destination.
    ///
    /// - Parameters:
    ///   - destination: The target destination to dismiss to. Must be of the navigator's `Destination` type.
    ///   - animated: A Bool value indicating whether the dismissals should be animated. Defaults to `true`.
    /// - Returns: `true` if the destination was found and dismissed to, otherwise `false`.
    @discardableResult
    public func dismiss(to destination: any Hashable, animated: Bool = true) -> Bool {
        guard let destination = destination as? Destination else {
            navigatorLog?("Dismiss only the specified `Destination` type. Found: \(type(of: destination)). Destination: \(Destination.self)")

            return false
        }

        return dismiss(target: destination, animated: animated)
    }

    /// Attempts to navigate to a specified target destination by traversing
    /// up the hierarchy of navigators.
    ///
    /// - Parameters:
    ///   - destination: The target destination to navigate back to. Must be of the same type as the navigator's `Destination`.
    ///   - animated: A Bool value indicating whether the closing transition should be animated. Defaults to `true`.
    /// - Returns: `true` if navigation to the target destination is successful, `false` otherwise.
    @discardableResult
    public func close(to destination: any Hashable, animated: Bool = true) -> Bool {
        guard let destination = destination as? Destination else {
            navigatorLog?("Close only the specified `Destination` type. Found: \(type(of: destination)). Destination: \(Destination.self)")

            return false
        }

        return close(target: destination, animated: animated)
    }

    /// Attempts to navigate to a destination that satisfies the given predicate by traversing
    /// up the hierarchy of navigators.
    ///
    /// - Parameters:
    ///   - predicate: A closure that takes a `Destination` (of type `any Hashable`)
    ///     and returns `true` if the destination should be closed to.
    ///   - animated: A Bool value indicating whether the closing transition should be animated. Defaults to `true`.
    /// - Returns: `true` if a destination satisfying the predicate is found and navigation is successfully performed, `false` otherwise.
    public func close(where predicate: (any Hashable) -> Bool, animated: Bool = true) -> Bool {
        return close(predicate: predicate, animated: animated)
    }
}
