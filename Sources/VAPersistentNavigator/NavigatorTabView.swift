//
//  NavigatorTabView.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 8/5/24.
//

import SwiftUI

struct NavigatorTabView<Content: View, Destination: Codable & Hashable>: View {
    let navigator: Navigator<Destination>
    @ViewBuilder let content: () -> Content

    @State private var selection: Int?

    init(navigator: Navigator<Destination>, @ViewBuilder content: @escaping () -> Content) {
        self.selection = navigator.selectedTabSubj.value
        self.navigator = navigator
        self.content = content
    }

    var body: some View {
        TabView(selection: $selection) {
            content()
        }
        .synchronize($selection, with: navigator.selectedTabSubj)
    }
}
