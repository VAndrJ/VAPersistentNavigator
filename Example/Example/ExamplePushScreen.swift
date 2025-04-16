//
//  ExamplePushScreen.swift
//  Example
//
//  Created by VAndrJ on 4/13/25.
//

import SwiftUI
import VAPersistentNavigator

struct ExamplePushScreen: View {
    let number: Int

    @Environment(\.navigator) private var navigator
    @State private var text = ""
    @State private var isPopAlertPresented = false

    @Namespace private var namespace
    private let zoomId = "Zoooooom"

    var body: some View {
        VStack(alignment: .leading) {
            Text("NavigationStack push/pop/root replacement with animation or without. \(number)")
                .padding()

            List {
                Section("Push") {
                    ListTileView(title: "Push animated") {
                        navigator.push(destination: .navigationStackExamples(Int.random(in: 0..<1000)))
                    }
                    ListTileView(title: "Push without animation") {
                        navigator.push(destination: .navigationStackExamples(Int.random(in: 0..<1000)), animated: false)
                    }
                    NavigationLink(
                        "Push with NavigationLink",
                        value: Destination.navigationStackExamples(Int.random(in: 0..<1000))
                    )
                    if #available(iOS 18.0, *) {
                        ListTileView(title: "Push with zoom animation") {
                            navigator.push(
                                destination: .navigationStackExamples(
                                    Int.random(in: 0..<1000),
                                    transition: .init(zoom: namespace, id: zoomId)
                                )
                            )
                        }
                        .matchedTransitionSource(id: zoomId, in: namespace)
                    }
                }

                Section("Replace root") {
                    ListTileView(title: "Replace animated", style: .replace) {
                        navigator.replace(.navigationStackExamples(Int.random(in: 0..<1000)))
                    }
                    ListTileView(title: "Replace without animation", style: .replace) {
                        navigator.replace(.navigationStackExamples(Int.random(in: 0..<1000)), animated: false)
                    }
                    .disabled(navigator.isRootView)
                    ListTileView(title: "Replace without popping", style: .replace) {
                        navigator.replace(.navigationStackExamples(Int.random(in: 0..<1000)), isPopToRoot: false)
                    }
                    ListTileView(title: "Replace with main menu", style: .replace) {
                        navigator.onReplaceInitialNavigator?(.init(root: .main))
                    }
                    .disabled(navigator.onReplaceInitialNavigator == nil)
                }

                Section("Pop") {
                    ListTileView(title: "Pop animated", style: .backward) {
                        navigator.pop()
                    }
                    ListTileView(title: "Pop without animation", style: .backward) {
                        navigator.pop(animated: false)
                    }
                }
                .disabled(navigator.isRootView)

                Section("Pop to root") {
                    ListTileView(title: "Pop to root animated", style: .backward) {
                        navigator.popToRoot()
                    }
                    .disabled(navigator.isRootView)
                    ListTileView(title: "Pop to root without animation", style: .backward) {
                        navigator.popToRoot(animated: false)
                    }
                }
                .disabled(navigator.isRootView)

                Section("Pop to specified destination") {
                    TextField("Enter number to pop", text: $text)
                        .keyboardType(.numberPad)
                    ListTileView(
                        title: "Pop to destination with entered number animated (if available)",
                        style: .backward
                    ) {
                        if !navigator.pop(target: .navigationStackExamples(Int(text) ?? -1)) {
                            isPopAlertPresented = true
                        }
                    }
                    .disabled(Int(text) == nil || navigator.isRootView)
                    ListTileView(
                        title: "Pop to destination with entered number without animation (if available)",
                        style: .backward
                    ) {
                        if !navigator.pop(target: .navigationStackExamples(Int(text) ?? -1), animated: false) {
                            isPopAlertPresented = true
                        }
                    }
                    .disabled(Int(text) == nil || navigator.isRootView)
                    ListTileView(
                        title: "Pop to destination with entered number using predicate animated (if available)",
                        style: .backward
                    ) {
                        if !navigator.pop(predicate: {
                            switch $0 {
                            case let .navigationStackExamples(number, _):
                                return number == Int(text)
                            default:
                                return false
                            }
                        }) {
                            isPopAlertPresented = true
                        }
                    }
                    .disabled(Int(text) == nil || navigator.isRootView)
                    ListTileView(
                        title: "Pop to destination with entered number using predicate without animation (if available)",
                        style: .backward
                    ) {
                        if !navigator.pop(
                            predicate: {
                                switch $0 {
                                case let .navigationStackExamples(number, _):
                                    return number == Int(text)
                                default:
                                    return false
                                }
                            },
                            animated: false
                        ) {
                            isPopAlertPresented = true
                        }
                    }
                    .disabled(Int(text) == nil || navigator.isRootView)
                    ListTileView(
                        title: "Close to destination with entered number using predicate animated (if available)",
                        style: .backward
                    ) {
                        if !navigator.close(predicate: {
                            switch $0 {
                            case let .navigationStackExamples(number, _):
                                return number == Int(text)
                            default:
                                return false
                            }
                        }) {
                            isPopAlertPresented = true
                        }
                    }
                    .disabled(Int(text) == nil || navigator.isRootView)
                    ListTileView(
                        title: "Close to destination with entered number using predicate without animation (if available)",
                        style: .backward
                    ) {
                        if !navigator.close(
                            predicate: {
                                switch $0 {
                                case let .navigationStackExamples(number, _):
                                    return number == Int(text)
                                default:
                                    return false
                                }
                            },
                            animated: false
                        ) {
                            isPopAlertPresented = true
                        }
                    }
                    .disabled(Int(text) == nil || navigator.isRootView)
                }
            }
            .alert("Pop was unsuccessful", isPresented: $isPopAlertPresented) {
                Button("OK") {}
            }
        }
        .navigationTitle("Examples \(number)")
    }
}


#Preview {
    WindowView(
        navigatorStorage: .init(),
        navigator: .init(root: .navigationStackExamples(42))
    )
}
