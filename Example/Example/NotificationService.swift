//
//  NotificationService.swift
//  Example
//
//  Created by VAndrJ on 1/21/25.
//

import UIKit
import Combine

struct Notification {
    let title: String
    let body: String
}

@MainActor
final class NotificationService {
    static let shared = NotificationService()

    let notificationPubl = PassthroughSubject<Notification, Never>()

    func handleNotification(response: UNNotificationResponse) {
        let content = response.notification.request.content
        notificationPubl.send(.init(title: content.title, body: content.body))
    }
}
