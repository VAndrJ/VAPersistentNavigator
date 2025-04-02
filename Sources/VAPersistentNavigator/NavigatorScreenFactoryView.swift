//
//  NavigatorScreenFactoryView.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 30.07.2024.
//

import SwiftUI

public struct NavigatorScreenFactoryView<
    Content: View,
    TabItem: View,
    Destination: PersistentDestination,
    TabItemTag: PersistentTabItemTag,
    SheetTag: PersistentSheetTag
>: View {
    private let navigator: CodablePersistentNavigator<Destination, TabItemTag, SheetTag>
    private let rootReplaceAnimation: (Destination?) -> Animation?
    @ViewBuilder private let buildView: (Destination, CodablePersistentNavigator<Destination, TabItemTag, SheetTag>) -> Content
    @ViewBuilder private let buildTab: (TabItemTag?) -> TabItem
    private let getDetents: (SheetTag?) -> (detents: Set<PresentationDetent>, dragIndicatorVisibility: Visibility)?
    @State private var isFirstAppearanceOccurred = false
    @State private var destinations: [Destination]
    @State private var root: Destination?
    @State private var isFullScreenCoverPresented = false
    @State private var isSheetPresented = false

    public init(
        navigator: CodablePersistentNavigator<Destination, TabItemTag, SheetTag>,
        @ViewBuilder buildView: @escaping (Destination, CodablePersistentNavigator<Destination, TabItemTag, SheetTag>) -> Content,
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
            .environment(\.persistentNavigator, navigator)
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
            .environment(\.persistentNavigator, navigator)
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
            .environment(\.persistentNavigator, navigator)
        }
    }
}

class EmptyNavigator: PersistentNavigator {
    var id: UUID { UUID() }
    var isRootView: Bool { true }

    func replace(root: any PersistentDestination, isPopToRoot: Bool) {}

    func dismissTop() {}
    
    func closeToInitial() {}
    
    func dismiss(to destination: any PersistentDestination) -> Bool {
        return false
    }

    func popToRoot() {}
    
    func dismiss(to id: UUID) -> Bool {
        return false
    }

    @discardableResult
    func push(_ destination: any PersistentDestination) -> Bool {
        return false
    }

    func pop() {}

    func pop(to destination: any PersistentDestination, isFirst: Bool) -> Bool {
        return false
    }

    func present(_ data: NavigatorData, strategy: PresentationStrategy) {}

    @discardableResult
    func closeTo(destination: any PersistentDestination) -> Bool {
        return false
    }

    @discardableResult
    func closeTo(where predicate: (any PersistentDestination) -> Bool) -> Bool {
        return false
    }
}

extension EnvironmentValues {
    @Entry public var persistentNavigator: any PersistentNavigator = emptyNavigator

    private static let emptyNavigator = EmptyNavigator()
}
