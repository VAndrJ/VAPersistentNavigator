//
//  ShortcutService.swift
//  Example
//
//  Created by VAndrJ on 1/17/25.
//

import Combine
import UIKit

enum ShortcutItemType: String {
    case presentOnTop = "com.example.presentOnTop"
    case closeToRoot = "com.example.closeToRoot"
    case pushOnTop = "com.example.push"
}

@MainActor
final class ShortcutService {
    static let shared = ShortcutService()

    let shortcutPubl = PassthroughSubject<ShortcutItemType, Never>()

    @discardableResult
    func handleShortcut(item: UIApplicationShortcutItem) -> Bool {
        if let shortcutItemType = ShortcutItemType(rawValue: item.type) {
            shortcutPubl.send(shortcutItemType)

            return true
        } else {
            return false
        }
    }
}
