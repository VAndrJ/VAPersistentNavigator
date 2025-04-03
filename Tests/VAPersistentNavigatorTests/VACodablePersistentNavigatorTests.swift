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

        #expect(true == navigator.push(expectedDestination))
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

        #expect(true == navigator.pop(to: expectedDestination))
        #expect(expectedDestinations == sut.destinationsSubj.value)

        let incorrectDestination: IncorrectDestination = .empty

        #expect(false == navigator.pop(to: incorrectDestination))
        #expect(false == navigator.pop(to: incorrectDestination as any Hashable))
    }

    @Test("Destinations should be substracted to last specified")
    func navigator_popToDestinationLast_destinationsArray() {
        let expectedDestination: MockDestination = .second
        let initialDestinations: [MockDestination] = [expectedDestination, .third, .fourth, expectedDestination, .third]
        let expectedIndex = initialDestinations.lastIndex(of: expectedDestination)! + 1
        let expectedDestinations = initialDestinations.removingSubrange(from: expectedIndex)
        let sut = TestNavigator(root: .first, destinations: initialDestinations)
        let navigator: any PersistentNavigator = sut

        #expect(true == navigator.pop(to: expectedDestination as any Hashable, isFirst: false))
        #expect(expectedDestinations == sut.destinationsSubj.value)
    }

    @Test("Destinations should be unchanged")
    func navigator_popToDestination_notExisting_destinationsArray() {
        let expectedDestination: MockDestination = .second
        let expectedDestinations: [MockDestination] = [.third, .fourth, .third]
        let sut = TestNavigator(root: .first, destinations: expectedDestinations)
        let navigator: any PersistentNavigator = sut

        #expect(false == navigator.pop(to: expectedDestination, isFirst: false))
        #expect(expectedDestinations == sut.destinationsSubj.value)
    }

    @Test("Replace root view")
    func navigator_replaceRoot() {
        let expectedRoot: MockDestination = .fourth
        let expectedDestinations: [MockDestination] = [.second, .third]
        let sut = TestNavigator(root: .first, destinations: expectedDestinations)
        let navigator: any PersistentNavigator = sut

        #expect(true == navigator.replace(root: expectedRoot))
        #expect(true == navigator.replace(root: expectedRoot as any Hashable))
        #expect(expectedRoot == sut.root)
        #expect(sut.destinationsSubj.value.isEmpty)

        let incorrectRoot: IncorrectDestination = .empty

        #expect(false == navigator.replace(root: incorrectRoot))
        #expect(false == navigator.replace(root: incorrectRoot as any Hashable))
    }

    @Test("Replace root view without pop")
    func navigator_replaceRoot_withoutPopToRoot() {
        let expectedRoot: MockDestination = .fourth
        let expectedDestinations: [MockDestination] = [.second, .third]
        let sut = TestNavigator(root: .first, destinations: expectedDestinations)
        let navigator: any PersistentNavigator = sut

        #expect(true == navigator.replace(root: expectedRoot, isPopToRoot: false))
        #expect(expectedRoot == sut.root)
        #expect(expectedDestinations == sut.destinationsSubj.value)

        let incorrectRoot: IncorrectDestination = .empty

        #expect(false == navigator.replace(root: incorrectRoot))
        #expect(false == navigator.replace(root: incorrectRoot as any Hashable))
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

        #expect(true == presentedNavigator?.dismiss(to: expectedDestination))
        #expect(nil == sut.childSubj.value)

        navigator.present(.stack(root: MockDestination.second))

        #expect(true == presentedNavigator?.dismiss(to: expectedDestination as any Hashable))

        let incorrectDestination: IncorrectDestination = .empty

        #expect(false == presentedNavigator?.dismiss(to: incorrectDestination))
        #expect(false == presentedNavigator?.dismiss(to: incorrectDestination as any Hashable))
    }

    @Test("Dismiss top specified Destination failure")
    func navigator_dismiss_toDestinationFailure() {
        let expectedDestination: MockDestination = .first
        let sut = TestNavigator(root: expectedDestination)
        let navigator: any PersistentNavigator = sut
        navigator.present(.stack(root: MockDestination.second))

        #expect(false == sut.childSubj.value?.dismiss(to: MockDestination.fourth))
        #expect(nil != sut.childSubj.value)
    }

    @Test("Presented destinations pop")
    func navigator_popToDestination_notExisting_destinationsArray() {
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

@Suite("Codable Navigator top / child navigators")
@MainActor
struct CodablePersistentNavigatorChildrenTests {

    @Test("TabNavigator topmost tab child navigator without selection")
    func navigator_tab_topFirst_noSelected() {
        let firstTab = TestNavigator(root: .first)
        let secondTab = TestNavigator(view: .third)
        let sut = TestNavigator(tabs: [firstTab, secondTab], selectedTab: nil)

        #expect(firstTab == sut.topChild)
        #expect(firstTab == sut.tabChild)
        #expect(firstTab == sut.topNavigator)
    }

    @Test("TabNavigator topmost tab child navigator with selection")
    func navigator_tab_topFirst_preSelected() {
        let selectedTab: MockTabTag = .second
        let firstTab = TestNavigator(root: .first, tabItem: .first)
        let secondTab = TestNavigator(view: .third, tabItem: selectedTab)
        let sut = TestNavigator(tabs: [firstTab, secondTab], selectedTab: selectedTab)

        #expect(secondTab == sut.topChild)
        #expect(secondTab == sut.tabChild)
        #expect(secondTab == sut.topNavigator)
    }

    @Test("Topmost navigator flow push success")
    func navigator_topmost_topMostFlow_pushSuccess() {
        let selectedTab: MockTabTag = .second
        let firstTab = TestNavigator(root: .first, tabItem: .first)
        let secondTab = TestNavigator(view: .third, tabItem: selectedTab)
        let sut = TestNavigator(tabs: [firstTab, secondTab], selectedTab: selectedTab)
        let presentedNavigator = TestNavigator(root: .second)
        sut.present(presentedNavigator)
        
        #expect(presentedNavigator == sut.topNavigator)

        let expectedDestination: MockDestination = .fourth

        #expect(true == sut.push(expectedDestination as any Hashable))
        #expect(expectedDestination == sut.topNavigator.destinationsSubj.value.last)
    }

    @Test("Topmost navigator flow push failure")
    func navigator_topmost_topMostFlow_pushFailure_singleView() {
        let selectedTab: MockTabTag = .second
        let firstTab = TestNavigator(root: .first, tabItem: .first)
        let secondTab = TestNavigator(view: .third, tabItem: selectedTab)
        let sut = TestNavigator(tabs: [firstTab, secondTab], selectedTab: selectedTab)
        let presentedNavigator = TestNavigator(view: .second)
        sut.present(presentedNavigator)

        #expect(presentedNavigator == sut.topNavigator)

        let expectedDestination: MockDestination = .fourth

        #expect(false == sut.push(expectedDestination))

        let inCorrectDestination: IncorrectDestination = .empty

        #expect(false == sut.push(inCorrectDestination))
        #expect(false == sut.push(inCorrectDestination as any Hashable))
    }

    @Test("Topmost navigator flow push failure")
    func navigator_topmost_topMostFlow_pushFailure_tabView() {
        let selectedTab: MockTabTag = .second
        let firstTab = TestNavigator(root: .first, tabItem: .first)
        let secondTab = TestNavigator(view: .third, tabItem: selectedTab)
        let sut = TestNavigator(tabs: [firstTab, secondTab], selectedTab: selectedTab)
        let presentedNavigator = TestNavigator(tabs: [])
        sut.present(presentedNavigator)

        #expect(presentedNavigator == sut.topNavigator)

        let expectedDestination: MockDestination = .fourth

        #expect(false == sut.push(expectedDestination))
    }

    @Test("Replace current presented navigator")
    func navigator_replaceCurrentPresented() async {
        let sut = TestNavigator(view: .first)
        let presentedDestination: MockDestination = .second
        sut.present(.init(view: presentedDestination))

        #expect(presentedDestination == sut.childSubj.value?.root)

        let expectedDestination: MockDestination = .third
        sut.present(.init(view: expectedDestination), strategy: .replaceCurrent)
        try? await Task.sleep(for: .milliseconds(600))

        #expect(expectedDestination == sut.childSubj.value?.root)
    }

    @Test("Pop root view")
    func navigator_popRootView() {
        let expectedDestination: MockDestination = .first
        let sut = TestNavigator(root: expectedDestination)

        #expect(sut.destinationsSubj.value.isEmpty)

        sut.pop()
        sut.popToRoot()

        #expect(sut.destinationsSubj.value.isEmpty)
        #expect(expectedDestination == sut.root)
    }

    @Test("Get navigator from data")
    func navigator_creationFromData() {
        let expectedDestination: MockDestination = .first
        let sut = TestNavigator(root: expectedDestination)

        #expect(expectedDestination == sut.getNavigator(data: .view(expectedDestination))?.root)
        #expect(expectedDestination == sut.getNavigator(data: .stack(root: expectedDestination))?.root)

        let incorrectDestination: IncorrectDestination = .empty

        #expect(nil == sut.getNavigator(data: .view(incorrectDestination)))
        #expect(nil == sut.getNavigator(data: .stack(root: incorrectDestination)))
        #expect(nil == sut.getNavigator(data: .view(expectedDestination, presentation: .sheet(tag: expectedDestination)))?.tabItem)
    }

    @Test("NavigatorPresentation tag")
    func navigatorPresentation_sheetTag() async throws {
        let expectedTag: MockTabTag = .first

        #expect(expectedTag == NavigatorPresentation.sheet(tag: expectedTag).sheetTag as? MockTabTag)
        #expect(nil == NavigatorPresentation.fullScreenCover.sheetTag)
    }
}

@Suite("Codable Navigator close to destination")
@MainActor
struct CodablePersistentNavigatorClose {

    @Test("Close to destination with presented views")
    func navigator_closeToDestination_presentedViews() {
        let expectedDestination: MockDestination = .second
        let sut = TestNavigator(view: .first)
        sut.present(.init(view: expectedDestination))
        sut.present(.init(view: .third))
        sut.present(.init(view: .fourth))

        #expect(.fourth == sut.topNavigator.root)
        #expect(true == sut.close(to: expectedDestination))
        #expect(expectedDestination == sut.topNavigator.root)

        sut.present(.init(view: .third))

        #expect(true == sut.close(to: expectedDestination as any Hashable))
    }

    @Test("Close to destination with presented views failure")
    func navigator_closeToDestination_presentedViewsFailure() {
        let sut = TestNavigator(view: .first)
        sut.present(.init(view: .second))
        sut.present(.init(view: .third))
        sut.present(.init(view: .fourth))

        #expect(.fourth == sut.topNavigator.root)

        let expectedDestination: MockDestination = .empty

        #expect(false == sut.close(to: expectedDestination))
        #expect(.fourth == sut.topNavigator.root)

        let incorrectDestination: IncorrectDestination = .empty

        #expect(false == sut.close(to: incorrectDestination))
        #expect(false == sut.close(to: incorrectDestination as any Hashable))

        let hashableDestination: AnyHashable = 1

        #expect(false == sut.close(where: { $0.anyHashable == hashableDestination }))
    }

    @Test("Close to destination with presented views and stack")
    func navigator_closeToDestination_presentedViewsStack() {
        let expectedDestination: MockDestination = .second
        let sut = TestNavigator(view: .first)
        sut.present(.init(root: expectedDestination, destinations: [.third, .fourth]))
        sut.present(.init(view: .third))
        sut.present(.init(view: .fourth))

        #expect(.fourth == sut.topNavigator.root)

        let closeResult = sut.close(to: expectedDestination)

        #expect(true == closeResult)
        #expect(expectedDestination == sut.topNavigator.root)
    }

    @Test("Close to destination with presented tabs and stack")
    func navigator_closeToDestination_presentedTabs() {
        let expectedDestination: MockDestination = .second
        let sut = TestNavigator(view: .first)
        sut.present(.init(tabs: [
            .init(view: expectedDestination),
            .init(view: .third),
        ]))
        sut.present(.init(view: .fourth))

        #expect(.fourth == sut.topNavigator.root)

        let closeResult = sut.close(to: expectedDestination)

        #expect(true == closeResult)
        #expect(expectedDestination == sut.topNavigator.root)
    }

    @Test("Close to destination with presented views and stack failure")
    func navigator_closeToDestination_presentedViewsStackFailure() {
        let expectedDestination: MockDestination = .empty
        let sut = TestNavigator(view: .first)
        sut.present(.init(root: .second, destinations: [.third, .fourth]))
        sut.present(.init(view: .third))
        sut.present(.init(view: .fourth))

        #expect(.fourth == sut.topNavigator.root)

        let closeResult = sut.close(to: expectedDestination)

        #expect(false == closeResult)
        #expect(.fourth == sut.topNavigator.root)
    }

    @Test("Close to destination with presented views and stack pop")
    func navigator_closeToDestination_presentedViewsStackPop() {
        let expectedDestination: MockDestination = .third
        let sut = TestNavigator(view: .first)
        sut.present(.init(root: .second, destinations: [expectedDestination, .fourth]))
        sut.present(.init(view: .fourth))

        #expect(.fourth == sut.topNavigator.root)

        let closeResult = sut.close(to: expectedDestination)

        #expect(true == closeResult)
        #expect(expectedDestination == sut.topNavigator.destinationsSubj.value.first)
    }

    @Test("Close to destination predicate with presented views")
    func navigator_closeToDestination_predicate_presentedViews() {
        let expectedDestination: MockDestination = .second
        let sut = TestNavigator(view: .first)
        sut.present(.init(view: expectedDestination))
        sut.present(.init(view: .third))
        sut.present(.init(view: .fourth))

        #expect(.fourth == sut.topNavigator.root)

        let closeResult = sut.close {
            expectedDestination == $0 as? MockDestination
        }

        #expect(true == closeResult)
        #expect(expectedDestination == sut.topNavigator.root)
    }

    @Test("Close to destination predicate with presented views failure")
    func navigator_closeToDestination_predicate_presentedViewsFailure() {
        let expectedDestination: MockDestination = .empty
        let sut = TestNavigator(view: .first)
        sut.present(.init(view: .second))
        sut.present(.init(view: .third))
        sut.present(.init(view: .fourth))

        #expect(.fourth == sut.topNavigator.root)
        let closeResult = sut.close {
            expectedDestination == $0 as? MockDestination
        }

        #expect(false == closeResult)
        #expect(.fourth == sut.topNavigator.root)
    }

    @Test("Close to destination predicate with presented views and stack")
    func navigator_closeToDestination_predicate_presentedViewsStack() {
        let expectedDestination: MockDestination = .second
        let sut = TestNavigator(view: .first)
        sut.present(.init(root: expectedDestination, destinations: [.third, .fourth]))
        sut.present(.init(view: .third))
        sut.present(.init(view: .fourth))

        #expect(.fourth == sut.topNavigator.root)

        let closeResult = sut.close {
            expectedDestination == $0 as? MockDestination
        }

        #expect(true == closeResult)
        #expect(expectedDestination == sut.topNavigator.root)
    }

    @Test("Close to destination predicate with presented views and stack failure")
    func navigator_closeToDestination_predicate_presentedViewsStackFailure() {
        let expectedDestination: MockDestination = .empty
        let sut = TestNavigator(view: .first)
        sut.present(.init(root: .second, destinations: [.third, .fourth]))
        sut.present(.init(view: .third))
        sut.present(.init(view: .fourth))

        #expect(.fourth == sut.topNavigator.root)
        
        let closeResult = sut.close {
            expectedDestination == $0 as? MockDestination
        }

        #expect(false == closeResult)
        #expect(.fourth == sut.topNavigator.root)
    }

    @Test("Close to destination predicate with presented views and stack pop")
    func navigator_closeToDestination_predicate_presentedViewsStackPop() {
        let expectedDestination: MockDestination = .third
        let sut = TestNavigator(view: .first)
        sut.present(.init(root: .second, destinations: [expectedDestination, .fourth]))
        sut.present(.init(view: .fourth))

        #expect(.fourth == sut.topNavigator.root)

        let closeResult = sut.close {
            expectedDestination == $0 as? MockDestination
        }

        #expect(true == closeResult)
        #expect(expectedDestination == sut.topNavigator.destinationsSubj.value.first)
    }
}
