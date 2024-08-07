import Foundation
import Testing
@testable import VAPersistentNavigator

typealias TestNavigator = Navigator<MockDestination, MockTabTag>

@Suite("Navigator initial")
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
    func navigator_InitialDestinations() {
        let expectedDestinations: [MockDestination] = [.second, .third, .fourth]
        let sut = TestNavigator(root: .first, destinations: expectedDestinations)

        #expect(expectedDestinations == sut.destinationsSubj.value)
    }
}

@Suite("Navigator push and pop")
struct NavigatorStack {

    @Test("Destination should be appended after push")
    func navigator_Push_DestinationsArray() {
        let expectedDestination: MockDestination = .second
        let sut = TestNavigator(root: .first)
        sut.push(destination: expectedDestination)

        #expect([expectedDestination] == sut.destinationsSubj.value)
    }

    @Test("Destination should be substracted after pop")
    func navigator_Pop_DestinationsArray() {
        let initialDestinations: [MockDestination] = [.second, .third, .fourth]
        let expectedDestinations = Array(initialDestinations.dropLast())
        let sut = TestNavigator(root: .first, destinations: initialDestinations)
        sut.pop()

        #expect(expectedDestinations == sut.destinationsSubj.value)
    }

    @Test("Destination should be empty after pop to root")
    func navigator_PopToRoot_DestinationsArray() {
        let initialDestinations: [MockDestination] = [.second, .third, .fourth]
        let sut = TestNavigator(root: .first, destinations: initialDestinations)
        sut.popToRoot()

        #expect(sut.destinationsSubj.value.isEmpty)
    }

    @Test("Destinations should be substracted to first specified")
    func navigator_PopToDestinationFirst_DestinationsArray() {
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
    func navigator_PopToDestinationLast_DestinationsArray() {
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
    func navigator_PopToDestination_NotExisting_DestinationsArray() {
        let expectedDestination: MockDestination = .second
        let expectedDestinations: [MockDestination] = [.third, .fourth, .third]
        let sut = TestNavigator(root: .first, destinations: expectedDestinations)
        let result = sut.pop(to: expectedDestination, isFirst: false)

        #expect(false == result)
        #expect(expectedDestinations == sut.destinationsSubj.value)
    }

    @Test("Replace root view")
    func navigator_ReplaceRoot() {
        let expectedRoot: MockDestination = .fourth
        let expectedDestinations: [MockDestination] = [.second, .third]
        let sut = TestNavigator(root: .first, destinations: expectedDestinations)
        sut.replace(root: expectedRoot)

        #expect(expectedRoot == sut.root)
        #expect(sut.destinationsSubj.value.isEmpty)
    }

    @Test("Replace root view without pop")
    func navigator_ReplaceRoot_WithoutPopToRoot() {
        let expectedRoot: MockDestination = .fourth
        let expectedDestinations: [MockDestination] = [.second, .third]
        let sut = TestNavigator(root: .first, destinations: expectedDestinations)
        sut.replace(root: expectedRoot, isPopToRoot: false)

        #expect(expectedRoot == sut.root)
        #expect(expectedDestinations == sut.destinationsSubj.value)
    }
}

@Suite("Navigator tabs")
struct NavigatorTabs {

    @Test("Tab item")
    func navigator_TabItem() {
        let expectedTag: MockTabTag = .second
        let sut = TestNavigator(root: .first, tabItem: expectedTag)

        #expect(expectedTag == sut.tabItem)
    }

    @Test("Tab view kind")
    func navigator_TabView() {
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
    func navigator_TabView_Selection() {
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
struct NavigatorPresentation {

    @Test("Present sheet")
    func navigator_Present() {
        let sut = TestNavigator(root: .first)
        let expected = TestNavigator(root: .second)
        sut.present(expected)

        #expect(expected == sut.childSubj.value)
    }

    @Test("Dismiss top presented sheet")
    func navigator_Dismiss_TopSheet() {
        let sut = TestNavigator(root: .first)
        let expected = TestNavigator(root: .second)
        sut.present(expected)
        expected.dismissTop()

        #expect(nil == sut.childSubj.value)
    }

    @Test("Dismiss top specified Destination")
    func navigator_Dismiss_ToDestination() {
        let expectedDestination: MockDestination = .first
        let sut = TestNavigator(root: expectedDestination)
        let expected = TestNavigator(root: .second)
        let top = TestNavigator(root: .third)
        sut.present(expected)
        expected.present(top)
        let result = top.dismiss(to: expectedDestination)

        #expect(result == true)
        #expect(nil == sut.childSubj.value)
    }

    @Test("Dismiss top specified Destination failure")
    func navigator_Dismiss_ToDestinationFailure() {
        let sut = TestNavigator(root: .first)
        let expected = TestNavigator(root: .second)
        let top = TestNavigator(root: .third)
        sut.present(expected)
        expected.present(top)
        let result = top.dismiss(to: .fourth)

        #expect(result == false)
        #expect(nil != sut.childSubj.value)
    }

    @Test("Dismiss top specified id")
    func navigator_Dismiss_ToId() {
        let expectedDestination: MockDestination = .first
        let sut = TestNavigator(root: expectedDestination)
        let id = sut.id
        let expected = TestNavigator(root: .second)
        let top = TestNavigator(root: .third)
        sut.present(expected)
        expected.present(top)
        let result = top.dismiss(to: id)

        #expect(result == true)
        #expect(nil == sut.childSubj.value)
    }

    @Test("Dismiss top specified id failure")
    func navigator_Dismiss_ToIdFailure() {
        let sut = TestNavigator(root: .first)
        let expected = TestNavigator(root: .second)
        let top = TestNavigator(root: .third)
        sut.present(expected)
        expected.present(top)
        let result = top.dismiss(to: UUID())

        #expect(result == false)
        #expect(nil != sut.childSubj.value)
    }

    @Test("Close to initial tab")
    func navigator_CloseToInitial_Tab() {
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
    }
}
