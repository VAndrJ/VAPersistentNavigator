//
//  Support.swift
//  Example
//
//  Created by VAndrJ on 8/12/24.
//

import Foundation
import SwiftUI

precedencegroup BackwardApplication {
    associativity: right
    higherThan: AssignmentPrecedence
}

infix operator <<| : BackwardApplication

func <<| <A, R>(_ f: @escaping (A) -> R, _ a: A) -> () -> R {
    { f(a) }
}

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
