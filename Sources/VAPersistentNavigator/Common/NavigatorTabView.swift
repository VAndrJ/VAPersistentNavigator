//
//  NavigatorTabView.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 8/5/24.
//

import SwiftUI
import Combine

struct NavigatorTabView<Content: View, SelectionValue: Hashable>: View {
    private let selectedTabSubj: CurrentValueSubject<SelectionValue?, Never>
    private let content: () -> Content
    @State private var selection: SelectionValue?

    init(
        selectedTabSubj: CurrentValueSubject<SelectionValue?, Never>,
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
