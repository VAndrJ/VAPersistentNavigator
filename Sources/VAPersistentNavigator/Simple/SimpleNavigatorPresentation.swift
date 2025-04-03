//
//  SimpleNavigatorPresentation.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 4/3/25.
//

public enum SimpleNavigatorPresentation {
    case sheet(tag: (any Hashable)? = nil)
    /// - Note: Available only on iOS 16.0, tvOS 16.0, and watchOS 9.0 and later. Not available on macOS.
    @available(iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    case fullScreenCover

    public static var sheet: SimpleNavigatorPresentation { .sheet() }

    var sheetTag: (any Hashable)? {
        switch self {
        case let .sheet(tag): tag
        case .fullScreenCover: nil
        }
    }
}
