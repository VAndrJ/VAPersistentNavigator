//
//  ExampleTabViews.swift
//  Example
//
//  Created by VAndrJ on 4/6/25.
//

import SwiftUI

struct Tab1ScreenView: View {
    @Environment(\.navigator) private var navigator

    var body: some View {
        VStack(spacing: 16) {
            Text("Current: Tab1")
            Button("Next") {
                navigator.push(destination: .main)
            }
        }
        .navigationTitle("Tab 1")
    }
}

struct Tab2ScreenView: View {
    @Environment(\.navigator) private var navigator
    @StateObject private var viewModel = Tab2ScreenViewViewModel()

    var body: some View {
        VStack(spacing: 16) {
            Text("Current: Tab2")
            Button("Next") {
                navigator.push(destination: .main)
            }
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
