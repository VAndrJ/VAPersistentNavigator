//
//  VANavigatorPresentationTests.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 11/13/24.
//

import Foundation
import Testing
@testable import VAPersistentNavigator

@Suite("Presentation Tag Tests")
@MainActor
struct VANavigatorPresentationTests {
    
#if os(iOS) || os(tvOS) || os(watchOS)
    @Test("Full screen cover tag should be nil")
    func fullScreenCoverTag() {
        #expect(NavigatorPresentation<String>.fullScreenCover.sheetTag == nil)
    }
#endif

    @Test("Sheet tag")
    func sheetTag() {
        let expected = "tag"

        #expect(NavigatorPresentation<String>.sheet(tag: expected).sheetTag == expected)
    }

    @Test("Sheet tag wit nil value")
    func sheetTagNil() {
        #expect(NavigatorPresentation<String>.sheet(tag: nil).sheetTag == nil)
    }
}
