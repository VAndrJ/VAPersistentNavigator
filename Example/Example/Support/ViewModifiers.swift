//
//  ViewModifiers.swift
//  Example
//
//  Created by VAndrJ on 1/21/25.
//

import SwiftUI

extension View {

    public func onFirstAppear(perform action: @escaping () -> Void) -> some View {
        modifier(OnFirstAppearViewModifier(onFirstAppear: action))
    }
}

struct OnFirstAppearViewModifier: ViewModifier {
    let onFirstAppear: () -> Void

    @State private var isAppeared = false

    func body(content: Content) -> some View {
        content
            .onAppear {
                guard !isAppeared else { return }

                onFirstAppear()
                isAppeared = true
            }
    }
}
