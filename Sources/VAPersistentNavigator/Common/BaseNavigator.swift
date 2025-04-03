//
//  BaseNavigator.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 4/3/25.
//

import Foundation
import Combine

@MainActor
public protocol BaseNavigator: AnyObject, CustomDebugStringConvertible {
    associatedtype Tab: Hashable
    associatedtype Destination: Hashable
    associatedtype Tag: Hashable

    var id: UUID { get }
    var isRootView: Bool { get }
    var kind: NavigatorKind { get }
    var tabs: [Self] { get }
    var presentation: TypedNavigatorPresentation<Tag> { get }
    var tabItem: Tab? { get }
    var selectedTabSubj: CurrentValueSubject<Tab?, Never> { get }
    var childSubj: CurrentValueSubject<Self?, Never> { get }
    var rootSubj: CurrentValueSubject<Destination?, Never> { get }
    var destinationsSubj: CurrentValueSubject<[Destination], Never> { get }
    var parent: Self? { get }

    func getNavigator(data: NavigatorData) -> Self?
}

public extension BaseNavigator {
    var root: Destination? { rootSubj.value }
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
    public var currentTab: Tab? {
        get { kind.isTabView ? selectedTabSubj.value : parent?.currentTab }
        set {
            if kind.isTabView {
                selectedTabSubj.send(newValue)
            } else {
                parent?.currentTab = newValue
            }
        }
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
    public func present(
        _ child: Self?,
        strategy: NavigatorPresentationStrategy = .onTop
    ) {
#if DEBUG
        navigatorLog?("present", "child: \(child?.debugDescription ?? "nil")", "strategy: \(strategy)")
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

    /// Dismisses to a specific navigator by ID.
    ///
    /// - Parameter id: The ID of the navigator to dismiss to.
    /// - Returns: `true` if the navigator was found and dismissed to, otherwise `false`.
    @discardableResult
    public func dismiss(to id: UUID) -> Bool {
        var topNavigator: Self? = self
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

    /// Dismisses to a specific destination.
    ///
    /// - Parameter destination: The destination to dismiss to.
    /// - Returns: `true` if the destination was found and dismissed to, otherwise `false`.
    @discardableResult
    public func dismiss(to destination: Destination) -> Bool {
        var topNavigator: Self? = self
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
    public func close(to target: Destination) -> Bool {
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
    public func close(where predicate: (Destination) -> Bool) -> Bool {
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
        var firstNavigator: Self! = self
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

    private func popToRootIfNeeded(in navigator: Self) {
        if !navigator.destinationsSubj.value.isEmpty {
            navigator.popToRoot()
        }
    }

    private func dismissIfNeeded(in navigator: Self) {
        if navigator.childSubj.value != nil {
            navigator.present(nil, strategy: .fromCurrent)
        }
    }
}
