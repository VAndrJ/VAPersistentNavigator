//
//  PersistentNavigator.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 12/24/24.
//

import Foundation
import Combine

@MainActor
public protocol PersistentNavigator: BaseNavigator {
    var storeSubj: PassthroughSubject<Void, Never> { get }
}

public extension PersistentNavigator {

    /// Pushes a new destination onto the navigation stack.
    /// - Returns: `true` if the destination matches base type, otherwise `false`.
    @discardableResult
    func push(_ destination: any PersistentDestination) -> Bool {
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
    func pop(to destination: any PersistentDestination, isFirst: Bool = true) -> Bool {
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
    func replace(root destination: any PersistentDestination, isPopToRoot: Bool = true) -> Bool {
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
    func dismiss(to destination: any PersistentDestination) -> Bool {
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
    func close(to destination: any PersistentDestination) -> Bool {
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
    func close(where predicate: ((any PersistentDestination)?) -> Bool) -> Bool {
        return close(predicate: { predicate($0 as? any PersistentDestination) })
    }

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

public protocol PersistentDestination: Codable & Hashable {}

public protocol PersistentTabItemTag: Codable & Hashable {}

public protocol PersistentSheetTag: Codable & Hashable {}
