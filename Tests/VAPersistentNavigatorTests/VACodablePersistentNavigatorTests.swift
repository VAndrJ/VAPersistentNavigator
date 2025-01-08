//
//  VACodablePersistentNavigatorTests.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 1/7/25.
//

import Foundation
import Testing
@testable import VAPersistentNavigator

@Suite("Codable Navigator push and pop")
@MainActor
struct CodablePersistentNavigatorStack {

    @Test("Destination should be appended after push")
    func navigator_push_destinationsArray() {
        let expectedDestination: MockDestination = .second
        let sut = TestNavigator(root: .first)
        let navigator: any PersistentNavigator = sut
        navigator.push(expectedDestination)

        #expect([expectedDestination] == sut.destinationsSubj.value)
    }

    @Test("Destination should be substracted after pop")
    func navigator_pop_destinationsArray() {
        let initialDestinations: [MockDestination] = [.second, .third, .fourth]
        let expectedDestinations = Array(initialDestinations.dropLast())
        let sut = TestNavigator(root: .first, destinations: initialDestinations)
        let navigator: any PersistentNavigator = sut
        navigator.pop()

        #expect(expectedDestinations == sut.destinationsSubj.value)
    }

    @Test("Destination should be empty after pop to root")
    func navigator_popToRoot_destinationsArray() {
        let initialDestinations: [MockDestination] = [.second, .third, .fourth]
        let sut = TestNavigator(root: .first, destinations: initialDestinations)
        let navigator: any PersistentNavigator = sut
        navigator.popToRoot()

        #expect(sut.destinationsSubj.value.isEmpty)
    }

    @Test("Destinations should be substracted to first specified")
    func navigator_popToDestinationFirst_destinationsArray() {
        let expectedDestination: MockDestination = .second
        let initialDestinations: [MockDestination] = [expectedDestination, .third, .fourth, expectedDestination, .third]
        let expectedIndex = initialDestinations.firstIndex(of: expectedDestination)! + 1
        let expectedDestinations = initialDestinations.removingSubrange(from: expectedIndex)
        let sut = TestNavigator(root: .first, destinations: initialDestinations)
        let navigator: any PersistentNavigator = sut
        let result = navigator.pop(to: expectedDestination)

        #expect(true == result)
        #expect(expectedDestinations == sut.destinationsSubj.value)
    }

    @Test("Destinations should be substracted to last specified")
    func navigator_popToDestinationLast_destinationsArray() {
        let expectedDestination: MockDestination = .second
        let initialDestinations: [MockDestination] = [expectedDestination, .third, .fourth, expectedDestination, .third]
        let expectedIndex = initialDestinations.lastIndex(of: expectedDestination)! + 1
        let expectedDestinations = initialDestinations.removingSubrange(from: expectedIndex)
        let sut = TestNavigator(root: .first, destinations: initialDestinations)
        let navigator: any PersistentNavigator = sut
        let result = navigator.pop(to: expectedDestination, isFirst: false)

        #expect(true == result)
        #expect(expectedDestinations == sut.destinationsSubj.value)
    }

    @Test("Destinations should be unchanged")
    func navigator_popToDestination_notExisting_destinationsArray() {
        let expectedDestination: MockDestination = .second
        let expectedDestinations: [MockDestination] = [.third, .fourth, .third]
        let sut = TestNavigator(root: .first, destinations: expectedDestinations)
        let navigator: any PersistentNavigator = sut
        let result = navigator.pop(to: expectedDestination, isFirst: false)

        #expect(false == result)
        #expect(expectedDestinations == sut.destinationsSubj.value)
    }

    @Test("Replace root view")
    func navigator_replaceRoot() {
        let expectedRoot: MockDestination = .fourth
        let expectedDestinations: [MockDestination] = [.second, .third]
        let sut = TestNavigator(root: .first, destinations: expectedDestinations)
        let navigator: any PersistentNavigator = sut
        navigator.replace(root: expectedRoot)

        #expect(expectedRoot == sut.root)
        #expect(sut.destinationsSubj.value.isEmpty)
    }

    @Test("Replace root view without pop")
    func navigator_replaceRoot_withoutPopToRoot() {
        let expectedRoot: MockDestination = .fourth
        let expectedDestinations: [MockDestination] = [.second, .third]
        let sut = TestNavigator(root: .first, destinations: expectedDestinations)
        let navigator: any PersistentNavigator = sut
        navigator.replace(root: expectedRoot, isPopToRoot: false)

        #expect(expectedRoot == sut.root)
        #expect(expectedDestinations == sut.destinationsSubj.value)
    }
}

@Suite("Codable Navigator presentation")
@MainActor
struct CodablePersistentNavigatorPresentationTests {

    @Test("Present sheet")
    func navigator_present() {
        let sut = TestNavigator(root: .first)
        let expectedDestination: MockDestination = .second
        let navigator: any PersistentNavigator = sut
        navigator.present(.stack(root: expectedDestination))

        #expect(expectedDestination == sut.childSubj.value?.root)
    }

    @Test("Dismiss top presented sheet")
    func navigator_dismiss_topSheet() {
        let sut = TestNavigator(root: .first)
        let expectedDestination: MockDestination = .second
        let navigator: any PersistentNavigator = sut
        navigator.present(.stack(root: expectedDestination))
        sut.childSubj.value?.dismissTop()

        #expect(nil == sut.childSubj.value)
    }

    @Test("Dismiss to specified Destination")
    func navigator_dismiss_toDestination() {
        let expectedDestination: MockDestination = .first
        let sut = TestNavigator(root: expectedDestination)
        let navigator: any PersistentNavigator = sut
        navigator.present(.stack(root: MockDestination.second))
        let presentedNavigator: (any PersistentNavigator)? = sut.childSubj.value
        let result = presentedNavigator?.dismiss(to: expectedDestination)

        #expect(true == result)
        #expect(nil == sut.childSubj.value)
    }

    @Test("Dismiss top specified Destination failure")
    func navigator_dismiss_toDestinationFailure() {
        let expectedDestination: MockDestination = .first
        let sut = TestNavigator(root: expectedDestination)
        let navigator: any PersistentNavigator = sut
        navigator.present(.stack(root: MockDestination.second))
        let result = sut.childSubj.value?.dismiss(to: MockDestination.fourth)

        #expect(false == result)
        #expect(nil != sut.childSubj.value)
    }

    @Test("Presented destinations pop")
    func navigator_popToDestination_notExisting_destinationsArray() {
        let expectedDestination: MockDestination = .second
        let expectedDestinations: [MockDestination] = [.third, .fourth]
        let sut = TestNavigator(root: .first, destinations: expectedDestinations)
        let navigator: any PersistentNavigator = sut
        navigator.present(.stack(root: MockDestination.second, destinations: expectedDestinations + CollectionOfOne(.third)))
        sut.childSubj.value?.pop()

        #expect(expectedDestinations == sut.childSubj.value?.destinationsSubj.value)
    }

    @Test("Present tabs")
    func navigator_closeToInitial_tab() {
        let sut = TestNavigator(root: .first)
        let navigarot: any PersistentNavigator = sut
        navigarot.present(.tab(
            tabs: [
                .stack(
                    root: MockDestination.first,
                    destinations: [MockDestination.second, MockDestination.third],
                    tabItem: MockTabTag.first
                ),
                .view(
                    MockDestination.second,
                    tabItem: MockTabTag.second
                ),
            ],
            selectedTab: MockTabTag.second
        ))

        #expect(.tabView == sut.childSubj.value?.kind)
        #expect(MockTabTag.second == sut.childSubj.value?.selectedTabSubj.value)
    }
}
