//
//  NavigatorStorage.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 30.07.2024.
//

import Foundation

public protocol NavigatorStorage {
    associatedtype Destination: Codable & Hashable

    func store(navigator: Navigator<Destination>)
    func getNavigator() -> Navigator<Destination>?
}
