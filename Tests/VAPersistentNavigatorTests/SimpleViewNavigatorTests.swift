//
//  SimpleViewNavigatorTests.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 4/3/25.
//

import Testing
import Foundation
@testable import VAPersistentNavigator

@Suite("SimpleViewNavigator creation and functions tests")
@MainActor
struct SimpleViewNavigatorTests {

    @Test("Test navigator creation from data")
    func navigator_getFromData() {
        let expectedDestination: AnyHashable = "1"
        let sut = SimpleViewNavigator(view: "1")

        #expect(expectedDestination == sut.getNavigator(data: .view(expectedDestination))?.root)
        #expect(expectedDestination == sut.getNavigator(data: .stack(root: expectedDestination))?.root)
        #expect(expectedDestination == sut.getNavigator(data: .tab(tabs: [.view(expectedDestination)]))?.tabChild?.root)
    }

    @Test("Test navigator equality")
    func navigator_equality() {
        let expectedId = UUID()

        #expect(SimpleViewNavigator(id: expectedId, view: "1") == SimpleViewNavigator(id: expectedId, root: "1", destinations: ["1"]))
    }
}
