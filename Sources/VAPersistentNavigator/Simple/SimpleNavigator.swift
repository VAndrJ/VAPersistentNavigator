//
//  SimpleNavigator.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 4/3/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
public protocol SimpleNavigator: AnyObject, CustomDebugStringConvertible {
    var id: UUID { get }
    var isRootView: Bool { get }
    var presentation: SimpleNavigatorPresentation { get }
    var topChild: (any SimpleNavigator)? { get }
    var orTabChild: any SimpleNavigator { get }
    var kind: NavigatorKind { get }
    var destinationsSubj: CurrentValueSubject<[AnyHashable], Never> { get }
    var childSubj: CurrentValueSubject<(any SimpleNavigator)?, Never> { get }
    var parent: (any SimpleNavigator)? { get }
    var currentTab: AnyHashable? { get  set }
    var onReplaceInitialNavigator: ((_ newNavigator: (any SimpleNavigator)) -> Void)? { get set }
    var root: AnyHashable? { get }
    var tabs: [any SimpleNavigator] { get }
    var tabItem: AnyHashable? { get }
    var rootSubj: CurrentValueSubject<AnyHashable?, Never> { get }
    var selectedTabSubj: CurrentValueSubject<AnyHashable?, Never> { get }
    var topNavigator: any SimpleNavigator { get }

    func getNavigator(data: SimpleNavigatorData) -> (any SimpleNavigator)?
}

public extension SimpleNavigator {

