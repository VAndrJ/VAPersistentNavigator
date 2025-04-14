//
//  DefaultsNavigatorStorage.swift
//  Example
//
//  Created by VAndrJ on 30.07.2024.
//

import Foundation
import VAPersistentNavigator

final class DefaultsNavigatorStorage: NavigatorStorage {
    private static let key = "com.vandrj.navigator"

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let defaults: UserDefaults
    private let key: String

    init(sceneId: String? = nil, defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.key = Self.key + (sceneId ?? "")
    }

    func store(navigator: Navigator) {
        defaults.set(try? encoder.encode(navigator), forKey: key)
    }

    func getNavigator() -> Navigator? {
        defaults.data(forKey: key).flatMap {
            try? decoder.decode(Navigator.self, from: $0)
        }
    }
}
