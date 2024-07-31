//
//  NavigatorScreenFactoryView.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 30.07.2024.
//

import SwiftUI
import Combine

public struct NavigatorScreenFactoryView<Content, Destination: Codable & Hashable>: View where Content: View {
    private let navigator: Navigator<Destination>
    private let rootReplaceAnimation: Animation?
    @ViewBuilder private  let buildView: (Destination, Navigator<Destination>) -> Content
    @State private var isAppeared = false
    @State private var destinations: [Destination]
    @State private var root: Destination
    @State private var isFullScreenCoverPresented = false
    @State private var isSheetPresented = false

    public init(
        navigator: Navigator<Destination>,
        rootReplaceAnimation: Animation? = .default,
        @ViewBuilder buildView: @escaping (Destination, Navigator<Destination>) -> Content
    ) {
        self.rootReplaceAnimation = rootReplaceAnimation
        self.buildView = buildView
        self.root = navigator.rootSubj.value
        self.destinations = navigator.destinationsSubj.value
        self.navigator = navigator
    }

    public var body: some View {
        switch navigator.kind {
        case .tabView:
            NavigatorTabView(navigator: navigator) {
                ForEach(navigator.tabs) { tab in
                    NavigatorScreenFactoryView(navigator: tab, buildView: buildView)
                        .tabItem {
                            Label(tab.tabItem?.title ?? "", systemImage: tab.tabItem?.image ?? "")
                        }
                        .tag(tab.tabItem?.tag)
                }
            }
        case .flow:
            NavigationStack(path: $destinations) {
                buildView(root, navigator)
                    .navigationDestination(for: Destination.self) {
                        buildView($0, navigator)
                    }
            }
            .animation(rootReplaceAnimation, value: root)
            .synchronize($root, with: navigator.rootSubj)
            .synchronize($destinations, with: navigator.destinationsSubj)
            .synchronize($isFullScreenCoverPresented, with: navigator.childSubj, isAppeared: $isAppeared, presentation: .fullScreenCover)
            .synchronize($isSheetPresented, with: navigator.childSubj, isAppeared: $isAppeared, presentation: .sheet)
            .onAppear {
                guard !isAppeared else { return }

                #if os(iOS)
                // Crutch to avoid iOS 16.0+ 💩 issue
                if navigator.childSubj.value != nil && UIView.areAnimationsEnabled {
                    UIView.setAnimationsEnabled(false)
                }
                Task {
                    await MainActor.run {
                        isAppeared = true
                        Task {
                            await MainActor.run {
                                if navigator.childSubj.value == nil && !UIView.areAnimationsEnabled {
                                    UIView.setAnimationsEnabled(true)
                                }
                            }
                        }
                    }
                }
                #else
                isAppeared = true
                #endif
            }
            #if os(iOS) || os(watchOS) || os(tvOS)
            .fullScreenCover(isPresented: $isFullScreenCoverPresented) {
                if let child = navigator.childSubj.value {
                    NavigatorScreenFactoryView(navigator: child, buildView: buildView)
                }
            }
            #endif
            .sheet(isPresented: $isSheetPresented) {
                if let child = navigator.childSubj.value {
                    NavigatorScreenFactoryView(navigator: child, buildView: buildView)
                }
            }
        }
    }
}

extension View {

    func synchronize<Destination: Codable & Hashable>(
        _ binding: Binding<Bool>,
        with subject: CurrentValueSubject<Navigator<Destination>?, Never>,
        isAppeared: Binding<Bool>,
        presentation: NavigatorPresentation
    ) -> some View {
        self.modifier(SynchronizingNavigatorPresentationViewModifier(
            binding: binding,
            isAppeared: isAppeared,
            subject: subject,
            presentation: presentation
        ))
    }

    func synchronize<T: Equatable>(
        _ binding: Binding<T>,
        with subject: CurrentValueSubject<T, Never>
    ) -> some View {
        self.modifier(SynchronizingViewModifier(binding: binding, subject: subject))
    }
}

struct SynchronizingViewModifier<T: Equatable>: ViewModifier {
    @Binding var binding: T
    let subject: CurrentValueSubject<T, Never>

    func body(content: Content) -> some View {
        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
            content
                .onChange(of: binding) { _, value in
                    subject.send(value)
                }
                .onReceive(subject) { value in
                    binding = value
                }
        } else {
            content
                .onChange(of: binding) { value in
                    subject.send(value)
                }
                .onReceive(subject) { value in
                    binding = value
                }
        }
    }
}

struct SynchronizingNavigatorPresentationViewModifier<Destination: Codable & Hashable>: ViewModifier {
    @Binding var binding: Bool
    @Binding var isAppeared: Bool
    let subject: CurrentValueSubject<Navigator<Destination>?, Never>
    let presentation: NavigatorPresentation

    func body(content: Content) -> some View {
        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
            content
                .onReceive(subject) { value in
                    binding = value?.presentation == presentation && isAppeared
                }
                .onChange(of: isAppeared) { _, value in
                    binding = subject.value?.presentation == presentation && value
                }
                .onChange(of: binding) { _, value in
                    if !value {
                        subject.send(nil)
                    }
                }
        } else {
            content
                .onReceive(subject) { value in
                    binding = value?.presentation == presentation && isAppeared
                }
                .onChange(of: isAppeared) { value in
                    binding = subject.value?.presentation == presentation && value
                }
                .onChange(of: binding) { value in
                    if !value {
                        subject.send(nil)
                    }
                }
        }
    }
}

extension Binding where Value == Bool {

    static func && (_ lhs: Binding<Bool>, _ rhs: Binding<Bool>) -> Binding<Bool> {
        Binding<Bool>(
            get: { lhs.wrappedValue && rhs.wrappedValue },
            set: { lhs.wrappedValue = $0 }
        )
    }

    static func &&<T>(_ lhs: Binding<T?>, _ rhs: Binding<Bool>) -> Binding<Bool> {
        Binding<Bool>(
            get: { lhs.wrappedValue != nil && rhs.wrappedValue },
            set: { value in
                if !value {
                    lhs.wrappedValue = nil
                }
            }
        )
    }
}

struct NavigatorTabView<Content: View, Destination: Codable & Hashable>: View {
    let navigator: Navigator<Destination>
    @ViewBuilder let content: () -> Content
    @State var selection: Int?

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
