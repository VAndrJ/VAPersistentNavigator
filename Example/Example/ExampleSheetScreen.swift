//
//  ExampleSheetScreen.swift
//  Example
//
//  Created by VAndrJ on 4/14/25.
//

import SwiftUI
import VAPersistentNavigator

struct ExampleSheetScreen: View {
    let number: Int

    @Environment(\.navigator) private var navigator
    @State private var numberText = ""
    @State private var uuidText = ""
    @State private var isDismissAlertPresented = false

    var body: some View {
        List {
            Section("Present") {
                ListTileView(title: "Present view animated") {
                    navigator.present(.view(Destination.sheetExamples(Int.random(in: 0...1000))))
                }
                ListTileView(title: "Present view with detents animated") {
                    navigator.present(
                        .view(
                            Destination.sheetExamples(Int.random(in: 0...1000)),
                            presentation: .sheet(tag: SheetTag.first)
                        )
                    )
                }
                ListTileView(title: "Present view without animation") {
                    navigator.present(.view(Destination.sheetExamples(Int.random(in: 0...1000))), animated: false)
                }
                ListTileView(title: "Present stack animated") {
                    navigator.present(.stack(root: Destination.sheetExamples(Int.random(in: 0...1000))))
                }
                ListTileView(title: "Present tabs animated") {
                    navigator.present(
                        .tab(tabs: [
                            .view(Destination.sheetExamples(Int.random(in: 0...1000)), tabItem: TabTag.first),
                            .stack(root: Destination.sheetExamples(Int.random(in: 0...1000)), tabItem: TabTag.second),
                        ])
                    )
                }
            }

            Section("Dismiss") {
                ListTileView(title: "Dismiss top animated", style: .backward) {
                    navigator.dismissTop()
                }
                .disabled(!navigator.isPresented)
                ListTileView(title: "Dismiss top without animation", style: .backward) {
                    navigator.dismissTop(animated: false)
                }
                .disabled(!navigator.isPresented)
                ListTileView(title: "Dismiss top tab view animated", style: .backward) {
                    navigator.dismissTop(includingTabView: true)
                }
                .disabled(!navigator.isPresentedTab)
                ListTileView(title: "Replace with main menu", style: .replace) {
                    navigator.onReplaceInitialNavigator?(.init(root: .main))
                }
                .disabled(navigator.onReplaceInitialNavigator == nil)
            }

            Section("Close") {
                ListTileView(title: "Close to initial animated", style: .backward) {
                    navigator.closeToInitial()
                }
                ListTileView(title: "Close to initial without animation", style: .backward) {
                    navigator.closeToInitial(animated: false)
                }
            }
            .disabled(!(navigator.isPresented || navigator.isPresentedTab))

            Section("Dismiss to specified destination") {
                VStack {
                    TextField("Enter number to dismiss to", text: $numberText)
                        .keyboardType(.numberPad)
                    Button("Get parent destination number") {
                        switch navigator.parent?.root {
                        case let .sheetExamples(number):
                            numberText = "\(number)"
                        default:
                            break
                        }
                    }
                    .buttonStyle(.plain)
                }
                .disabled(!navigator.isPresented)
                ListTileView(
                    title: "Dismiss to destination with entered number animated (if available)",
                    style: .backward
                ) {
                    if !navigator.dismiss(target: .sheetExamples(Int(numberText) ?? -1)) {
                        isDismissAlertPresented = true
                    }
                }
                .disabled(Int(numberText) == nil)
                ListTileView(
                    title: "Dismiss to destination with entered number without animation (if available)",
                    style: .backward
                ) {
                    if !navigator.dismiss(target: .sheetExamples(Int(numberText) ?? -1), animated: false) {
                        isDismissAlertPresented = true
                    }
                }
                .disabled(Int(numberText) == nil)
                ListTileView(
                    title: "Dismiss to destination using predicate with entered number animated (if available)",
                    style: .backward
                ) {
                    if !navigator.dismiss(predicate: {
                        switch $0 {
                        case let .sheetExamples(number):
                            return number == Int(numberText)
                        default:
                            return false
                        }
                    }) {
                        isDismissAlertPresented = true
                    }
                }
                .disabled(Int(numberText) == nil)
                ListTileView(
                    title: "Dismiss to destination using predicate with entered number without animation (if available)",
                    style: .backward
                ) {
                    if !navigator.dismiss(
                        predicate: {
                            switch $0 {
                            case let .sheetExamples(number):
                                return number == Int(numberText)
                            default:
                                return false
                            }
                        },
                        animated: false
                    ) {
                        isDismissAlertPresented = true
                    }
                }
                .disabled(Int(numberText) == nil)
                ListTileView(
                    title: "Close to destination with entered number animated (if available)",
                    style: .backward
                ) {
                    if !navigator.close(target: .sheetExamples(Int(numberText) ?? -1)) {
                        isDismissAlertPresented = true
                    }
                }
                .disabled(Int(numberText) == nil)
                ListTileView(
                    title: "Close to destination with entered number without animation (if available)",
                    style: .backward
                ) {
                    if !navigator.close(target: .sheetExamples(Int(numberText) ?? -1), animated: false) {
                        isDismissAlertPresented = true
                    }
                }
                .disabled(Int(numberText) == nil)
            }

            Section("Dismiss to specified UUID") {
                VStack {
                    TextField("Enter UUID to dismiss to", text: $uuidText)
                        .keyboardType(.numberPad)
                    Button("Get parent destination UUID") {
                        uuidText = navigator.orTabParent?.id.uuidString ?? ""
                    }
                    .buttonStyle(.plain)
                }
                .disabled(!(navigator.isPresented || navigator.isPresentedTab))
                ListTileView(
                    title: "Dismiss to destination with entered UUID animated (if available)",
                    style: .backward
                ) {
                    if let uuid = UUID(uuidString: uuidText), !navigator.dismissTo(id: uuid) {
                        isDismissAlertPresented = true
                    }
                }
                .disabled(UUID(uuidString: uuidText) == nil)
                ListTileView(
                    title: "Dismiss to destination with entered UUID without animation (if available)",
                    style: .backward
                ) {
                    if let uuid = UUID(uuidString: uuidText), !navigator.dismissTo(id: uuid, animated: false) {
                        isDismissAlertPresented = true
                    }
                }
                .disabled(UUID(uuidString: uuidText) == nil)
            }
        }
        .alert("Dismiss was unsuccessful", isPresented: $isDismissAlertPresented) {
            Button("OK") {}
        }
        .navigationTitle(("Sheet view \(number)"))
    }
}

#Preview {
    WindowView(
        navigatorStorage: .init(),
        navigator: .init(root: .sheetExamples(42))
    )
}
