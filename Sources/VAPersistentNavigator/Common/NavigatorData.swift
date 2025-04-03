//
//  NavigatorData.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 4/3/25.
//

import Foundation

public enum NavigatorData {
    case view(
        _ view: any Hashable,
        id: UUID = .init(),
        presentation: NavigatorPresentation = .sheet,
        tabItem: (any Hashable)? = nil
    )
    case stack(
        root: any Hashable,
        id: UUID = .init(),
        destinations: [any Hashable] = [],
        presentation: NavigatorPresentation = .sheet,
        tabItem: (any Hashable)? = nil
    )
    indirect case tab(
        tabs: [NavigatorData] = [],
        id: UUID = .init(),
        presentation: NavigatorPresentation = .sheet,
        selectedTab: (any Hashable)? = nil
    )
}
