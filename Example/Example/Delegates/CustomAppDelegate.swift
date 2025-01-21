//
//  CustomAppDelegate.swift
//  Example
//
//  Created by VAndrJ on 1/17/25.
//

import UIKit
import UserNotifications

class CustomAppDelegate: NSObject, UIApplicationDelegate, ObservableObject {

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
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound],
            completionHandler: { @Sendable _, _ in }
        )

        return sceneConfiguration
    }
}

extension CustomAppDelegate: @preconcurrency UNUserNotificationCenterDelegate {

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        NotificationService.shared.handleNotification(response: response)
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        return [.banner, .badge]
    }
}
