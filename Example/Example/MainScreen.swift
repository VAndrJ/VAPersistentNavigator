//
//  MainScreen.swift
//  Example
//
//  Created by VAndrJ on 4/13/25.
//

import SwiftUI
import VAPersistentNavigator

struct MainScreen: View {
    @Environment(\.navigator) private var navigator

    var body: some View {
        VStack(alignment: .leading) {
            Text("Functions examples")
                .padding()
            List {
                Section {
                    ListTileView(title: "NavigationStack examples") {
                        navigator.onReplaceInitialNavigator?(
                            .init(root: .navigationStackExamples(Int.random(in: 0..<1000)))
                        )
                    }
                    ListTileView(title: "Sheet examples") {
                        navigator.onReplaceInitialNavigator?(
                            .init(root: .sheetExamples(Int.random(in: 0..<1000)))
                        )
                    }
                    ListTileView(title: "Full screen cover examples") {
                        navigator.onReplaceInitialNavigator?(
                            .init(root: .fullScreenCoverExamples(Int.random(in: 0..<1000)))
                        )
                    }
                    ListTileView(title: "TabView examples") {
                        navigator.onReplaceInitialNavigator?(.init(tabs: [
                            .init(root: .tab1, tabItem: .first),
                            .init(root: .tab2, tabItem: .second),
                        ]))
                    }
                }
                .disabled(navigator.onReplaceInitialNavigator == nil)

                Section {
                    ListTileView(title: "Separate feature flow example") {
                        navigator.present(.init(root: .feature(.root)))
                    }
                    ListTileView(title: "Separate feature package flow example") {
                        navigator.present(.init(root: .featurePackage(.root)))
                    }
                }

                Section {
                    ListTileView(title: "Open URL", style: .apple) {
                        navigator.open(url: .apple)
                    }
                    ListTileView(title: "Open URL (sheet)", style: .apple) {
                        navigator.present(.init(view: .url(.apple)))
                    }
                    ListTileView(title: "Open App settings", style: .settings) {
                        navigator.open(url: .settings)
                    }
                    if UIDevice.current.userInterfaceIdiom == .pad {
                        ListTileView(title: "Open second window", style: .openWindow) {
                            navigator.open(window: .auxiliaryWindowId)
                        }
                    }
                    ListTileView(title: "Review", style: .review) {
                        navigator.pass(action: MessageAction.review)
                    }
                }
            }
        }
        .navigationTitle("Navigator")
    }
}

#Preview {
    WindowView(
        navigatorStorage: .init(),
        navigator: .init(root: .main)
    )
}
