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
}

private struct NavigatorScreenFactoryTestAction: Equatable {
    let value: Int
}

private func settleNavigatorScreenFactoryViewUpdates() async throws {
    await Task.yield()
    try await Task.sleep(for: .milliseconds(100))
}
#endif
