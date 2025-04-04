import Foundation
import Testing
@testable import VAPersistentNavigator

typealias TestNavigator = PersistentViewNavigator<MockDestination, MockTabTag, SheetTag>

@Suite("Navigator initial")
@MainActor
struct NavigatorInitial {

    @Test("Initial state")
    func navigator() {
        let expectedId = UUID()
        let expectedRoot: MockDestination = .first
        let sut = TestNavigator(id: expectedId, root: expectedRoot)

        #expect(expectedId == sut.id)
        #expect(expectedRoot == sut.root)
        #expect(true == sut.destinationsSubj.value.isEmpty)
        #expect(.flow == sut.kind)
        #expect(.sheet == sut.presentation)
        #expect(nil == sut.tabItem)
        #expect(true == sut.tabs.isEmpty)
        #expect(nil == sut.currentTab)
        #expect(nil == sut.parent)
        #expect(nil == sut.childSubj.value)
        #expect(nil == sut.onReplaceInitialNavigator)
    }

    @Test("Initially set destinations")
    func navigator_initialDestinations() {
        let expectedDestinations: [MockDestination] = [.second, .third, .fourth]
        let sut = TestNavigator(root: .first, destinations: expectedDestinations)

        #expect(expectedDestinations == sut.destinationsSubj.value)
    }
}

@Suite("Navigator push and pop")
@MainActor
struct NavigatorStack {

    @Test("Destination should be appended after push")
    func navigator_push_destinationsArray() {
        let expectedDestination: MockDestination = .second
        let sut = TestNavigator(root: .first)

        #expect(true == sut.push(destination: expectedDestination))
        #expect([expectedDestination] == sut.destinationsSubj.value)
    }

    @Test("Destination should be substracted after pop")
    func navigator_pop_destinationsArray() {
        let initialDestinations: [MockDestination] = [.second, .third, .fourth]
        let expectedDestinations = Array(initialDestinations.dropLast())
        let sut = TestNavigator(root: .first, destinations: initialDestinations)
        sut.pop()

        #expect(expectedDestinations == sut.destinationsSubj.value)
    }

    @Test("Destination should be empty after pop to root")
    func navigator_popToRoot_destinationsArray() {
        let initialDestinations: [MockDestination] = [.second, .third, .fourth]
        let sut = TestNavigator(root: .first, destinations: initialDestinations)
        sut.popToRoot()

        #expect(sut.destinationsSubj.value.isEmpty)
    }

    @Test("Destinations should be substracted to first specified")
    func navigator_popToDestinationFirst_destinationsArray() {
        let expectedDestination: MockDestination = .second
        let initialDestinations: [MockDestination] = [expectedDestination, .third, .fourth, expectedDestination, .third]
        let expectedIndex = initialDestinations.firstIndex(of: expectedDestination)! + 1
        let expectedDestinations = initialDestinations.removingSubrange(from: expectedIndex)
        let sut = TestNavigator(root: .first, destinations: initialDestinations)
        let result = sut.pop(to: expectedDestination)

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
        let result = sut.pop(to: expectedDestination, isFirst: false)

        #expect(true == result)
        #expect(expectedDestinations == sut.destinationsSubj.value)
    }

    @Test("Destinations should be unchanged")
    func navigator_popToDestination_notExisting_destinationsArray() {
        let expectedDestination: MockDestination = .second
        let expectedDestinations: [MockDestination] = [.third, .fourth, .third]
        let sut = TestNavigator(root: .first, destinations: expectedDestinations)
        let result = sut.pop(to: expectedDestination, isFirst: false)

        #expect(false == result)
        #expect(expectedDestinations == sut.destinationsSubj.value)
    }

    @Test("Replace root view")
    func navigator_replaceRoot() {
        let expectedRoot: MockDestination = .fourth
        let expectedDestinations: [MockDestination] = [.second, .third]
        let sut = TestNavigator(root: .first, destinations: expectedDestinations)
        sut.replace(root: expectedRoot)

        #expect(expectedRoot == sut.root)
        #expect(sut.destinationsSubj.value.isEmpty)
    }

    @Test("Replace root view without pop")
    func navigator_replaceRoot_withoutPopToRoot() {
        let expectedRoot: MockDestination = .fourth
        let expectedDestinations: [MockDestination] = [.second, .third]
        let sut = TestNavigator(root: .first, destinations: expectedDestinations)
        sut.replace(root: expectedRoot, isPopToRoot: false)

        #expect(expectedRoot == sut.root)
        #expect(expectedDestinations == sut.destinationsSubj.value)
    }
}

@Suite("Navigator tabs")
@MainActor
struct NavigatorTabs {

    @Test("Tab item")
    func navigator_tabItem() {
        let expectedTag: MockTabTag = .second
        let sut = TestNavigator(root: .first, tabItem: expectedTag)

        #expect(expectedTag == sut.tabItem)
    }

    @Test("Tab view kind")
    func navigator_tabView() {
        let tab1Navigator = TestNavigator(root: .first, tabItem: .first)
        let tab2Navigator = TestNavigator(root: .first, tabItem: .second)
        let expecgedTab = MockTabTag.second
        let sut = TestNavigator(
            tabs: [tab1Navigator, tab2Navigator],
            selectedTab: expecgedTab
        )

        #expect(.tabView == sut.kind)
        #expect([tab1Navigator, tab2Navigator] == sut.tabs)
        #expect(expecgedTab == sut.currentTab)
        #expect(expecgedTab == tab1Navigator.currentTab)
        #expect(expecgedTab == tab2Navigator.currentTab)
    }

