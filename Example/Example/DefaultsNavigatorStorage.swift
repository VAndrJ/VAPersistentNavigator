//
//  DefaultsNavigatorStorage.swift
//  Example
//
//  Created by VAndrJ on 30.07.2024.
//

import Foundation
import VAPersistentNavigator

final class DefaultsNavigatorStorage: NavigatorStorage {
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let key = "com.vandrj.navigator"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func store(navigator: Navigator) {
        defaults.set(try? encoder.encode(navigator), forKey: key)
    }

    func getNavigator() -> Navigator? {
        defaults.data(forKey: key).flatMap {
            try? decoder.decode(PersistentViewNavigator.self, from: $0)
        }
    }
}
