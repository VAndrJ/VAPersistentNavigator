//
//  NavigatorStorage.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 30.07.2024.
//

import Foundation

/// A protocol defining the storage mechanism for a navigator.
public protocol NavigatorStorage {
    associatedtype Destination: PersistentDestination
    associatedtype TabItemTag: PersistentTabItemTag
    associatedtype SheetTag: PersistentSheetTag

    /// Stores the given navigator.
    ///
    /// - Parameter navigator: The `Navigator` to be stored.
    func store(navigator: CodablePersistentNavigator<Destination, TabItemTag, SheetTag>)
    /// Retrieves the stored navigator.
    ///
    /// - Returns: The stored `PersistentNavigator`, or `nil` if no `Navigator` is stored.
    func getNavigator() -> CodablePersistentNavigator<Destination, TabItemTag, SheetTag>?
}
