//
//  NavigatorPresentation.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 4/3/25.
//

public enum NavigatorPresentation {
    case sheet(tag: (any Hashable)? = nil)
    /// - Note: Available only on iOS 16.0, tvOS 16.0, and watchOS 9.0 and later. Not available on macOS.
    @available(iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    case fullScreenCover

    public static var sheet: NavigatorPresentation { .sheet() }

    var sheetTag: (any Hashable)? {
        switch self {
        case let .sheet(tag): tag
        case .fullScreenCover: nil
        }
    }
}

/// Represents the presentation style of the navigator.
public enum TypedNavigatorPresentation<SheetTag: Hashable>: Hashable {
    case sheet(tag: SheetTag? = nil)
    /// - Note: Available only on iOS 16.0, tvOS 16.0, and watchOS 9.0 and later. Not available on macOS.
    @available(iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    case fullScreenCover

    public static var sheet: TypedNavigatorPresentation { .sheet() }

    init(from presentation: NavigatorPresentation) {
        switch presentation {
        case let .sheet(tag):
            if let tag {
                if let tag = tag as? SheetTag {
                    self = .sheet(tag: tag)
                } else {
                    navigatorLog?("Tag must have only the specified `SheetTag` type. Found: \(type(of: tag)). Expecting: \(SheetTag.self)")
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

extension TypedNavigatorPresentation: Codable where SheetTag: Codable {}
