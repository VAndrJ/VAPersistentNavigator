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
                    case .main:
                        MainScreen()
                    case let .navigationStackExamples(number):
                        ExamplePushScreen(number: number)
                    case let .sheetExamples(number):
                        ExampleSheetScreen(number: number)
                    case let .fullScreenCoverExamples(number):
                        ExampleFullScreen(number: number)
                    case let .feature(destination):
                        FeatureScreenFactoryView(destination: destination)
                    case let .featurePackage(destination):
                        FeaturePackageScreenFactoryView(
                            navigator: navigator,
                            destination: destination,
                            getOuterDestination: { .featurePackage($0) }
                        )
                    case .tab1:
                        Tab1ScreenView()
                    case .tab2:
                        Tab2ScreenView()
                    case .shortcutExample:
                        Text("Shortcut example \(Int.random(in: 0...1000))")
                    case let .notificationExample(title, body):
                        VStack {
                            Text(title)
                                .font(.title)
                            Text(body)
                        }
                    }
                },
                buildTab: { tag in
                    switch tag {
                    case .first: Label("Tab 1", systemImage: "pencil.circle")
                    case .second: Label("Tab 2", systemImage: "square.and.pencil.circle")
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
        navigatorStorage: .init(),
        navigator: .init(root: .main)
    )
}
