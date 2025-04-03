//
//  SimpleNavigatorScreenFactoryView.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 4/3/25.
//

import SwiftUI

public struct SimpleNavigatorScreenFactoryView<Content: View, TabItem: View>: View {
    private let navigator: any SimpleNavigator
    private let rootReplaceAnimation: ((any Hashable)?) -> Animation?
    @ViewBuilder private let buildView: (any Hashable, any SimpleNavigator) -> Content
    @ViewBuilder private let buildTab: ((any Hashable)?) -> TabItem
    private let getDetents: ((any Hashable)?) -> (detents: Set<PresentationDetent>, dragIndicatorVisibility: Visibility)?
    @State private var isFirstAppearanceOccurred = false
    @State private var destinations: [AnyHashable]
    @State private var root: AnyHashable?
    @State private var isFullScreenCoverPresented = false
    @State private var isSheetPresented = false

    public init(
        navigator: any SimpleNavigator,
        @ViewBuilder buildView: @escaping (any Hashable, any SimpleNavigator) -> Content,
        @ViewBuilder buildTab: @escaping ((any Hashable)?) -> TabItem,
        getDetents: @escaping ((any Hashable)?) -> (detents: Set<PresentationDetent>, dragIndicatorVisibility: Visibility)? = { _ in ([], .automatic) },
        getRootReplaceAnimation: @escaping ((any Hashable)?) -> Animation? = { _ in .default }
    ) {
        self.rootReplaceAnimation = getRootReplaceAnimation
        self.buildView = buildView
        self.root = navigator.rootSubj.value
        self.destinations = navigator.destinationsSubj.value
        self.navigator = navigator
        self.buildTab = buildTab
        self.getDetents = getDetents
    }

    public var body: some View {
        switch navigator.kind {
        case .singleView:
            ZStack {
                if let root {
                    buildView(root, navigator)
                } else {
                    EmptyView()
                }
            }
            .animation(rootReplaceAnimation(root), value: root)
            .synchronize($root, with: navigator.rootSubj)
            .synchronize(
                $isFullScreenCoverPresented,
                with: navigator.childSubj,
                isFirstAppearanceOccured: $isFirstAppearanceOccurred,
                isFullScreen: true
            )
            .synchronize(
                $isSheetPresented,
                with: navigator.childSubj,
                isFirstAppearanceOccured: $isFirstAppearanceOccurred,
                isFullScreen: false
            )
            .onAppear {
                guard !isFirstAppearanceOccurred else { return }

#if os(iOS)
                // Crutch to avoid iOS 16.0+ 💩 issue
                if navigator.childSubj.value != nil && UIView.areAnimationsEnabled {
                    UIView.setAnimationsEnabled(false)
                }
                Task {
                    await MainActor.run {
                        isFirstAppearanceOccurred = true
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
                isFirstAppearanceOccurred = true
#endif
            }
#if os(iOS) || os(watchOS) || os(tvOS)
            .fullScreenCover(isPresented: $isFullScreenCoverPresented) {
                if let child = navigator.childSubj.value {
                    SimpleNavigatorScreenFactoryView(
                        navigator: child,
                        buildView: buildView,
                        buildTab: buildTab,
                        getDetents: getDetents,
                        getRootReplaceAnimation: rootReplaceAnimation
                    )
                }
            }
#endif
            .sheet(isPresented: $isSheetPresented) {
                if let child = navigator.childSubj.value {
                    SimpleNavigatorScreenFactoryView(
                        navigator: child,
                        buildView: buildView,
                        buildTab: buildTab,
                        getDetents: getDetents,
                        getRootReplaceAnimation: rootReplaceAnimation
                    )
                    .withDetentsIfNeeded(getDetents(child.presentation.sheetTag))
                }
            }
            .environment(\.simpleNavigator, navigator)
        case .tabView:
            SimpleNavigatorTabView(selectedTabSubj: navigator.selectedTabSubj) {
                ForEach(navigator.tabs, id: \.id) { tab in
                    SimpleNavigatorScreenFactoryView(
                        navigator: tab,
                        buildView: buildView,
                        buildTab: buildTab,
                        getDetents: getDetents,
                        getRootReplaceAnimation: rootReplaceAnimation
                    )
                    .tabItem {
                        buildTab(tab.tabItem)
                    }
                    .tag(tab.tabItem)
                }
            }
            .environment(\.simpleNavigator, navigator)
        case .flow:
            NavigationStack(path: $destinations) {
                if let root {
                    buildView(root, navigator)
                        .navigationDestination(for: AnyHashable.self) {
                            buildView($0, navigator)
                        }
                } else {
                    EmptyView()
                }
            }
            .animation(rootReplaceAnimation(root), value: root)
            .synchronize($root, with: navigator.rootSubj)
            .synchronize($destinations, with: navigator.destinationsSubj)
            .synchronize(
                $isFullScreenCoverPresented,
                with: navigator.childSubj,
                isFirstAppearanceOccured: $isFirstAppearanceOccurred,
                isFullScreen: true
            )
            .synchronize(
                $isSheetPresented,
                with: navigator.childSubj,
                isFirstAppearanceOccured: $isFirstAppearanceOccurred,
                isFullScreen: false
            )
            .onAppear {
                guard !isFirstAppearanceOccurred else { return }

#if os(iOS)
                // Crutch to avoid iOS 16.0+ 💩 issue
                if navigator.childSubj.value != nil && UIView.areAnimationsEnabled {
                    UIView.setAnimationsEnabled(false)
                }
                // To guarantee delays.
                Task {
                    await MainActor.run {
                        isFirstAppearanceOccurred = true
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
                isFirstAppearanceOccurred = true
#endif
            }
#if os(iOS) || os(watchOS) || os(tvOS)
            .fullScreenCover(isPresented: $isFullScreenCoverPresented) {
                if let child = navigator.childSubj.value {
                    SimpleNavigatorScreenFactoryView(
                        navigator: child,
                        buildView: buildView,
                        buildTab: buildTab,
                        getDetents: getDetents,
                        getRootReplaceAnimation: rootReplaceAnimation
                    )
                }
            }
#endif
            .sheet(isPresented: $isSheetPresented) {
                if let child = navigator.childSubj.value {
                    SimpleNavigatorScreenFactoryView(
                        navigator: child,
                        buildView: buildView,
                        buildTab: buildTab,
                        getDetents: getDetents,
                        getRootReplaceAnimation: rootReplaceAnimation
                    )
                    .withDetentsIfNeeded(getDetents(child.presentation.sheetTag))
                }
            }
            .environment(\.simpleNavigator, navigator)
        }
    }
}
