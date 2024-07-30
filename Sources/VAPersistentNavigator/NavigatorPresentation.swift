//
//  NavigatorPresentation.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 30.07.2024.
//

import Foundation

public enum NavigatorPresentation: Codable {
    case sheet
    @available(iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    case fullScreenCover
}
