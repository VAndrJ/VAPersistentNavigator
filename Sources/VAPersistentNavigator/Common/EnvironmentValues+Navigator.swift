//
//  EnvironmentValues+Navigator.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 4/3/25.
//

import Combine
import SwiftUI

extension EnvironmentValues {
    /// The current `BaseNavigator` available in the environment.
    ///
    /// This provides access to a generic navigation context, allowing views to interact
    /// with the navigation system (e.g., pushing destinations or accessing navigation state)
    /// without requiring direct injection of a concrete navigator.
    @Entry public var baseNavigator: any BaseNavigator = emptyPersistentNavigator

    /// The current `PersistentNavigator` available in the environment.
    ///
    /// This provides access to a generic navigation context, allowing views to interact
    /// with the navigation system (e.g., pushing destinations or accessing navigation state)
    /// without requiring direct injection of a concrete navigator.
    @Entry public var persistentNavigator: any PersistentNavigator = emptyPersistentNavigator

    static let emptyPersistentNavigator = TypedViewNavigator<EmptyDestination, EmptyTabItemTag, EmptySheetTag>(view: EmptyDestination())

    @Entry var externalAction: ((Any) -> Void)?
}

public enum EnvironmentAction {
    case openURL(URL)
    case openWindow(id: String)
    case dismissWindow(id: String)
    case external(Any)
}

struct EmptyDestination: @MainActor PersistentDestination {}
