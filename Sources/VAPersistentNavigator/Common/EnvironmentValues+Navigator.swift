//
//  EnvironmentValues+Navigator.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 4/3/25.
//

import SwiftUI
import Combine

extension EnvironmentValues {
    /// The current `BaseNavigator` available in the environment.
    ///
    /// This provides access to a generic navigation context, allowing views to interact
    /// with the navigation system (e.g., pushing destinations or accessing navigation state)
    /// without requiring direct injection of a concrete navigator.
    @Entry public var baseNavigator: any BaseNavigator = emptyPersistentNavigator

    /// The current `PersistentNavigator` available in the environment.
    ///
    /// This provides access to a generic navigation context, allowing views to interact
    /// with the navigation system (e.g., pushing destinations or accessing navigation state)
    /// without requiring direct injection of a concrete navigator.
    @Entry public var persistentNavigator: any PersistentNavigator = emptyPersistentNavigator

    static let emptyPersistentNavigator = EmptyPersistentNavigator()
}

final class EmptyPersistentNavigator: PersistentNavigator {
    typealias Destination = String
    typealias TabItemTag = String
    typealias SheetTag = String

    var childCancellable: AnyCancellable?
    var bag: Set<AnyCancellable> = []
    var _onReplaceInitialNavigator: ((EmptyPersistentNavigator) -> Void)?
    var storeSubj: PassthroughSubject<Void, Never> { .init() }
    var destinationsSubj: CurrentValueSubject<[Destination], Never> { .init([]) }
    var parent: EmptyPersistentNavigator?
    var tabItem: TabItemTag?
    var selectedTabSubj: CurrentValueSubject<TabItemTag?, Never> { .init(nil) }
    var rootSubj: CurrentValueSubject<Destination?, Never> { .init(nil) }
    var childSubj: CurrentValueSubject<EmptyPersistentNavigator?, Never> { .init(nil) }
    var tabs: [EmptyPersistentNavigator] { [] }
    var kind: NavigatorKind { .singleView }
    var presentation: TypedNavigatorPresentation<SheetTag> { .sheet }
    let id = UUID()
    var onDeinit: (() -> Void)?
    nonisolated var debugDescription: String { "" }

    nonisolated init() {}

    init(
        id: UUID,
        root: Destination?,
        destinations: [Destination],
        presentation: TypedNavigatorPresentation<SheetTag>,
        tabItem: TabItemTag?,
        kind: NavigatorKind,
        tabs: [EmptyPersistentNavigator],
        selectedTab: TabItemTag?,
        child: EmptyPersistentNavigator?
    ) {}
}
