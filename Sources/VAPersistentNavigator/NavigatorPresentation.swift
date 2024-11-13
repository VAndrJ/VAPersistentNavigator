//
//  NavigatorPresentation.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 30.07.2024.
//

import Foundation

/// Represents the presentation style of the navigator.
public enum NavigatorPresentation<SheetTag: Codable & Hashable>: Codable, Hashable {
    case sheet(tag: SheetTag? = nil)
    /// - Note: Available only on iOS 16.0, tvOS 16.0, and watchOS 9.0 and later. Not available on macOS.
    @available(iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    case fullScreenCover

    public static var sheet: NavigatorPresentation { .sheet() }

    var sheetTag: SheetTag? {
        switch self {
        case let .sheet(tag): tag
        case .fullScreenCover: nil
        }
    }
}
