//
//  ExampleRootWindowView.swift
//  Example
//
//  Created by VAndrJ on 4/6/25.
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
                        Tab1ScreenView()
                    case .tab2:
                        Tab2ScreenView()
                    case .main:
                        MainScreenView(context: .init(next: { navigator.push(destination: .detail(number: $0)) }))
                    case .navigationLinks:
                        NavigationLinksExampleScreenView()
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

#Preview {
    WindowView(
        navigatorStorage: DefaultsNavigatorStorage(),
        navigator: .init(root: .root)
    )
}
