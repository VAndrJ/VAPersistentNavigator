//
//  PersistentNavigator.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 12/24/24.
//

import Foundation
import SwiftUI

@MainActor
public protocol PersistentNavigator {
    var id: UUID { get }
    var isRootView: Bool { get }

    @discardableResult
    func push(_ destination: any PersistentDestination) -> Bool
    func pop()
    func pop(to destination: any PersistentDestination, isFirst: Bool) -> Bool
    func popToRoot()
    @discardableResult
    func dismiss(to destination: any PersistentDestination) -> Bool
    @discardableResult
    func dismiss(to id: UUID) -> Bool
    func dismissTop()
    func closeToInitial()
    @discardableResult
    func closeTo(destination: any PersistentDestination) -> Bool
    @discardableResult
    func closeTo(where predicate: (any PersistentDestination) -> Bool) -> Bool
    func replace(root: any PersistentDestination, isPopToRoot: Bool)
    func present(_ data: PersistentNavigatorData, strategy: NavigatorPresentationStrategy)
}

public extension PersistentNavigator {

    func present(_ data: PersistentNavigatorData) {
        present(data, strategy: .onTop)
    }

    func pop(to destination: any PersistentDestination) -> Bool {
        pop(to: destination, isFirst: true)
    }

    func replace(root: any PersistentDestination) {
        replace(root: root, isPopToRoot: true)
    }
}

public enum PersistentNavigatorData {
    case view(
        _ view: any PersistentDestination,
        id: UUID = .init(),
        presentation: PersistentNavigatorPresentation = .sheet,
        tabItem: (any PersistentTabItemTag)? = nil
    )
    case stack(
        root: any PersistentDestination,
        id: UUID = .init(),
        destinations: [any PersistentDestination] = [],
        presentation: PersistentNavigatorPresentation = .sheet,
        tabItem: (any PersistentTabItemTag)? = nil
    )
    indirect case tab(
        tabs: [PersistentNavigatorData] = [],
        id: UUID = .init(),
        presentation: PersistentNavigatorPresentation = .sheet,
        selectedTab: (any PersistentTabItemTag)? = nil
    )
}

public protocol PersistentDestination: Codable & Hashable {}

public protocol PersistentTabItemTag: Codable & Hashable {}

public protocol PersistentSheetTag: Codable & Hashable {}

final class EmptyPersistentNavigator: PersistentNavigator {
    var id: UUID { UUID() }
    var isRootView: Bool { true }

    nonisolated init() {}

    func replace(root: any PersistentDestination, isPopToRoot: Bool) {}

    func dismissTop() {}

    func closeToInitial() {}

    func dismiss(to destination: any PersistentDestination) -> Bool {
        return false
    }

    func popToRoot() {}

    func dismiss(to id: UUID) -> Bool {
        return false
    }

    @discardableResult
    func push(_ destination: any PersistentDestination) -> Bool {
        return false
    }

    func pop() {}

    func pop(to destination: any PersistentDestination, isFirst: Bool) -> Bool {
        return false
    }

    func present(_ data: PersistentNavigatorData, strategy: NavigatorPresentationStrategy) {}

    @discardableResult
    func closeTo(destination: any PersistentDestination) -> Bool {
        return false
    }

    @discardableResult
    func closeTo(where predicate: (any PersistentDestination) -> Bool) -> Bool {
        return false
    }
}

extension EnvironmentValues {
    @Entry public var persistentNavigator: any PersistentNavigator = emptyPersistentNavigator

    private static let emptyPersistentNavigator = EmptyPersistentNavigator()
}
