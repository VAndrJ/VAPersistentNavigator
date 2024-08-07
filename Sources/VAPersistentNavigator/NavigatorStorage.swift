//
//  NavigatorStorage.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 30.07.2024.
//

import Foundation

/// A protocol defining the storage mechanism for a navigator.
public protocol NavigatorStorage {
    associatedtype Destination: Codable & Hashable
    associatedtype TabItemTag: Codable & Hashable

    /// Stores the given navigator.
    ///
    /// - Parameter navigator: The `Navigator` to be stored.
    func store(navigator: Navigator<Destination, TabItemTag>)
    /// Retrieves the stored navigator.
    ///
    /// - Returns: The stored `Navigator`, or `nil` if no `Navigator` is stored.
    func getNavigator() -> Navigator<Destination, TabItemTag>?
}
