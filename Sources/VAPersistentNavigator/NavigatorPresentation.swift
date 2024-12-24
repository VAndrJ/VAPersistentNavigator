//
//  NavigatorPresentation.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 30.07.2024.
//

import Foundation

public enum PersistentNavigatorPresentation {
    case sheet(tag: (any PersistentSheetTag)? = nil)
    /// - Note: Available only on iOS 16.0, tvOS 16.0, and watchOS 9.0 and later. Not available on macOS.
    @available(iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    case fullScreenCover

    public static var sheet: PersistentNavigatorPresentation { .sheet() }
}

/// Represents the presentation style of the navigator.
public enum NavigatorPresentation<SheetTag: Codable & Hashable>: Codable, Hashable {
    case sheet(tag: SheetTag? = nil)
    /// - Note: Available only on iOS 16.0, tvOS 16.0, and watchOS 9.0 and later. Not available on macOS.
    @available(iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    case fullScreenCover

    public static var sheet: NavigatorPresentation { .sheet() }

    init(from presentation: PersistentNavigatorPresentation) {
        switch presentation {
        case let .sheet(tag):
            if let tag {
                if let tag = tag as? SheetTag {
                    self = .sheet(tag: tag)
                } else {
                    assertionFailure("Tag must have only the specified `SheetTag` type.")
                    self = .sheet
                }
            } else {
                self = .sheet
            }
        case .fullScreenCover:
            self = .fullScreenCover
        }
    }

    var sheetTag: SheetTag? {
        switch self {
        case let .sheet(tag): tag
        case .fullScreenCover: nil
        }
    }
}
