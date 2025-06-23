//
//  NavigatorData.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 4/3/25.
//

import Foundation

/// A type-erased enum that describes different navigation configurations in a tree-like structure.
///
/// `NavigatorData` acts as a blueprint for constructing navigation hierarchies,
/// including single views, navigation stacks, and tabbed interfaces.
/// Each case holds all necessary data to represent its navigation form,
/// and may include presentation style and optional tab item identification.
public enum NavigatorData: @unchecked Sendable {
    /// A single view navigation node.
    ///
    /// - Parameters:
    ///   - view: The hashable identifier for the destination view.
    ///   - id: A unique identifier for this navigation node.
    ///   - presentation: The style of presentation (e.g., sheet or full screen).
    ///   - tabItem: Optional tab item identifier if used in a tab view.
    case view(
        _ view: any Hashable,
        id: UUID = .init(),
        presentation: NavigatorPresentation = .sheet,
        tabItem: (any Hashable)? = nil
    )

    /// A navigation stack node with a root and an array of pushed destinations.
    ///
    /// - Parameters:
    ///   - root: The root destination of the navigation stack.
    ///   - id: A unique identifier for this navigation node.
    ///   - destinations: Additional destinations in the stack.
    ///   - presentation: The style of presentation (e.g., sheet or full screen).
    ///   - tabItem: Optional tab item identifier if used in a tab view.
    case stack(
        root: any Hashable,
        id: UUID = .init(),
        destinations: [any Hashable] = [],
        presentation: NavigatorPresentation = .sheet,
        tabItem: (any Hashable)? = nil
    )

    /// A tabbed navigation node containing multiple child navigators.
    ///
    /// This case is marked `indirect` to allow recursive tree structures.
    ///
    /// - Parameters:
    ///   - tabs: The array of child `NavigatorData` representing each tab.
    ///   - id: A unique identifier for this navigation node.
    ///   - presentation: The style of presentation (e.g., sheet or full screen).
    ///   - selectedTab: An optional identifier for the currently selected tab.
    indirect case tab(
        tabs: [NavigatorData] = [],
        id: UUID = .init(),
        presentation: NavigatorPresentation = .sheet,
        selectedTab: (any Hashable)? = nil
    )
}
