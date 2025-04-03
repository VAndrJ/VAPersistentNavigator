//
//  SimpleNavigatorTabView.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 4/3/25.
//

import SwiftUI
import Combine

struct SimpleNavigatorTabView<Content: View>: View {
    private let selectedTabSubj: CurrentValueSubject<AnyHashable?, Never>
    @ViewBuilder private let content: () -> Content
    @State private var selection: AnyHashable?

    init(
        selectedTabSubj: CurrentValueSubject<AnyHashable?, Never>,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.selection = selectedTabSubj.value
        self.selectedTabSubj = selectedTabSubj
        self.content = content
    }

    var body: some View {
        TabView(selection: $selection) {
            content()
        }
        .synchronize($selection, with: selectedTabSubj)
    }
}
