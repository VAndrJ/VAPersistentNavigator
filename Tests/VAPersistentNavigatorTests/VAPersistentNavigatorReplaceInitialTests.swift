//
//  VAPersistentNavigatorReplaceInitialTests.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 8/12/24.
//

import Foundation
import Testing

@testable import VAPersistentNavigator

@Suite("Codable Navigator push and pop")
struct VAPersistentNavigatorReplaceInitialTests {

    @Test
    func test_navigator_onReplaceInitialNavigator() async {
        let sut = TestNavigator(root: .first)
        let expected = TestNavigator(root: .second)
        var replaced: TestNavigator?
        sut.onReplaceInitialNavigator = {
            replaced = $0
        }
        sut.onReplaceInitialNavigator?(expected)
        try? await Task.sleep(for: .seconds(1))

        #expect(sut.onReplaceInitialNavigator != nil)
        #expect(expected == replaced)
    }

    func test_navigator_onReplaceInitialNavigator_parent() async {
        let sut = TestNavigator(root: .first)
        let top = TestNavigator(root: .second)
        sut.present(top)
        let expected = TestNavigator(root: .third)
        var replaced: TestNavigator?
        top.onReplaceInitialNavigator = {
            replaced = $0
        }
        top.onReplaceInitialNavigator?(expected)
        try? await Task.sleep(for: .seconds(1))

        #expect(sut.onReplaceInitialNavigator != nil)
        #expect(expected == replaced)
    }
}
