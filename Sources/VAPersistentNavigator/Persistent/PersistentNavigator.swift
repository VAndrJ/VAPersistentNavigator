//
//  PersistentNavigator.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 12/24/24.
//

import Combine
import Foundation

/// A persistable navigation destination.
///
/// Use this protocol to mark navigation destinations that can be encoded and decoded.
public protocol PersistentDestination: Codable & Hashable {}

/// A tag for identifying a tab item in a persistable navigation context.
///
/// Use this protocol to mark tab tags that can be encoded and decoded.
public protocol PersistentTabItemTag: Codable & Hashable {}

/// A tag for identifying a sheet presentation in a persistable navigation context.
///
/// Use this protocol to mark sheet tags that can be encoded and decoded.
public protocol PersistentSheetTag: Codable & Hashable {}

/// A navigator that supports persistence by emitting store signals through a subject.
///
/// Conforming types are expected to emit to `storeSubj` whenever their internal state changes
/// in a way that should be persisted. This enables external systems (e.g., storage layers) to
/// observe and debounce state saves efficiently.
///
/// Combine this with `NavigatorStoringView` for automatic persistence.
public protocol PersistentNavigator: BaseNavigator {
    /// A subject that emits whenever the navigator’s state should be stored.
    var storeSubj: PassthroughSubject<Void, Never> { get }
}

extension PersistentNavigator {

    /// Pushes a new destination onto the navigation stack.
    /// - Returns: `true` if the destination matches base type, otherwise `false`.
    @discardableResult
    public func push(_ destination: any PersistentDestination, animated: Bool = true) -> Bool {
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
    ///   - isFirst: If `true`, pops to the first occurrence of the destination; otherwise, pops to the last occurrence.
    /// - Returns: `true` if the destination was found and popped to, otherwise `false`.
    public func pop(to destination: any PersistentDestination, animated: Bool = true, isFirst: Bool = true) -> Bool {
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
    ///   - isPopToRoot: If `true`, pops to the root before replacing it.
    /// - Returns: `true` if the destination was correct, otherwise `false`.
    @discardableResult
    public func replace(root destination: any PersistentDestination, animated: Bool = true, isPopToRoot: Bool = true) -> Bool {
        guard let destination = destination as? Destination else {
            navigatorLog?("Replace only the specified `Destination` type. Found: \(type(of: destination)). Destination: \(Destination.self)")

            return false
        }

        replace(destination, animated: animated, isPopToRoot: isPopToRoot)

        return true
    }

    /// Dismisses to a specific destination.
    ///
    /// - Parameter destination: The destination to dismiss to.
    /// - Returns: `true` if the destination was found and dismissed to, otherwise `false`.
    @discardableResult
    public func dismiss(to destination: any PersistentDestination, animated: Bool = true) -> Bool {
        guard let destination = destination as? Destination else {
            navigatorLog?("Dismiss only the specified `Destination` type. Found: \(type(of: destination)). Destination: \(Destination.self)")

            return false
        }

        return dismiss(target: destination, animated: animated)
    }

    /// Attempts to navigate to a specified target destination by traversing
    /// up the hierarchy of navigators.
    ///
    /// - Parameter target: The destination to which the method attempts to navigate.
    /// - Returns: `true` if navigation to the target destination is successful, `false` otherwise.
    @discardableResult
    public func close(to destination: any PersistentDestination, animated: Bool = true) -> Bool {
        guard let destination = destination as? Destination else {
            navigatorLog?("Close only the specified `Destination` type. Found: \(type(of: destination)). Destination: \(Destination.self)")

            return false
        }

        return close(target: destination, animated: animated)
    }

    /// Attempts to navigate to a destination that satisfies the given predicate by traversing
    /// up the hierarchy of navigators.
    ///
    /// - Parameter predicate: A closure that takes a `Destination` as its argument and returns `true` if the destination satisfies the condition.
    /// - Returns: `true` if a destination satisfying the predicate is found and navigation is successfully performed, `false` otherwise.
    public func close(where predicate: ((any PersistentDestination)?) -> Bool, animated: Bool = true) -> Bool {
        return close(predicate: { predicate($0 as? any PersistentDestination) }, animated: animated)
    }
}

extension PersistentNavigator {

    func bindStoring() {
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
            child.storeSubj
                .sink(receiveValue: storeSubj.send)
                .store(in: &bag)
        }
        childSubj
            .sink { [weak self] in
                self?.bindChildStoring($0)
            }
            .store(in: &bag)
    }

    private func bindChildStoring(_ child: Self?) {
        childCancellable?.cancel()
        if let child {
            childCancellable = child.storeSubj
                .sink(receiveValue: storeSubj.send)
        } else {
            childCancellable = nil
        }
        storeSubj.send(())
    }
}
