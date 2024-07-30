//
//  NavigatorStorage.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 30.07.2024.
//

import Foundation

public protocol NavigatorStorage {

    func store(navigator: Navigator)
    func getNavigator() -> Navigator
}
