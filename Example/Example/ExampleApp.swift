//
//  ExampleApp.swift
//  Example
//
//  Created by VAndrJ on 30.07.2024.
//

import SwiftUI
import VAPersistentNavigator

@main
struct ExampleApp: App {
    let navigatorStorage: DefaultsNavigatorStorage
    @StateObject var viewModel: TestStateNavRestoreAppViewModel

    init() {
        let storage = DefaultsNavigatorStorage()
        self.navigatorStorage = storage
        self._viewModel = .init(wrappedValue: .init(navigator: storage.getNavigator() ?? .init(root: .root)))
    }

    var body: some Scene {
        WindowGroup {
            WindowView(navigatorStorage: navigatorStorage, navigator: viewModel.navigator)
                .id(viewModel.navigator.id)
        }
    }
}

class TestStateNavRestoreAppViewModel: ObservableObject {
    @Published var navigator: Navigator<Destination, TabViewTag, SheetTag>

    init(navigator: Navigator<Destination, TabViewTag, SheetTag>) {
        self._navigator = .init(wrappedValue: navigator)

        bindReplacement()
    }

    func replaceNavigator(_ navigator: Navigator<Destination, TabViewTag, SheetTag>) {
        self.navigator = navigator
        bindReplacement()
    }

    private func bindReplacement() {
        navigator.onReplaceInitialNavigator = { [weak self] in
            self?.replaceNavigator($0)
        }
    }
}

struct WindowView<Storage: NavigatorStorage>: View where Storage.Destination == Destination, Storage.TabItemTag == TabViewTag, Storage.SheetTag == SheetTag {
    let navigatorStorage: Storage
    let navigator: Navigator<Destination, TabViewTag, SheetTag>

    var body: some View {
        NavigatorStoringView(navigator: navigator, storage: navigatorStorage, interval: .seconds(3), scheduler: DispatchQueue.main) {
            NavigatorScreenFactoryView(
                navigator: navigator,
                buildView: { destination, navigator in
                    let _ = { print("navigationDestination:", destination) }()

                    switch destination {
                    case .root:
                        RootView(context: .init(
                            related: .init(isReplacementAvailable: navigator.onReplaceInitialNavigator != nil),
                            navigation: .init(
                                replaceRoot: { navigator.replace(root: .otherRoot) },
                                replaceWindowWithTabView: {
                                    navigator.onReplaceInitialNavigator?(.init(
                                        tabs: [
                                            .init(root: .tab1, tabItem: .first(.first)),
                                            .init(root: .tab2, tabItem: .first(.second)),
                                        ],
                                        selectedTab: .first(.first)
                                    ))
                                },
                                next: { navigator.push(destination: .main) }
                            )
                        ))
                    case .otherRoot:
                        OtherRootView(context: .init(
                            replaceRoot: { navigator.replace(root: .root) },
                            next: { navigator.push(destination: .main) }
                        ))
                    case .root1:
                        Root1View(context: .init(
                            present: { navigator.present(.init(root: .root2, presentation: .sheet(tag: .first))) },
                            dismiss: { navigator.dismissTop() }
                        ))
                    case .root2:
                        Root2View(context: .init(
                            present: { navigator.present(.init(root: .root3)) },
                            dismiss: { navigator.dismissTop() }
                        ))
                    case .root3:
                        Root3View(context: .init(
                            closeToInitial: { navigator.closeToInitial() },
                            dismiss: { navigator.dismissTop() }
                        ))
                    case .tab1:
                        Tab1View(context: .init(next: { navigator.push(destination: .main) }))
                    case .tab2:
                        Tab2View(context: .init(next: { navigator.push(destination: .main) }))
                    case .main:
                        MainView(context: .init(next: { navigator.push(destination: .detail(number: $0)) }))
                    case let .detail(number):
                        DetailView(context: .init(
                            related: .init(
                                number: number,
                                isReplacementAvailable: navigator.onReplaceInitialNavigator != nil,
                                isTabChangeAvailable: navigator.currentTab != nil
                            ),
                            navigation: .init(
                                present: { navigator.present(.init(root: .root1)) },
                                fullScreenCover: { navigator.present(.init(root: .root1, presentation: .fullScreenCover)) },
                                reset: { navigator.onReplaceInitialNavigator?(.init(root: .root)) },
                                presentTabs: {
                                    navigator.present(.init(
                                        tabs: [
                                            .init(root: .tab1, tabItem: .second(.first)),
                                            .init(root: .tab2, tabItem: .second(.second)),
                                        ],
                                        selectedTab: .second(.second)
                                    ))
                                },
                                popToMain: { navigator.pop(to: .main) },
                                changeTabs: {
                                    switch navigator.currentTab {
                                    case let .first(tabView):
                                        switch tabView {
                                        case .first:
                                            navigator.currentTab = .first(.second)
                                        case .second:
                                            navigator.currentTab = .first(.first)
                                        }
                                    case let .second(tabView):
                                        switch tabView {
                                        case .first:
                                            navigator.currentTab = .second(.second)
                                        case .second:
                                            navigator.currentTab = .second(.first)
                                        }
                                    case .none:
                                        break
                                    }
                                }
                            )
                        ))
                    case .empty:
                        EmptyView()
                    }
                },
                buildTab: { tag in
                    switch tag {
                    case let .first(tabView):
                        switch tabView {
                        case .first: Label("Tab 1 1", systemImage: "pencil.circle")
                        case .second: Label("Tab 1 2", systemImage: "square.and.pencil.circle")
                        }
                    case let .second(tabView):
                        switch tabView {
                        case .first: Label("Tab 2 1", systemImage: "pencil.circle")
                        case .second: Label("Tab 2 2", systemImage: "square.and.pencil.circle")
                        }
                    case .none: EmptyView()
                    }
                },
                getDetents: { tag in
                    switch tag {
                    case .first: ([.medium, .large], .visible)
                    case .none: nil
                    }
                }
            )
        }
    }
}

