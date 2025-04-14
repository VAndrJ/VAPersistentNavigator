//
//  WindowReaderView.swift
//  Example
//
//  Created by VAndrJ on 4/14/25.
//

import SwiftUI

struct WindowReaderView<Content: View>: View {
    let view: (UIWindow) -> Content

    @State private var window: UIWindow?

    init(@ViewBuilder view: @escaping (UIWindow) -> Content) {
        self.view = view
    }

    var body: some View {
        VStack(spacing: 0) {
            if let window {
                view(window)
            }

            WindowHandlerRepresentableView(binding: $window)
                .allowsHitTesting(false)
                .frame(width: 0, height: 0)
        }
    }

    private struct WindowHandlerRepresentableView: UIViewRepresentable {
        var binding: Binding<UIWindow?>

        func makeUIView(context _: Context) -> WindowHandlerView {
            return WindowHandlerView(binding: binding)
        }

        func updateUIView(_: WindowHandlerView, context _: Context) {}
    }

    private class WindowHandlerView: UIView {
        @Binding var binding: UIWindow?

        init(binding: Binding<UIWindow?>) {
            self._binding = binding

            super.init(frame: .zero)

            backgroundColor = .clear
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()

            binding = window
        }
    }
}
