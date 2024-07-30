//
//  NavigatorDestination.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 30.07.2024.
//

import Foundation

open class NavigatorDestination: Codable, Hashable {
    public static func == (lhs: NavigatorDestination, rhs: NavigatorDestination) -> Bool {
        lhs.id == rhs.id
    }

    public var id: UUID

    public init(id: UUID = .init()) {
        self.id = id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
