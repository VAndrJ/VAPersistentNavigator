//
//  NavigatorPresentationStrategy.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 4/3/25.
//

/// Defines strategies for presenting a new navigator in the app.
public enum NavigatorPresentationStrategy {
    /// Presents a new navigator from the top-most available navigator.
    case onTop
    /// Replaces the currently presented navigator with a new one.
    case replaceCurrent
    /// Presents a new navigator from the current navigator.
    case fromCurrent
}
