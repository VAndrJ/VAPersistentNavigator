//
//  ExampleApp.swift
//  Example
//
//  Created by VAndrJ on 30.07.2024.
//

import SwiftUI

@main
struct ExampleApp: App {
    @UIApplicationDelegateAdaptor(CustomAppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            WindowReaderView { window in
                GroupView(sceneId: window.windowScene?.session.persistentIdentifier)
            }
        }
        WindowGroup("Auxiliary", id: .auxiliaryWindowId) {
            Text("Auxiliary")
        }
    }
}

struct GroupView: View {
    @StateObject private var viewModel: TestStateNavRestoreAppViewModel
    private let shortcutService = ShortcutService.shared
    private let notificationService = NotificationService.shared

    init(sceneId: String?) {
        self._viewModel = .init(wrappedValue: .init(navigatorStorage: DefaultsNavigatorStorage(sceneId: sceneId)))
    }

    var body: some View {
        ZStack {
            WindowView(navigatorStorage: viewModel.navigatorStorage, navigator: viewModel.navigator)
                .transition(.slide.combined(with: .opacity).combined(with: .scale))
                .id(viewModel.navigator.id)
        }
        .animation(.easeInOut, value: viewModel.navigator.id)
        .onReceive(shortcutService.shortcutPubl) {
            viewModel.handle(shortcut: $0)
        }
        .onReceive(notificationService.notificationPubl) {
            viewModel.handle(notification: $0)
        }
    }
}

@MainActor
final class TestStateNavRestoreAppViewModel: ObservableObject {
    let navigatorStorage: DefaultsNavigatorStorage
    @Published var navigator: Navigator

    init(navigatorStorage: DefaultsNavigatorStorage) {
        self.navigatorStorage = navigatorStorage
        self._navigator = .init(wrappedValue: navigatorStorage.getNavigator() ?? .init(root: .main))

        bindReplacement()
    }

    func replaceNavigator(_ navigator: Navigator) {
        self.navigator = navigator
        bindReplacement()
    }

    func handle(notification: Notification) {
        navigator.present(.init(view: .notificationExample(
            title: notification.title,
            body: notification.body
        )))
    }

    func handle(shortcut: ShortcutItemType) {
        switch shortcut {
        case .closeToRoot:
            navigator.closeToInitial()
        case .presentOnTop:
            navigator.present(.init(view: .shortcutExample))
        case .pushOnTop:
            /// If the `.push` is unsuccessful then fallback to the `.present`
            if !navigator.push(destination: .shortcutExample) {
                navigator.present(.init(view: .shortcutExample))
            }
        }
    }

    private func bindReplacement() {
        navigator.onReplaceInitialNavigator = { [weak self] in
            self?.replaceNavigator($0)
        }
    }
}
