//
//  VAPersistentNavigatorReplaceInitialTests.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 8/12/24.
//

import XCTest

@testable import VAPersistentNavigator

class VAPersistentNavigatorReplaceInitialTests: XCTestCase, MainActorIsolated {

    func test_navigator_onReplaceInitialNavigator() {
        let sut = TestNavigator(root: .first)
        let expected = TestNavigator(root: .second)
        var replaced: TestNavigator?
        let expectation = expectation(description: "Replace initial")
        sut.onReplaceInitialNavigator = {
            replaced = $0
            expectation.fulfill()
        }
        sut.onReplaceInitialNavigator?(expected)
        wait(for: [expectation])

        XCTAssertNotNil(sut.onReplaceInitialNavigator)
        XCTAssertEqual(expected, replaced)
    }

    func test_navigator_onReplaceInitialNavigator_parent() {
        let sut = TestNavigator(root: .first)
        let top = TestNavigator(root: .second)
        sut.present(top)
        let expected = TestNavigator(root: .third)
        var replaced: TestNavigator?
        let expectation = expectation(description: "Replace initial")
        top.onReplaceInitialNavigator = {
            replaced = $0
            expectation.fulfill()
        }
        top.onReplaceInitialNavigator?(expected)
        wait(for: [expectation])

        XCTAssertNotNil(sut.onReplaceInitialNavigator)
        XCTAssertEqual(expected, replaced)
    }
}
