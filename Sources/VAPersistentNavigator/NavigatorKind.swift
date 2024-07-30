//
//  NavigatorKind.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 30.07.2024.
//

public enum NavigatorKind: Codable {
    case flow
    case tabView

    public var isTabView: Bool { self == .tabView }
}
