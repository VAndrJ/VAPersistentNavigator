//
//  ExampleViews.swift
//  Example
//
//  Created by VAndrJ on 4/5/25.
//

import SwiftUI
import VAPersistentNavigator
import FeaturePackage

struct WindowView: View {
    let navigatorStorage: DefaultsNavigatorStorage
    let navigator: Navigator

    var body: some View {
        NavigatorStoringView(navigator: navigator, storage: navigatorStorage, delay: .seconds(3)) {
            NavigatorScreenFactoryView(
                navigator: navigator,
                buildView: { destination, navigator in
                    let _ = { print("navigationDestination:", destination) }()

                    /// We can use functions DI for navigation
                    /// to be independent of the specific implementation of the navigator
                    /// And rule them all in one place.
                    /// Or use `\.persistentNavigator` environment variable to use in-place, like ``FeatureScreenFactoryView`` example
                    switch destination {
                    case let .feature(destination):
                        FeatureScreenFactoryView(destination: destination)
                    case let .featurePackage(destination):
                        FeaturePackageScreenFactoryView(
                            navigator: navigator,
                            destination: destination,
                            getOuterDestination: { .featurePackage($0) }
                        )
                    case .greeting:
                        GreetingScreenView(context: .init(
                            start: { navigator.onReplaceInitialNavigator?(.init(root: .root)) },
                            hello: { navigator.replace(.hello) },
                            nextToAssert: {
                                if !navigator.push(destination: .main) {
                                    assertionFailure("Push failed")
                                }
                            }
                        ))
                    case .hello:
                        HelloScreenView(context: .init(
                            start: { navigator.onReplaceInitialNavigator?(.init(root: .root)) },
                            greeting: { navigator.replace(.greeting) },
                            nextToAssert: {
                                if !navigator.push(destination: .main) {
                                    assertionFailure("Push failed")
                                }
                            }
                        ))
                    case .root:
                        RootScreenView(context: .init(
                            related: .init(isReplacementAvailable: navigator.onReplaceInitialNavigator != nil),
                            navigation: .init(
                                replaceRoot: { navigator.replace(.otherRoot) },
                                replaceWindowWithTabView: {
                                    navigator.onReplaceInitialNavigator?(.init(
                                        tabs: [
                                            .init(root: .tab1, tabItem: .first(.first)),
                                            .init(root: .tab2, tabItem: .first(.second)),
                                        ],
                                        selectedTab: .first(.first)
                                    ))
                                },
                                next: { navigator.push(destination: .main) },
                                navigationLinks: { navigator.push(destination: .navigationLinks) },
                                presentFeature: { navigator.present(.init(root: .feature(.root))) },
                                presentPackageFeature: { navigator.present(.init(root: .featurePackage(.root))) }
                            )
                        ))
                    case .otherRoot:
                        OtherRootScreenView(context: .init(
                            replaceRoot: { navigator.replace(.root) },
                            navigationLinks: { navigator.push(destination: .navigationLinks) },
                            next: { navigator.push(destination: .main) }
                        ))
                    case .root1:
                        Root1ScreenView(context: .init(
                            present: { navigator.present(.init(root: .root2, presentation: .sheet(tag: .first))) },
                            dismiss: { navigator.dismissTop() }
                        ))
                    case .root2:
                        Root2ScreenView(context: .init(
                            present: { navigator.present(.init(root: .root3)) },
                            dismiss: { navigator.dismissTop() }
                        ))
                    case .root3:
                        Root3ScreenView(context: .init(
                            closeToInitial: { navigator.closeToInitial() },
                            closeToRoot1: { navigator.close(target: .root1) },
                            dismiss: { navigator.dismissTop() }
                        ))
                    case .tab1:
                        Tab1ScreenView(context: .init(next: { navigator.push(destination: .main) }))
                    case .tab2:
                        Tab2ScreenView(context: .init(next: { navigator.push(destination: .main) }))
                    case .main:
                        MainScreenView(context: .init(next: { navigator.push(destination: .detail(number: $0)) }))
                    case .navigationLinks:
                        NavigationLinksExampleView()
                    case .shortcutExample:
                        Text("Shortcut example \(Int.random(in: 0...1000))")
                    case let .notificationExample(title, body):
                        VStack {
                            Text(title)
                                .font(.title)
                            Text(body)
                        }
                    case let .detail(number):
                        DetailScreenView(context: .init(
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
                                popToMain: { navigator.pop(target: .main) },
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

struct GreetingScreenView: View {
    struct Context {
        let start: () -> Void
        let hello: () -> Void
        let nextToAssert: () -> Void
    }

    let context: Context

    var body: some View {
        VStack(spacing: 16) {
            Text("Hello, world!")
            Button("Hello", action: context.hello)
            Button("Start", action: context.start)
            Button("Next to assert", action: context.nextToAssert)
        }
        .transition(.scale)
    }
}

struct HelloScreenView: View {
    struct Context {
        let start: () -> Void
        let greeting: () -> Void
        let nextToAssert: () -> Void
    }

    let context: Context

    var body: some View {
        VStack(spacing: 16) {
            Text("Hello!")
            Button("Hello", action: context.greeting)
            Button("Start", action: context.start)
            Button("Next to assert", action: context.nextToAssert)
        }
        .transition(.scale)
    }
}

struct RootScreenView: View {
    struct Context {
        struct Related {
            let isReplacementAvailable: Bool
        }

        struct Navigation {
            let replaceRoot: () -> Void
            let replaceWindowWithTabView: () -> Void
            let next: () -> Void
            let navigationLinks: () -> Void
            let presentFeature: () -> Void
            let presentPackageFeature: () -> Void
        }

        let related: Related
        let navigation: Navigation
    }

    let context: Context

    var body: some View {
        VStack(spacing: 16) {
            Text("Current: Root")
            Button("Other root", action: context.navigation.replaceRoot)
            Button("Replace window with TabView", action: context.navigation.replaceWindowWithTabView)
                .disabled(!context.related.isReplacementAvailable)
            Button("Next", action: context.navigation.next)
            Button("NavigationLink example", action: context.navigation.navigationLinks)
            Button(#"Present "Feature""#, action: context.navigation.presentFeature)
            Button(#"Present "Package Feature""#, action: context.navigation.presentPackageFeature)
        }
        .navigationTitle("Root")
    }
}

struct Tab1ScreenView: View {
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

struct Tab2ScreenView: View {
    struct Context {
        let next: () -> Void
    }

    let context: Context
    @StateObject private var viewModel = Tab2ScreenViewViewModel()

    var body: some View {
        VStack(spacing: 16) {
            Text("Current: Tab2")
            Button("Next", action: context.next)
        }
        .navigationTitle("Tab 2")
        .onFirstAppear {
            viewModel.onFirstAppear()
        }
    }
}

final class Tab2ScreenViewViewModel: ObservableObject {

    init() {
        print(#function, Self.self)
    }

    func onFirstAppear() {
        print(#function, Self.self)
    }

    deinit {
        print(#function, Self.self)
    }
}

struct Root1ScreenView: View {
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

struct Root2ScreenView: View {
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

struct Root3ScreenView: View {
    struct Context {
        let closeToInitial: () -> Void
        let closeToRoot1: () -> Void
        let dismiss: () -> Void
    }

    let context: Context

    var body: some View {
        VStack(spacing: 16) {
            Text("Current: Root3")
            Button("Close to initial", action: context.closeToInitial)
            Button("Close to root 1", action: context.closeToRoot1)
            Button("Dismiss", action: context.dismiss)
        }
    }
}

struct OtherRootScreenView: View {
    struct Context {
        let replaceRoot: () -> Void
        let navigationLinks: () -> Void
        let next: () -> Void
    }

    let context: Context

    var body: some View {
        VStack(spacing: 16) {
            Text("Current: Other Root")
            Button("Root", action: context.replaceRoot)
            Button("NavigationLink example", action: context.navigationLinks)
            Button("Next", action: context.next)
        }
        .navigationTitle("Other Root")
    }
}

struct MainScreenView: View {
    struct Context {
        let next: (Int) -> Void
    }

    let context: Context

    var body: some View {
        VStack(spacing: 16) {
            Text("Current: Main")
            Button("Next", action: context.next <<| .random(in: 0...1000))
        }
    }
}

struct DetailScreenView: View {
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
