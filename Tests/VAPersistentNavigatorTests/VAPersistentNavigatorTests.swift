import Foundation
import Testing
@testable import VAPersistentNavigator

@Suite("Navigator Tests")
struct NavigatorTests {
    
    @Test func navigator() {
        let expectedId = UUID()
        let expectedRoot: MockDestination = .first
        let sut = Navigator<MockDestination, MockTabTag>(id: expectedId, root: expectedRoot)

        #expect(expectedId == sut.id)
        #expect(expectedRoot == sut.root)
        #expect(sut.destinationsSubj.value.isEmpty)
        #expect(.flow == sut.kind)
        #expect(.sheet == sut.presentation)
        #expect(nil == sut.tabItem)
        #expect(sut.tabs.isEmpty)
        #expect(nil == sut.currentTab)
        #expect(nil == sut.parent)
        #expect(nil == sut.childSubj.value)
        #expect(nil == sut.onReplaceInitialNavigator)
    }
}
