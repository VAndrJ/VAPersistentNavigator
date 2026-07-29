import Foundation
import SwiftUI
import Testing

@testable import VAPersistentNavigator

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

#if os(iOS) || os(macOS)
@Suite("Navigator storing view lifecycle")
struct NavigatorStoringViewLifecycleTests {

    @Test("Disappearance flushes state before the debounce interval")
    func navigatorStoringView_disappearanceFlushesPendingState() async throws {
        let navigator = TestNavigator(root: .first)
        let storage = MockNavigatorStorage()
        let visibility = NavigatorStoringViewVisibility()
        let rootView = NavigatorStoringViewLifecycleHarness(
            visibility: visibility,
            navigator: navigator,
            storage: storage
        )

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

        try await settleSwiftUIUpdates()
        #expect(storage.storeCount == 0)

        navigator.push(destination: .second)
        visibility.isVisible = false

        try await settleSwiftUIUpdates()
        #expect(storage.storeCount == 1)
        #expect(storage.getNavigator()?.destinationsSubj.value == [.second])

        #if os(iOS)
        window.isHidden = true
        window.rootViewController = nil
        #elseif os(macOS)
        window.orderOut(nil)
        window.contentViewController = nil
        #endif
    }
}

private final class NavigatorStoringViewVisibility: ObservableObject {
    @Published var isVisible = true
}

private struct NavigatorStoringViewLifecycleHarness: View {
    @ObservedObject var visibility: NavigatorStoringViewVisibility
    let navigator: TestNavigator
    let storage: MockNavigatorStorage

    var body: some View {
        if visibility.isVisible {
            NavigatorStoringView(
                navigator: navigator,
                storage: storage,
                delay: .seconds(60)
            ) {
                Color.clear
                    .frame(width: 1, height: 1)
            }
        }
    }
}

private func settleSwiftUIUpdates() async throws {
    await Task.yield()
    try await Task.sleep(for: .milliseconds(100))
}
#endif
