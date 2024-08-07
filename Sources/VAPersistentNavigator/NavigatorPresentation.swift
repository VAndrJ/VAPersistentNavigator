//
//  NavigatorPresentation.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 30.07.2024.
//

import Foundation

/// Represents the presentation style of the navigator.
public enum NavigatorPresentation: Codable {
    case sheet
    /// - Note: Available only on iOS 16.0, tvOS 16.0, and watchOS 9.0 and later.
    @available(iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    case fullScreenCover
}
