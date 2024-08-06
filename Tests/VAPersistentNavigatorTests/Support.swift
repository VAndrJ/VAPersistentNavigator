//
//  Support.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 8/6/24.
//

import Testing
@testable import VAPersistentNavigator

enum MockDestination: Codable, Hashable {
    case first
    case second
    case third
    case fourth
}

enum MockTabTag: Codable, Hashable {
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
