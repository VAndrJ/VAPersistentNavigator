//
//  WindowReaderView.swift
//  Example
//
//  Created by VAndrJ on 4/14/25.
//

import SwiftUI

struct WindowReaderView<Content: View>: View {
    private let content: (UIWindow) -> Content
    @State private var window: UIWindow?

    init(@ViewBuilder content: @escaping (UIWindow) -> Content) {
        self.content = content
    }

    var body: some View {
        ZStack {
            WindowHandlerRepresentableView(binding: $window)
                .allowsHitTesting(false)
                .frame(width: 0, height: 0)
                .zIndex(1)
            if let window {
                content(window)
                    .zIndex(2)
            }
        }
        .ignoresSafeArea()
    }

    private struct WindowHandlerRepresentableView: UIViewRepresentable {
        var binding: Binding<UIWindow?>

        func makeUIView(context: Context) -> WindowHandlerView {
            return WindowHandlerView(binding: binding)
        }

        func updateUIView(_ uiView: WindowHandlerView, context: Context) {}
    }

    private class WindowHandlerView: UIView {
        @Binding var binding: UIWindow?

        init(binding: Binding<UIWindow?>) {
            self._binding = binding

            super.init(frame: .zero)

            backgroundColor = .clear
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()

            binding = window
        }
    }
}
