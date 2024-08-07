//
//  Support.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 8/6/24.
//

import Foundation
import Testing
@testable import VAPersistentNavigator

enum MockDestination: Codable, Hashable {
    case empty
    case first
    case second
    case third
    case fourth
}

enum MockTabTag: Codable, Hashable {
    case first
    case second
}

enum SheetTag: Codable, Hashable {
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

    func store(navigator: Navigator<Destination, TabItemTag, SheetItemTag>) {
        self.navigator = try! encoder.encode(navigator)
    }
    
    func getNavigator() -> Navigator<Destination, TabItemTag, SheetItemTag>? {
        navigator.flatMap { try! decoder.decode(Navigator<Destination, TabItemTag, SheetItemTag>.self, from: $0) }
    }
}
