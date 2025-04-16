//
//  NavigatorScreenFactoryView.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 30.07.2024.
//

import SwiftUI

/// A generic View responsible for building and managing screens within a `BaseNavigator` navigation system.
///
/// `NavigatorScreenFactoryView` acts as the entry point for rendering views based on a navigation model.
/// It supports single view, tab-based, and navigation stack flows depending on the `Navigator` type configuration.
///
/// - Parameters:
///   - Navigator: A type conforming to `BaseNavigator` that drives the navigation logic.
///   - Content: The type of the content view rendered for each destination.
///   - TabContent: The type of the view rendered for each tab item.
public struct NavigatorScreenFactoryView<
    Navigator: BaseNavigator,
    Content: View,
    TabContent: View
>: View {
    private let navigator: Navigator
    private let rootReplaceAnimation: (Navigator.Destination?) -> Animation?
    @ViewBuilder private let buildView: (Navigator.Destination, Navigator) -> Content
    @ViewBuilder private let buildTab: (Navigator.TabItemTag?) -> TabContent
    private let getDetents: (Navigator.SheetTag?) -> (detents: Set<PresentationDetent>, dragIndicatorVisibility: Visibility)?
    @State private var isFirstAppearanceOccurred = false
    @State private var destinations: [Navigator.Destination]
    @State private var root: Navigator.Destination?
    @State private var isFullScreenCoverPresented = false
    @State private var isSheetPresented = false
    @Environment(\.self) private var environment

    /// Initializes a view for navigators without tab support.
    ///
    /// This initializer is intended for simple use cases without tab navigation. It defaults the tab content to `EmptyView`.
    ///
    /// - Parameters:
    ///   - navigator: The navigation model providing navigation state and destinations.
    ///   - buildView: A closure that returns a content view for a given destination.
    ///   - getDetents: A closure that returns presentation detents and drag indicator visibility for sheets (optional).
    ///   - getRootReplaceAnimation: A closure that provides animation when the root view is replaced (optional).
    public init(
        navigator: Navigator,
        @ViewBuilder buildView: @escaping (Navigator.Destination, Navigator) -> Content,
        getDetents: @escaping (Navigator.SheetTag?) -> (detents: Set<PresentationDetent>, dragIndicatorVisibility: Visibility)? = { _ in ([], .automatic) },
        getRootReplaceAnimation: @escaping (Navigator.Destination?) -> Animation? = { _ in .default }
    ) where Navigator.TabItemTag == EmptyTabItemTag, TabContent == EmptyView {
        self.init(
            navigator: navigator,
            buildView: buildView,
            buildTab: { _ in EmptyView() },
            getDetents: getDetents,
            getRootReplaceAnimation: getRootReplaceAnimation
        )
    }

    /// Initializes a view for navigators.
    ///
    /// This initializer is used for navigators that support tab navigation and require tab views.
    ///
    /// - Parameters:
    ///   - navigator: The navigation model providing navigation state and destinations.
    ///   - buildView: A closure that returns a content view for a given destination.
    ///   - buildTab: A closure that returns a tab view for a given tab item tag.
    ///   - getDetents: A closure that returns presentation detents and drag indicator visibility for sheets (optional).
    ///   - getRootReplaceAnimation: A closure that provides animation when the root view is replaced (optional).
    public init(
        navigator: Navigator,
        @ViewBuilder buildView: @escaping (Navigator.Destination, Navigator) -> Content,
        @ViewBuilder buildTab: @escaping (Navigator.TabItemTag?) -> TabContent,
        getDetents: @escaping (Navigator.SheetTag?) -> (detents: Set<PresentationDetent>, dragIndicatorVisibility: Visibility)? = { _ in ([], .automatic) },
        getRootReplaceAnimation: @escaping (Navigator.Destination?) -> Animation? = { _ in .default }
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
            rootView
                .animation(rootReplaceAnimation(root), value: root)
                .synchronize($root, with: navigator.rootSubj, animated: isAnimatedSubj)
#if os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
                .synchronize(
                    $isFullScreenCoverPresented,
                    with: navigator.childSubj,
                    isFirstAppearanceOccured: $isFirstAppearanceOccurred,
                    isFullScreen: true,
                    animated: isAnimatedSubj
                )
#endif
                .synchronize(
                    $isSheetPresented,
                    with: navigator.childSubj,
                    isFirstAppearanceOccured: $isFirstAppearanceOccurred,
                    isFullScreen: false,
                    animated: isAnimatedSubj
                )
                .onReceive(navigator.environmentPubl, perform: handleEnvironment(action:))
                .onAppear(perform: checkFirstAppearance)
#if os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
                .fullScreenCover(isPresented: $isFullScreenCoverPresented, content: getFullScreenCover)
#endif
                .sheet(isPresented: $isSheetPresented, content: getSheet)
                .with(navigator: navigator)
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
            .with(navigator: navigator)
        case .flow:
            NavigationStack(path: $destinations) {
                rootStackView
            }
            .animation(rootReplaceAnimation(root), value: root)
            .synchronize($root, with: navigator.rootSubj, animated: isAnimatedSubj)
            .synchronize($destinations, with: navigator.destinationsSubj, animated: isAnimatedSubj)
#if os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
            .synchronize(
                $isFullScreenCoverPresented,
                with: navigator.childSubj,
                isFirstAppearanceOccured: $isFirstAppearanceOccurred,
                isFullScreen: true,
                animated: isAnimatedSubj
            )
#endif
            .synchronize(
                $isSheetPresented,
                with: navigator.childSubj,
                isFirstAppearanceOccured: $isFirstAppearanceOccurred,
                isFullScreen: false,
                animated: isAnimatedSubj
            )
            .onReceive(navigator.environmentPubl, perform: handleEnvironment(action:))
            .onAppear(perform: checkFirstAppearance)
#if os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
            .fullScreenCover(isPresented: $isFullScreenCoverPresented, content: getFullScreenCover)
#endif
            .sheet(isPresented: $isSheetPresented, content: getSheet)
            .with(navigator: navigator)
        }
    }

    private func handleEnvironment(action: EnvironmentAction) {
        switch action {
        case let .openURL(url):
            environment.openURL(url)
        case let .openWindow(id):
            environment.openWindow(id: id)
        case let .dismissWindow(id):
            if #available(iOS 17.0, macOS 14.0, visionOS 1.0, *) {
                environment.dismissWindow(id: id)
            }
        case let .external(action):
            environment.externalAction?(action)
        }
    }

    private func checkFirstAppearance() {
        guard !isFirstAppearanceOccurred else { return }

#if os(iOS)
        // Crutch to avoid iOS 16.0+ 💩 issue
        if navigator.childSubj.value != nil && UIView.areAnimationsEnabled {
            UIView.setAnimationsEnabled(false)
        }
        Task { @MainActor in
            isFirstAppearanceOccurred = true
            if navigator.childSubj.value == nil && !UIView.areAnimationsEnabled {
                Task {
                    try? await Task.sleep(for: .milliseconds(100))
                    UIView.setAnimationsEnabled(true)
                }
            }
        }
#else
        isFirstAppearanceOccurred = true
#endif
    }

    @ViewBuilder
    private func getSheet() -> some View {
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

    @ViewBuilder
    private func getFullScreenCover() -> some View {
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

    @ViewBuilder
    private var rootView: some View {
        if let root {
            buildView(root, navigator)
        }
    }

    @ViewBuilder
    private var rootStackView: some View {
        if let root {
            buildView(root, navigator)
                .navigationDestination(for: Navigator.Destination.self) {
                    buildView($0, navigator)
                }
        }
    }
}
