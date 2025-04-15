//
//  CustomSceneDelegate.swift
//  Example
//
//  Created by VAndrJ on 1/21/25.
//

import UIKit

final class CustomSceneDelegate: UIResponder, UIWindowSceneDelegate {

    func windowScene(
        _ windowScene: UIWindowScene,
        performActionFor shortcutItem: UIApplicationShortcutItem
    ) async -> Bool {
        return ShortcutService.shared.handleShortcut(item: shortcutItem)
    }
}
