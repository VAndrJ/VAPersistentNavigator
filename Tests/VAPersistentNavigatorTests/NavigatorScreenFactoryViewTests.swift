import SwiftUI
import Testing

@testable import VAPersistentNavigator

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

#if os(iOS) || os(macOS)
@Suite("Navigator screen factory view")
struct NavigatorScreenFactoryViewTests {

    @Test("Tab-root environment actions reach the view hierarchy")
    func tabRootEnvironmentAction_isHandled() async throws {
        let tab = TestNavigator(root: .first, tabItem: .first)
        let navigator = TestNavigator(tabs: [tab], selectedTab: .first)
        let expectedAction = NavigatorScreenFactoryTestAction(value: 42)
        var receivedAction: NavigatorScreenFactoryTestAction?
        let rootView = NavigatorScreenFactoryView(
            navigator: navigator,
            buildView: { _, _ in Color.clear },
            buildTab: { _ in EmptyView() }
        )
        .handle { (action: NavigatorScreenFactoryTestAction) in
            receivedAction = action
        }

        #if os(iOS)
        let hostingController = UIHostingController(rootView: rootView)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        window.rootViewController = hostingController
        window.makeKeyAndVisible()
        #elseif os(macOS)
        let hostingController = NSHostingController(rootView: rootView)
        let window = NSWindow(contentViewController: hostingController)
        window.setContentSize(NSSize(width: 100, height: 100))
        window.setFrameOrigin(NSPoint(x: -10_000, y: -10_000))
        window.orderFront(nil)
        #endif

        try await settleNavigatorScreenFactoryViewUpdates()
        navigator.pass(action: expectedAction)
        try await settleNavigatorScreenFactoryViewUpdates()

        #expect(receivedAction == expectedAction)

        #if os(iOS)
        window.isHidden = true
        window.rootViewController = nil
        #elseif os(macOS)
        window.orderOut(nil)
        window.contentViewController = nil
        #endif
    }

    #if os(iOS)
    @Test("Changing presentation style keeps the replacement navigator")
    func presentationStyleChange_keepsReplacementNavigator() async throws {
        let navigator = TestNavigator(root: .first)
        let rootView = NavigatorPresentationSynchronizationHarness(navigator: navigator)
        let hostingController = UIHostingController(rootView: rootView)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        window.rootViewController = hostingController
        window.makeKeyAndVisible()
        try await settleNavigatorScreenFactoryViewUpdates()

        let sheet = TestNavigator(view: .second, presentation: .sheet)
        navigator.present(sheet, strategy: .fromCurrent)
        try await settleNavigatorScreenFactoryViewUpdates()

        let fullScreenCover = TestNavigator(view: .third, presentation: .fullScreenCover)
        navigator.present(fullScreenCover, strategy: .fromCurrent)
        try await settleNavigatorScreenFactoryViewUpdates()

        #expect(navigator.childSubj.value === fullScreenCover)
        #expect(sheet.parent == nil)
        #expect(fullScreenCover.parent === navigator)

        window.isHidden = true
        window.rootViewController = nil
    }
    #endif
}

private struct NavigatorScreenFactoryTestAction: Equatable {
    let value: Int
}

#if os(iOS)
private struct NavigatorPresentationSynchronizationHarness: View {
    let navigator: TestNavigator
    @State private var isFirstAppearanceOccurred = true
    @State private var isFullScreenCoverPresented = false
    @State private var isSheetPresented = false

    var body: some View {
        Color.clear
            .synchronize(
                $isFullScreenCoverPresented,
                with: navigator.childSubj,
                isFirstAppearanceOccured: $isFirstAppearanceOccurred,
                isFullScreen: true,
                animated: navigator.isAnimatedSubj
            )
            .synchronize(
                $isSheetPresented,
                with: navigator.childSubj,
                isFirstAppearanceOccured: $isFirstAppearanceOccurred,
                isFullScreen: false,
                animated: navigator.isAnimatedSubj
            )
    }
}
#endif

private func settleNavigatorScreenFactoryViewUpdates() async throws {
    await Task.yield()
    try await Task.sleep(for: .milliseconds(100))
}
#endif
