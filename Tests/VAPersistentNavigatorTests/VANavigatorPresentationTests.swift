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
struct VANavigatorPresentationTests {

    #if os(iOS) || os(tvOS) || os(watchOS)
    @Test("Full screen cover tag should be nil")
    func fullScreenCoverTag() {
        #expect(TypedNavigatorPresentation<String>.fullScreenCover.sheetTag == nil)
    }
    #endif

    @Test("Sheet tag")
    func sheetTag() {
        let expected = "tag"

        #expect(TypedNavigatorPresentation<String>.sheet(tag: expected).sheetTag == expected)
    }

    @Test("Sheet tag wit nil value")
    func sheetTagNil() {
        #expect(TypedNavigatorPresentation<String>.sheet(tag: nil).sheetTag == nil)
    }

    @Test("NavigatorPresentation mapping")
    func presentationMapping() {
        let persistentPresentationCover: NavigatorPresentation = .fullScreenCover
        let navigatorPresentationCover = TypedNavigatorPresentation<SheetTag>(presentation: persistentPresentationCover)
        #expect(.fullScreenCover == navigatorPresentationCover)
        let persistentPresentationSheet: NavigatorPresentation = .sheet
        let navigatorPresentationSheet = TypedNavigatorPresentation<SheetTag>(presentation: persistentPresentationSheet)
        #expect(.sheet == navigatorPresentationSheet)
        let sheetTag: SheetTag = .first
        let persistentPresentationSheetTag: NavigatorPresentation = .sheet(tag: sheetTag)
        let navigatorPresentationSheetTag = TypedNavigatorPresentation<SheetTag>(presentation: persistentPresentationSheetTag)
        #expect(.sheet(tag: sheetTag) == navigatorPresentationSheetTag)
    }
}
