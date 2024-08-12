//
//  NavigatorScreenFactoryView.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 30.07.2024.
//

import SwiftUI

public struct NavigatorScreenFactoryView<Content: View, TabItem: View, Destination: Codable & Hashable, TabItemTag: Codable & Hashable, SheetTag: Codable & Hashable>: View {
    private let navigator: Navigator<Destination, TabItemTag, SheetTag>
    private let rootReplaceAnimation: (Destination?) -> Animation?
    @ViewBuilder private let buildView: (Destination, Navigator<Destination, TabItemTag, SheetTag>) -> Content
    @ViewBuilder private let buildTab: (TabItemTag?) -> TabItem
    private let getDetents: (SheetTag?) -> (detents: Set<PresentationDetent>, dragIndicatorVisibility: Visibility)?
    @State private var isAppeared = false
    @State private var destinations: [Destination]
    @State private var root: Destination?
    @State private var isFullScreenCoverPresented = false
    @State private var isSheetPresented = false

    public init(
        navigator: Navigator<Destination, TabItemTag, SheetTag>,
        @ViewBuilder buildView: @escaping (Destination, Navigator<Destination, TabItemTag, SheetTag>) -> Content,
        @ViewBuilder buildTab: @escaping (TabItemTag?) -> TabItem,
        getDetents: @escaping (SheetTag?) -> (detents: Set<PresentationDetent>, dragIndicatorVisibility: Visibility)? = { _ in ([], .automatic) },
        getRootReplaceAnimation: @escaping (Destination?) -> Animation? = { _ in .default }
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
                isAppeared: $isAppeared,
                isFullScreen: true
            )
            .synchronize(
                $isSheetPresented,
                with: navigator.childSubj,
                isAppeared: $isAppeared,
                isFullScreen: false
            )
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
                    NavigatorScreenFactoryView(
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
                    NavigatorScreenFactoryView(
                        navigator: child,
                        buildView: buildView,
                        buildTab: buildTab,
                        getDetents: getDetents,
                        getRootReplaceAnimation: rootReplaceAnimation
                    )
                    .withDetentsIfNeeded(getDetents(child.presentation.sheetTag))
                }
            }
        case .tabView:
            NavigatorTabView(selectedTabSubj: navigator.selectedTabSubj) {
                ForEach(navigator.tabs) { tab in
                    NavigatorScreenFactoryView(
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
        case .flow:
            NavigationStack(path: $destinations) {
                if let root {
                    buildView(root, navigator)
                        .navigationDestination(for: Destination.self) {
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
                isAppeared: $isAppeared,
                isFullScreen: true
            )
            .synchronize(
                $isSheetPresented,
                with: navigator.childSubj,
                isAppeared: $isAppeared,
                isFullScreen: false
            )
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
                    NavigatorScreenFactoryView(
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
                    NavigatorScreenFactoryView(
                        navigator: child,
                        buildView: buildView,
                        buildTab: buildTab,
                        getDetents: getDetents,
                        getRootReplaceAnimation: rootReplaceAnimation
                    )
                    .withDetentsIfNeeded(getDetents(child.presentation.sheetTag))
                }
            }
        }
    }
}
