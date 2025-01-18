//
//  PersistentNavigator.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 12/24/24.
//

import Foundation

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
    func replace(root: any PersistentDestination, isPopToRoot: Bool)
    func present(_ data: NavigatorData, strategy: PresentationStrategy)
}

public extension PersistentNavigator {

    func present(_ data: NavigatorData) {
        present(data, strategy: .onTop)
    }

    func pop(to destination: any PersistentDestination) -> Bool {
        pop(to: destination, isFirst: true)
    }

    func replace(root: any PersistentDestination) {
        replace(root: root, isPopToRoot: true)
    }
}

/// Defines strategies for presenting a new navigator in the app.
public enum PresentationStrategy {
    /// Presents a new navigator from the top-most available navigator.
    case onTop
    /// Replaces the currently presented navigator with a new one.
    case replaceCurrent
    /// Presents a new navigator from the current navigator.
    case fromCurrent
}

public enum NavigatorData {
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
        tabs: [NavigatorData] = [],
        id: UUID = .init(),
        presentation: PersistentNavigatorPresentation = .sheet,
        selectedTab: (any PersistentTabItemTag)? = nil
    )
}

public protocol PersistentDestination: Codable & Hashable {}

public protocol PersistentTabItemTag: Codable & Hashable {}

public protocol PersistentSheetTag: Codable & Hashable {}
