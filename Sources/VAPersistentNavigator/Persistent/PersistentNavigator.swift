//
//  PersistentNavigator.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 12/24/24.
//

import Foundation
import SwiftUI
import Combine

@MainActor
public protocol PersistentNavigator: SimpleNavigator {
    var storeSubj: PassthroughSubject<Void, Never> { get }
}

public extension PersistentNavigator {

    /// Pushes a new destination onto the navigation stack.
    /// - Returns: `true` if the destination matches base type, otherwise `false`.
    @discardableResult
    public func push(_ destination: any PersistentDestination) -> Bool {
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
    public func pop(to destination: any PersistentDestination, isFirst: Bool) -> Bool {
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
    public func replace(root: any PersistentDestination, isPopToRoot: Bool) {
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
    public func dismiss(to destination: any PersistentDestination) -> Bool {
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
    public func close(to destination: any PersistentDestination) -> Bool {
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
    public func close(where predicate: ((any PersistentDestination)?) -> Bool) -> Bool {
        return close(where: { predicate($0 as? any PersistentDestination) })
    }
}

public protocol PersistentDestination: Codable & Hashable {}

public protocol PersistentTabItemTag: Codable & Hashable {}

public protocol PersistentSheetTag: Codable & Hashable {}

final class EmptyPersistentNavigator: PersistentNavigator {
    typealias Destination = String
    typealias Tab = String
    typealias Tag = String
    
    var storeSubj: PassthroughSubject<Void, Never> { .init() }
    var destinationsSubj: CurrentValueSubject<[Destination], Never> { .init([]) }
    var parent: EmptyPersistentNavigator? { nil }
    var tabItem: Tab?
    var selectedTabSubj: CurrentValueSubject<Tab?, Never> { .init(nil) }
    var rootSubj: CurrentValueSubject<Destination?, Never> { .init(nil) }
    var childSubj: CurrentValueSubject<EmptyPersistentNavigator?, Never> { .init(nil) }
    var tabs: [EmptyPersistentNavigator] { [] }
    var kind: NavigatorKind { .singleView }
    var presentation: TypedNavigatorPresentation<Tag> { .sheet }
    var id: UUID { UUID() }
    var isRootView: Bool { true }
    nonisolated var debugDescription: String { "" }

    nonisolated init() {}

    func getNavigator(data: NavigatorData) -> Self? {
        return nil
    }
}

extension EnvironmentValues {
    @Entry public var baseNavigator: any BaseNavigator = emptyPersistentNavigator
    @Entry public var simpleNavigator: any SimpleNavigator = emptyPersistentNavigator
    @Entry public var persistentNavigator: any PersistentNavigator = emptyPersistentNavigator

    static let emptyPersistentNavigator = EmptyPersistentNavigator()
}
