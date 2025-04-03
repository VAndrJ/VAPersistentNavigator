//
//  NavigatorKind.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 30.07.2024.
//

/// Represents the type of container being used.
public enum NavigatorKind: Codable {
    /// NavigationStack container for single view without any embedding
    case singleView
    /// NavigationStack container for navigator.
    case flow
    /// TabView container for navigator.
    case tabView

    /// Indicates whether the container is a TabView.
    public var isTabView: Bool { self == .tabView }
}
