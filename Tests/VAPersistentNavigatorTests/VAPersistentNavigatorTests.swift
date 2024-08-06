import Foundation
import Testing
@testable import VAPersistentNavigator

@Suite("Navigator initial")
struct NavigatorInitial {

    @Test("Initial state")
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
}

@Suite("Navigator push and pop")
struct NavigatorStack {

    @Test("Destination should be appended after push")
    func navigator_Push_DestinationsArray() {
        let expectedDestination: MockDestination = .second
        let sut = Navigator<MockDestination, MockTabTag>(root: .first)
        sut.push(destination: expectedDestination)

        #expect([expectedDestination] == sut.destinationsSubj.value)
    }

    @Test("Destination should be substracted after pop")
    func navigator_Pop_DestinationsArray() {
        let initialDestinations: [MockDestination] = [.second, .third, .fourth]
        let expectedDestinations = Array(initialDestinations.dropLast())
        let sut = Navigator<MockDestination, MockTabTag>(root: .first, destinations: initialDestinations)
        sut.pop()

        #expect(expectedDestinations == sut.destinationsSubj.value)
    }

    @Test("Destination should be empty after pop to root")
    func navigator_PopToRoot_DestinationsArray() {
        let initialDestinations: [MockDestination] = [.second, .third, .fourth]
        let sut = Navigator<MockDestination, MockTabTag>(root: .first, destinations: initialDestinations)
        sut.popToRoot()

        #expect(sut.destinationsSubj.value.isEmpty)
    }

    @Test("Destinations should be substracted to first specified")
    func navigator_PopToDestinationFirst_DestinationsArray() {
        let expectedDestination: MockDestination = .second
        let initialDestinations: [MockDestination] = [expectedDestination, .third, .fourth, expectedDestination, .third]
        let expectedIndex = initialDestinations.firstIndex(of: expectedDestination)! + 1
        let expectedDestinations = initialDestinations.removingSubrange(from: expectedIndex)
        let sut = Navigator<MockDestination, MockTabTag>(root: .first, destinations: initialDestinations)
        sut.pop(to: expectedDestination)

        #expect(expectedDestinations == sut.destinationsSubj.value)
    }

    @Test("Destinations should be substracted to last specified")
    func navigator_PopToDestinationLast_DestinationsArray() {
        let expectedDestination: MockDestination = .second
        let initialDestinations: [MockDestination] = [expectedDestination, .third, .fourth, expectedDestination, .third]
        let expectedIndex = initialDestinations.lastIndex(of: expectedDestination)! + 1
        let expectedDestinations = initialDestinations.removingSubrange(from: expectedIndex)
        let sut = Navigator<MockDestination, MockTabTag>(root: .first, destinations: initialDestinations)
        sut.pop(to: expectedDestination, isFirst: false)

        #expect(expectedDestinations == sut.destinationsSubj.value)
    }

    @Test("Destinations should be unchanged")
    func navigator_PopToDestination_NotExisting_DestinationsArray() {
        let expectedDestination: MockDestination = .second
        let expectedDestinations: [MockDestination] = [.third, .fourth, .third]
        let sut = Navigator<MockDestination, MockTabTag>(root: .first, destinations: expectedDestinations)
        sut.pop(to: expectedDestination, isFirst: false)

        #expect(expectedDestinations == sut.destinationsSubj.value)
    }
}

