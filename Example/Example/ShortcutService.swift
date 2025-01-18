//
//  ShortcutService.swift
//  Example
//
//  Created by VAndrJ on 1/17/25.
//

import UIKit
import Combine

enum ShortcutItemType: String {
    case presentOnTop = "com.example.presentOnTop"
    case closeToRoot = "com.example.closeToRoot"
    case pushOnTop = "com.example.push"
}

@MainActor
final class ShortcutService {
    static let shared = ShortcutService()

    let shortcutPublisher = PassthroughSubject<ShortcutItemType, Never>()

    func handleShortcut(
        item: UIApplicationShortcutItem,
        completionHandler: ((Bool) -> Void)? = nil
    ) {
        if let shortcutItemType = ShortcutItemType(rawValue: item.type) {
            shortcutPublisher.send(shortcutItemType)
            completionHandler?(true)
        } else {
            completionHandler?(false)
        }
    }
}
