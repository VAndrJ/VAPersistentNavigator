//
//  ExampleTabViews.swift
//  Example
//
//  Created by VAndrJ on 4/6/25.
//

import SwiftUI
import VAPersistentNavigator

struct Tab1ScreenView: View {
    @Environment(\.navigator) private var navigator

    var body: some View {
        VStack(spacing: 16) {
            Text("Current: Tab1")
            Button("Next") {
                navigator.push(destination: .tab1)
            }
            Button("Switch to tab 2") {
                navigator.currentTab = .second
            }
            Button("Replace with main menu") {
                navigator.onReplaceInitialNavigator?(.init(root: .main))
            }
        }
        .navigationTitle("Tab 1")
    }
}

struct Tab2ScreenView: View {
    @Environment(\.navigator) private var navigator

    var body: some View {
        VStack(spacing: 16) {
            Text("Current: Tab2")
            Button("Next") {
                navigator.push(destination: .tab2)
            }
            Button("Switch to tab 1") {
                navigator.currentTab = .first
            }
            Button("Replace with main menu") {
                navigator.onReplaceInitialNavigator?(.init(root: .main))
            }
        }
        .navigationTitle("Tab 2")
    }
}
