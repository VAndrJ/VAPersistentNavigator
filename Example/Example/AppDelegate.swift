//
//  AppDelegate.swift
//  Example
//
//  Created by VAndrJ on 1/17/25.
//

import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        if let shortcutItem = options.shortcutItem {
            ShortcutService.shared.handleShortcut(item: shortcutItem)
        }

        let sceneConfiguration = UISceneConfiguration(
            name: "Custom Configuration",
            sessionRole: connectingSceneSession.role
        )
        sceneConfiguration.delegateClass = CustomSceneDelegate.self
        
        return sceneConfiguration
    }
}

class CustomSceneDelegate: UIResponder, UIWindowSceneDelegate {

    func windowScene(
        _ windowScene: UIWindowScene,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        ShortcutService.shared.handleShortcut(
            item: shortcutItem,
            completionHandler: completionHandler
        )
    }
}