    /// Pushes a new destination onto the navigation stack.
    @discardableResult
    public func push(_ destination: any Hashable) -> Bool {
#if DEBUG
        navigatorLog?("push", "destination: \(destination)")
#endif
        let topNavigator = self.topNavigator.orTabChild
        switch topNavigator.kind {
        case .flow:
            var destinationsValue = topNavigator.destinationsSubj.value
            destinationsValue.append(destination.anyHashable)
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
    func present(_ data: SimpleNavigatorData, strategy: PresentationStrategy = .onTop) {
        present(child: getNavigator(data: data), strategy: strategy)
    }

    /// Presents a child navigator.
    ///
    /// - Parameters:
    ///   - child: The child navigator to present.
    ///   - strategy: Defines strategy for presenting a new navigator.
    public func present(
        child: (any SimpleNavigator)?,
        strategy: PresentationStrategy = .onTop
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
    public func pop(to destination: any Hashable, isFirst: Bool = true) -> Bool {
        var destinationsValue = destinationsSubj.value
        if let index = isFirst ? destinationsValue.firstIndex(where: { $0 == destination.anyHashable }) : destinationsValue.lastIndex(where: { $0 == destination.anyHashable }), index + 1 < destinationsValue.count {
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

    /// Dismisses to a specific destination.
    ///
    /// - Parameter destination: The destination to dismiss to.
    /// - Returns: `true` if the destination was found and dismissed to, otherwise `false`.
    @discardableResult
    public func dismiss(to destination: any Hashable) -> Bool {
        var topNavigator: (any SimpleNavigator)? = self
        while topNavigator != nil {
            if topNavigator?.root == destination.anyHashable {
#if DEBUG
                navigatorLog?("dismiss to", "destination: \(destination)")
#endif
                topNavigator?.present(child: nil, strategy: .fromCurrent)

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
        var topNavigator: (any SimpleNavigator)? = self
        while topNavigator != nil {
            if topNavigator?.id == id {
#if DEBUG
                navigatorLog?("dismiss to", "id: \(id)")
#endif
                topNavigator?.present(child: nil, strategy: .fromCurrent)

                return true
            }

            topNavigator = topNavigator?.parent
        }
#if DEBUG
        navigatorLog?("dismiss to", "not possible, id: \(id) not found")
#endif

        return false
    }

    /// Replaces the root destination.
    ///
    /// - Parameters:
    ///   - root: The new root destination.
    ///   - isPopToRoot: If `true`, pops to the root before replacing it.
    public func replace(root: any Hashable, isPopToRoot: Bool = true) {
        if isPopToRoot {
#if DEBUG
            navigatorLog?("replace root", "pop to root")
#endif
            popToRoot()
        }
#if DEBUG
        navigatorLog?("replace root", "destination: \(root)")
#endif
        rootSubj.send(root.anyHashable)
    }

    /// Dismisses the current top navigator.
    public func dismissTop() {
#if DEBUG
        navigatorLog?("dismiss top")
#endif
        parent?.present(child: nil, strategy: .fromCurrent)
    }

    /// Attempts to navigate to a specified target destination by traversing
    /// up the hierarchy of navigators.
    ///
    /// - Parameter target: The destination to which the method attempts to navigate.
    /// - Returns: `true` if navigation to the target destination is successful, `false` otherwise.
    @discardableResult
    public func close(to target: any Hashable) -> Bool {
        var navigator: (any SimpleNavigator)? = topNavigator
        while navigator != nil {
            if navigator?.closeIn(where: { $0 == target.anyHashable }) == true {
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
    public func close(where predicate: (any Hashable) -> Bool) -> Bool {
        var navigator: (any SimpleNavigator)? = topNavigator
        while navigator != nil {
            if navigator?.closeIn(where: predicate) == true {
                return true
            }
            navigator = navigator?.parent
        }

        return false
    }

    private func closeIn(where predicate: (AnyHashable) -> Bool) -> Bool {
        for destination in destinationsSubj.value.reversed() {
            if predicate(destination) {
                present(child: nil, strategy: .fromCurrent)
                pop(to: destination)

                return true
            }
        }
        if let destination = root, predicate(destination) {
            present(child: nil, strategy: .fromCurrent)
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
        var firstNavigator: (any SimpleNavigator)! = self
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

    private func popToRootIfNeeded(in navigator: any SimpleNavigator) {
        if !navigator.destinationsSubj.value.isEmpty {
            navigator.popToRoot()
        }
    }

    private func dismissIfNeeded(in navigator: any SimpleNavigator) {
        if navigator.childSubj.value != nil {
            navigator.present(child: nil, strategy: .fromCurrent)
        }
    }
}

public enum SimpleNavigatorData {
    case view(
        _ view: any Hashable,
        id: UUID = .init(),
        presentation: SimpleNavigatorPresentation = .sheet,
        tabItem: (any Hashable)? = nil
    )
    case stack(
        root: any Hashable,
        id: UUID = .init(),
        destinations: [any Hashable] = [],
        presentation: SimpleNavigatorPresentation = .sheet,
        tabItem: (any Hashable)? = nil
    )
    indirect case tab(
        tabs: [SimpleNavigatorData] = [],
        id: UUID = .init(),
        presentation: SimpleNavigatorPresentation = .sheet,
        selectedTab: (any Hashable)? = nil
    )
}

final class EmptySimpleNavigator: SimpleNavigator {
    var id: UUID { UUID() }
    var isRootView: Bool { true }
    var presentation: SimpleNavigatorPresentation { .sheet }
    var topChild: (any SimpleNavigator)? { nil }
    var orTabChild: any SimpleNavigator { self }
    var kind: NavigatorKind { .singleView }
    var destinationsSubj: CurrentValueSubject<[AnyHashable], Never> { .init([]) }
    var childSubj: CurrentValueSubject<(any SimpleNavigator)?, Never> { .init(nil) }
    var parent: (any SimpleNavigator)? { nil }
    var currentTab: AnyHashable?
    var onReplaceInitialNavigator: ((any SimpleNavigator) -> Void)?
    var root: AnyHashable? { nil }
    let tabs: [any SimpleNavigator] = []
    var tabItem: AnyHashable? { nil }
    var rootSubj: CurrentValueSubject<AnyHashable?, Never> { .init(nil) }
    var selectedTabSubj: CurrentValueSubject<AnyHashable?, Never> { .init(nil) }
    nonisolated var debugDescription: String { "" }
    var topNavigator: any SimpleNavigator { self }

    nonisolated init() {}

    func getNavigator(data: SimpleNavigatorData) -> (any SimpleNavigator)? {
        return nil
    }
}

extension EnvironmentValues {
    @Entry public var simpleNavigator: any SimpleNavigator = emptySimpleNavigator

    private static let emptySimpleNavigator = EmptySimpleNavigator()
}
