//
//  EnvironmentValues+Navigator.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 4/3/25.
//

import SwiftUI
import Combine

extension EnvironmentValues {
    @Entry public var baseNavigator: any BaseNavigator = emptyPersistentNavigator
    @Entry public var persistentNavigator: any PersistentNavigator = emptyPersistentNavigator

    static let emptyPersistentNavigator = EmptyPersistentNavigator()
}

final class EmptyPersistentNavigator: PersistentNavigator {
    typealias Destination = String
    typealias TabItemTag = String
    typealias Tag = String

    var childCancellable: AnyCancellable?
    var bag: Set<AnyCancellable> = []
    var _onReplaceInitialNavigator: ((EmptyPersistentNavigator) -> Void)?
    var storeSubj: PassthroughSubject<Void, Never> { .init() }
    var destinationsSubj: CurrentValueSubject<[Destination], Never> { .init([]) }
    var parent: EmptyPersistentNavigator? { nil }
    var tabItem: TabItemTag?
    var selectedTabSubj: CurrentValueSubject<TabItemTag?, Never> { .init(nil) }
    var rootSubj: CurrentValueSubject<Destination?, Never> { .init(nil) }
    var childSubj: CurrentValueSubject<EmptyPersistentNavigator?, Never> { .init(nil) }
    var tabs: [EmptyPersistentNavigator] { [] }
    var kind: NavigatorKind { .singleView }
    var presentation: TypedNavigatorPresentation<Tag> { .sheet }
    let id = UUID()
    var onDeinit: (() -> Void)?
    nonisolated var debugDescription: String { "" }

    nonisolated init() {}

    init(
        id: UUID,
        root: String?,
        destinations: [String],
        presentation: TypedNavigatorPresentation<String>,
        tabItem: String?,
        kind: NavigatorKind,
        tabs: [EmptyPersistentNavigator],
        selectedTab: String?
    ) {}
}
