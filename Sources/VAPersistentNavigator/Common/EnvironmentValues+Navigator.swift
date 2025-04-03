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
    typealias Tab = String
    typealias Tag = String

    var _onReplaceInitialNavigator: ((EmptyPersistentNavigator) -> Void)?
    var storeSubj: PassthroughSubject<Void, Never> { .init() }
    var destinationsSubj: CurrentValueSubject<[Destination], Never> { .init([]) }
    var parent: EmptyPersistentNavigator? { nil }
    var tabItem: Tab?
    var selectedTabSubj: CurrentValueSubject<Tab?, Never> { .init(nil) }
    var rootSubj: CurrentValueSubject<Destination?, Never> { .init(nil) }
    var childSubj: CurrentValueSubject<EmptyPersistentNavigator?, Never> { .init(nil) }
    var tabs: [EmptyPersistentNavigator] { [] }
    var kind: NavigatorKind { .singleView }
    var presentation: TypedNavigatorPresentation<Tag> { .sheet }
    let id = UUID()
    nonisolated var debugDescription: String { "" }

    nonisolated init() {}

    func getNavigator(data: NavigatorData) -> Self? {
        return nil
    }
}
