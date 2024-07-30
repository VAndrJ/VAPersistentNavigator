//
//  Destinations.swift
//  Example
//
//  Created by VAndrJ on 30.07.2024.
//

import Foundation
import VAPersistentNavigator

final class EmptyDestination: NavigatorDestination {}

final class RootDestination: NavigatorDestination {}

final class Root1Destination: NavigatorDestination {}

final class Root2Destination: NavigatorDestination {}

final class Root3Destination: NavigatorDestination {}

final class OtherRootDestination: NavigatorDestination {}

final class Tab1Destination: NavigatorDestination {}

final class Tab2Destination: NavigatorDestination {}

final class MainDestination: NavigatorDestination {}

final class DetailDestination: NavigatorDestination {
    let number: Int

    init(number: Int) {
        self.number = number

        super.init()
    }

    enum CodingKeys: String, CodingKey {
        case id
        case number
    }

    required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.number = try container.decode(Int.self, forKey: .number)

        try super.init(from: decoder)
    }
}
