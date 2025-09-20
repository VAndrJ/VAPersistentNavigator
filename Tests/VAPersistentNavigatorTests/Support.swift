//
//  Support.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 8/6/24.
//

import Foundation
import Testing

@testable import VAPersistentNavigator

enum MockDestination: Codable, Hashable, PersistentDestination {
    case empty
    case first
    case second
    case third
    case fourth
}

enum IncorrectDestination: Codable, Hashable, PersistentDestination {
    case empty
}

enum MockTabTag: Codable, Hashable, PersistentTabItemTag {
    case first
    case second
}

enum SheetTag: Codable, Hashable, PersistentSheetTag {
    case first
    case second
}

extension Array {

    func removingSubrange(from index: Int) -> Array {
        var mutableArray = self
        mutableArray.removeSubrange(index..<count)

        return mutableArray
    }
}

class MockNavigatorStorage: NavigatorStorage {
    typealias Destination = MockDestination
    typealias TabItemTag = MockTabTag
    typealias SheetItemTag = SheetTag

    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    var navigator: Data?

    func store(navigator: PersistentViewNavigator<Destination, TabItemTag, SheetItemTag>) {
        self.navigator = try! encoder.encode(navigator)
    }

    func getNavigator() -> PersistentViewNavigator<Destination, TabItemTag, SheetItemTag>? {
        navigator.flatMap { try! decoder.decode(PersistentViewNavigator<Destination, TabItemTag, SheetItemTag>.self, from: $0) }
    }
}

extension Hashable {
    var anyHashable: AnyHashable { self }
}
