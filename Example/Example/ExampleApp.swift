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
        self._viewModel = .init(wrappedValue: .init(navigator: storage.getNavigator()))
    }

    var body: some Scene {
        WindowGroup {
            WindowView(navigatorStorage: navigatorStorage, navigator: viewModel.navigator)
                .id(viewModel.navigator.id)
        }
    }
}

class TestStateNavRestoreAppViewModel: ObservableObject {
    @Published var navigator: Navigator<NavigatorDestination>

    init(navigator: Navigator<NavigatorDestination>) {
        self._navigator = .init(wrappedValue: navigator)

        bindReplacement()
    }

    func replaceNavigator(_ navigator: Navigator<NavigatorDestination>) {
        self.navigator = navigator
        bindReplacement()
    }

    private func bindReplacement() {
        navigator.onReplaceWindow = { [weak self] in
            self?.replaceNavigator($0)
        }
    }
}

struct WindowView<Storage: NavigatorStorage>: View where Storage.Destination == NavigatorDestination {
    let navigatorStorage: Storage
    let navigator: Navigator<NavigatorDestination>

    var body: some View {
        NavigatorStoringView(navigator: navigator, storage: navigatorStorage, scheduler: DispatchQueue.main) {
            NavigatorScreenFactoryView(navigator: navigator, buildView: { destination, navigator in
                let _ = { print("navigationDestination:", destination) }()

                switch destination {
                case _ as RootDestination:
                    RootView(context: .init(
                        related: .init(isReplacementAvailable: navigator.onReplaceWindow != nil),
                        navigation: .init(
                            replaceRoot: { navigator.replace(root: OtherRootDestination()) },
                            replaceWindowWithTabView: {
                                navigator.onReplaceWindow?(Navigator(root: EmptyDestination(), kind: .tabView, tabs: [
                                    Navigator(root: Tab1Destination(), tabItem: .init(title: "Tab 1", image: "pencil.circle", tag: 0)),
                                    Navigator(root: Tab2Destination(), tabItem: .init(title: "Tab 2", image: "square.and.pencil.circle", tag: 1)),
                                ]))
                            },
                            next: { navigator.push(destination: MainDestination()) }
                        )
                    ))
                case _ as OtherRootDestination:
                    OtherRootView(context: .init(
                        replaceRoot: { navigator.replace(root: RootDestination()) },
                        next: { navigator.push(destination: MainDestination()) }
                    ))
                case _ as Root1Destination:
                    Root1View(context: .init(
                        present: { navigator.present(Navigator(root: Root2Destination())) },
                        dismiss: { navigator.dismissTop() }
                    ))
                case _ as Root2Destination:
                    Root2View(context: .init(
                        present: { navigator.present(Navigator(root: Root3Destination())) },
                        dismiss: { navigator.dismissTop() }
                    ))
                case _ as Root3Destination:
                    Root3View(context: .init(
                        closeToRoot: { navigator.closeToRoot() },
                        dismiss: { navigator.dismissTop() }
                    ))
                case _ as Tab1Destination:
                    Tab1View(context: .init(next: { navigator.push(destination: MainDestination()) }))
                case _ as Tab2Destination:
                    Tab2View(context: .init(next: { navigator.push(destination: MainDestination()) }))
                case _ as MainDestination:
                    MainView(context: .init(next: { navigator.push(destination: DetailDestination(number: $0)) }))
                case let detail as DetailDestination:
                    DetailView(context: .init(
                        related: .init(
                            number: detail.number,
                            isReplacementAvailable: navigator.onReplaceWindow != nil,
                            isTabChangeAvailable: navigator.currentTab != nil
                        ),
                        navigation: .init(
                            present: { navigator.present(Navigator(root: Root1Destination())) },
                            fullScreenCover: { navigator.present(Navigator(root: Root1Destination(), presentation: .fullScreenCover)) },
                            reset: { navigator.onReplaceWindow?(.init(root: RootDestination())) },
                            presentTabs: {
                                navigator.present(Navigator(root: EmptyDestination(), kind: .tabView, tabs: [
                                    Navigator(root: Tab1Destination(), tabItem: .init(title: "Tab 3", image: "pencil.circle", tag: 0)),
                                    Navigator(root: Tab2Destination(), tabItem: .init(title: "Tab 4", image: "square.and.pencil.circle", tag: 1)),
                                ]))
                            },
                            changeTabs: {
                                if navigator.currentTab == 0 {
                                    navigator.currentTab = 1
                                } else if navigator.currentTab == 1 {
                                    navigator.currentTab = 0
                                }
                            }
                        )
                    ))
                default:
                    EmptyView()
                }
            })
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
        let closeToRoot: () -> Void
        let dismiss: () -> Void
    }

    let context: Context

    var body: some View {
        VStack(spacing: 16) {
            Text("Current: Root3")
            Button("Close to root", action: context.closeToRoot)
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
            Button("Change tab if available", action: context.navigation.changeTabs)
                .disabled(!context.related.isTabChangeAvailable)
        }
    }
}

#Preview {
    WindowView(
        navigatorStorage: DefaultsNavigatorStorage(),
        navigator: Navigator(root: RootDestination())
    )
}
