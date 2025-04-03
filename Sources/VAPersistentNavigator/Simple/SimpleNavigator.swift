//
//  SimpleNavigator.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 4/3/25.
//

import Foundation

@MainActor
public protocol SimpleNavigator: BaseNavigator {}

public extension SimpleNavigator {

    /// Pushes a new destination onto the navigation stack.
    /// - Returns: `true` if the destination matches base type, otherwise `false`.
    @discardableResult
    func push(_ destination: any Hashable) -> Bool {
        guard let destination = destination as? Destination else {
            assertionFailure("Push only the specified `Destination` type.")
            
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
            assertionFailure("Pop only the specified `Destination` type.")
            
            return false
        }

        return pop(to: destination, isFirst: isFirst)
    }

    /// Replaces the root destination.
    ///
    /// - Parameters:
    ///   - root: The new root destination.
    ///   - isPopToRoot: If `true`, pops to the root before replacing it.
    func replace(root: any Hashable, isPopToRoot: Bool) {
        guard let destination = root as? Destination else {
            assertionFailure("Pop only the specified `Destination` type.")

            return
        }

        replace(root: destination, isPopToRoot: isPopToRoot)
    }

    /// Dismisses to a specific destination.
    ///
    /// - Parameter destination: The destination to dismiss to.
    /// - Returns: `true` if the destination was found and dismissed to, otherwise `false`.
    @discardableResult
    func dismiss(to destination: any Hashable) -> Bool {
        guard let destination = destination as? Destination else {
            assertionFailure("Pop only the specified `Destination` type.")
            
            return false
        }

        return dismiss(to: destination)
    }

    /// Attempts to navigate to a specified target destination by traversing
    /// up the hierarchy of navigators.
    ///
    /// - Parameter target: The destination to which the method attempts to navigate.
    /// - Returns: `true` if navigation to the target destination is successful, `false` otherwise.
    @discardableResult
    func close(to destination: any Hashable) -> Bool {
        guard let destination = destination as? Destination else {
            assertionFailure("Close only the specified `Destination` type.")
            
            return false
        }

        return close(to: destination)
    }

    /// Attempts to navigate to a destination that satisfies the given predicate by traversing
    /// up the hierarchy of navigators.
    ///
    /// - Parameter predicate: A closure that takes a `Destination` as its argument and returns `true` if the destination satisfies the condition.
    /// - Returns: `true` if a destination satisfying the predicate is found and navigation is successfully performed, `false` otherwise.
    func closeTo(where predicate: (any Hashable) -> Bool) -> Bool {
        return close(where: predicate)
    }
}