struct RootView: View {
    struct Context {
        struct Related {
            let isReplacementAvailable: Bool
        }

        struct Navigation {
            let replaceRoot: () -> Void
            let replaceWindowWithTabView: () -> Void
            let next: () -> Void
        }

        let related: Related
        let navigation: Navigation
    }

    let context: Context

    var body: some View {
        VStack(spacing: 16) {
            Text("Current: Root")
            Button("Other root", action: context.navigation.replaceRoot)
            Button("Replace wintdow with TabView", action: context.navigation.replaceWindowWithTabView)
                .disabled(!context.related.isReplacementAvailable)
            Button("Next", action: context.navigation.next)
        }
    }
}

struct Tab1View: View {
    struct Context {
        let next: () -> Void
    }

    let context: Context

    var body: some View {
        VStack(spacing: 16) {
            Text("Current: Tab1")
            Button("Next", action: context.next)
        }
        .navigationTitle("Tab 1")
    }
}

struct Tab2View: View {
    struct Context {
        let next: () -> Void
    }

    let context: Context

    var body: some View {
        VStack(spacing: 16) {
            Text("Current: Tab2")
            Button("Next", action: context.next)
        }
        .navigationTitle("Tab 2")
    }
}

struct Root1View: View {
    struct Context {
        let present: () -> Void
        let dismiss: () -> Void
    }

    let context: Context

    var body: some View {
        VStack(spacing: 16) {
            Text("Current: Root1")
            Button("Present", action: context.present)
            Button("Dismiss", action: context.dismiss)
        }
    }
}

struct Root2View: View {
    struct Context {
        let present: () -> Void
        let dismiss: () -> Void
    }

    let context: Context

    var body: some View {
        VStack(spacing: 16) {
            Text("Current: Root2")
            Button("Present", action: context.present)
            Button("Dismiss", action: context.dismiss)
        }
    }
}

struct Root3View: View {
    struct Context {
        let closeToInitial: () -> Void
        let dismiss: () -> Void
    }

    let context: Context

    var body: some View {
        VStack(spacing: 16) {
            Text("Current: Root3")
            Button("Close to initial", action: context.closeToInitial)
            Button("Dismiss", action: context.dismiss)
        }
    }
}

struct OtherRootView: View {
    struct Context {
        let replaceRoot: () -> Void
        let next: () -> Void
    }

    let context: Context

    var body: some View {
        VStack(spacing: 16) {
            Text("Current: Other Root")
            Button("Root", action: context.replaceRoot)
            Button("Next", action: context.next)
        }
    }
}

struct MainView: View {
    struct Context {
        let next: (Int) -> Void
    }

    let context: Context

    var body: some View {
        VStack(spacing: 16) {
            Text("Current: Main")
            Button("Next") { context.next(.random(in: 0...1000)) }
        }
    }
}

struct DetailView: View {
    struct Context {
        struct Related {
            let number: Int
            let isReplacementAvailable: Bool
            let isTabChangeAvailable: Bool
        }

        struct Navigation {
            let present: () -> Void
            let fullScreenCover: () -> Void
            let reset: () -> Void
            let presentTabs: () -> Void
            let popToMain: () -> Void
            let changeTabs: () -> Void
        }

        let related: Related
        let navigation: Navigation
    }

    let context: Context

    var body: some View {
        VStack(spacing: 16) {
            Text("Current: Detail \(context.related.number)")
            Button("Present", action: context.navigation.present)
            Button("Present full screen", action: context.navigation.fullScreenCover)
            Button("Reset navigator to root", action: context.navigation.reset)
                .disabled(!context.related.isReplacementAvailable)
            Button("Present tabs", action: context.navigation.presentTabs)
            Button("Pop to Main", action: context.navigation.popToMain)
            Button("Change tab if available", action: context.navigation.changeTabs)
                .disabled(!context.related.isTabChangeAvailable)
        }
    }
}

#Preview {
    WindowView(
        navigatorStorage: DefaultsNavigatorStorage(),
        navigator: .init(root: .root)
    )
}
