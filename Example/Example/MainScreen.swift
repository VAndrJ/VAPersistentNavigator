//
//  MainScreen.swift
//  Example
//
//  Created by VAndrJ on 4/13/25.
//

import SwiftUI

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
                            .init(root: .tab1, tabItem: TabTag.first),
                            .init(root: .tab2, tabItem: TabTag.second),
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
