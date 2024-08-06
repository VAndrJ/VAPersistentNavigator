import Foundation
import Testing
@testable import VAPersistentNavigator

@Suite("Navigator Tests")
struct NavigatorTests {
    
    @Test("Test Navigator initial state")
    func navigator() {
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

    @Test("Initially set destinations")
    func navigator_InitialDestinations() {
        let expectedDestinations: [MockDestination] = [.second, .third, .fourth]
        let sut = Navigator<MockDestination, MockTabTag>(root: .first, destinations: expectedDestinations)

        #expect(expectedDestinations == sut.destinationsSubj.value)
    }

    @Test("Destination should be appended after push")
    func navigator_Push_DestinationsArray() {
        let expectedDestination: MockDestination = .second
        let sut = Navigator<MockDestination, MockTabTag>(root: .first)
        sut.push(destination: expectedDestination)

        #expect([expectedDestination] == sut.destinationsSubj.value)
    }
}
