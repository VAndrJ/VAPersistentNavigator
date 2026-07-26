//
//  Support.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 8/6/24.
//

import Foundation
import Testing

@testable import VAPersistentNavigator

enum MockDestination: @MainActor PersistentDestination {
    case empty
    case first
    case second
    case third
    case fourth
}

enum IncorrectDestination: @MainActor PersistentDestination {
    case empty
}

enum MockTabTag: @MainActor PersistentTabItemTag {
    case first
    case second
}

enum SheetTag: @MainActor PersistentSheetTag {
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

class MockNavigatorStorage: @MainActor NavigatorStorage {
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
