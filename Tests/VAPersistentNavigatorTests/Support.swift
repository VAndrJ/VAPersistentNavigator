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

    func store(navigator: CodablePersistentNavigator<Destination, TabItemTag, SheetItemTag>) {
        self.navigator = try! encoder.encode(navigator)
    }
    
    func getNavigator() -> CodablePersistentNavigator<Destination, TabItemTag, SheetItemTag>? {
        navigator.flatMap { try! decoder.decode(CodablePersistentNavigator<Destination, TabItemTag, SheetItemTag>.self, from: $0) }
    }
}

@MainActor
protocol MainActorIsolated {}