    @Test("Tab view tab selection")
    func navigator_tabView_selection() {
        let tab1Navigator = TestNavigator(root: .first, tabItem: .first)
        let tab2Navigator = TestNavigator(root: .first, tabItem: .second)
        let initialTab = MockTabTag.first
        let expecgedTab = MockTabTag.second
        let sut = TestNavigator(
            tabs: [tab1Navigator, tab2Navigator],
            selectedTab: initialTab
        )

        #expect(initialTab == sut.currentTab)

        sut.currentTab = expecgedTab

        #expect(expecgedTab == sut.currentTab)

        tab1Navigator.currentTab = initialTab

        #expect(initialTab == sut.currentTab)

        tab2Navigator.currentTab = expecgedTab

        #expect(expecgedTab == sut.currentTab)
    }
}

@Suite("Navigator presentation")
@MainActor
struct NavigatorPresentationTests {

    @Test("Present sheet")
    func navigator_present() {
        let sut = TestNavigator(root: .first)
        let expected = TestNavigator(root: .second)
        sut.present(expected)

        #expect(expected == sut.childSubj.value)
    }

    @Test("Dismiss top presented sheet")
    func navigator_dismiss_topSheet() {
        let sut = TestNavigator(root: .first)
        let expected = TestNavigator(root: .second)
        sut.present(expected)
        expected.dismissTop()

        #expect(nil == sut.childSubj.value)
    }

    @Test("Dismiss to specified Destination")
    func navigator_dismiss_toDestination() {
        let expectedDestination: MockDestination = .first
        let sut = TestNavigator(root: expectedDestination)
        let expected = TestNavigator(root: .second)
        let top = TestNavigator(root: .third)
        sut.present(expected)
        expected.present(top)
        let result = top.dismiss(to: expectedDestination)

        #expect(true == result)
        #expect(nil == sut.childSubj.value)
    }

    @Test("Dismiss top specified Destination failure")
    func navigator_dismiss_toDestinationFailure() {
        let sut = TestNavigator(root: .first)
        let expected = TestNavigator(root: .second)
        let top = TestNavigator(root: .third)
        sut.present(expected)
        expected.present(top)
        let result = top.dismiss(target: .fourth)

        #expect(false == result)
        #expect(nil != sut.childSubj.value)
    }

    @Test("Dismiss top specified id")
    func navigator_dismiss_toId() {
        let expectedDestination: MockDestination = .first
        let sut = TestNavigator(root: expectedDestination)
        let id = sut.id
        let expected = TestNavigator(root: .second)
        let top = TestNavigator(root: .third)
        sut.present(expected)
        expected.present(top)
        let result = top.dismissTo(id: id)

        #expect(true == result)
        #expect(nil == sut.childSubj.value)
    }

    @Test("Dismiss top specified id failure")
    func navigator_dismiss_toIdFailure() {
        let sut = TestNavigator(root: .first)
        let expected = TestNavigator(root: .second)
        let top = TestNavigator(root: .third)
        sut.present(expected)
        expected.present(top)
        let result = top.dismissTo(id: UUID())

        #expect(false == result)
        #expect(nil != sut.childSubj.value)
    }

    @Test("Close to initial")
    func navigator_closeToInitial() {
        let sut = TestNavigator(root: .first, destinations: [.third, .fourth])
        let presented = TestNavigator(root: .second)
        let top = TestNavigator(root: .third)
        sut.present(presented)
        presented.present(top)
        top.closeToInitial()

        #expect(nil == sut.childSubj.value)
        #expect(true == sut.destinationsSubj.value.isEmpty)
    }

    @Test("Close to initial tab")
    func navigator_closeToInitial_tab() {
        let tab1 = TestNavigator(root: .first, destinations: [.third, .fourth], tabItem: .first)
        let tab2 = TestNavigator(root: .second, tabItem: .second)
        let sut = TestNavigator(tabs: [tab1, tab2])
        let presented = TestNavigator(root: .second)
        let top = TestNavigator(root: .third)
        tab1.present(presented)
        presented.present(top)
        top.closeToInitial()

        #expect(nil == tab1.childSubj.value)
        #expect(true == tab1.destinationsSubj.value.isEmpty)
        #expect([tab1, tab2] == sut.tabs)
    }

    @Test("Close to initial single view")
    func navigator_closeToInitial_singleView() {
        let sut = TestNavigator(view: .first)
        let presented = TestNavigator(root: .second)
        let top = TestNavigator(root: .third)
        sut.present(presented)
        presented.present(top)
        top.closeToInitial()

        #expect(nil == sut.childSubj.value)
    }
}

@Suite("Navigator storing")
@MainActor
struct NavigatorStoring {

    @Test("Close to initial tab")
    func navigator_storingAndDeociding() {
        let storage = MockNavigatorStorage()
        let sut = TestNavigator(root: .first)
        storage.store(navigator: sut)
        let navigator = storage.getNavigator()
        
        #expect(navigator == sut)
    }
}
