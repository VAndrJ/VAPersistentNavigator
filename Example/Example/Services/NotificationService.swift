//
//  NotificationService.swift
//  Example
//
//  Created by VAndrJ on 1/21/25.
//

import Combine
import UIKit

struct Notification {
    let title: String
    let body: String
}

final class NotificationService {
    static let shared = NotificationService()

    let notificationPubl = PassthroughSubject<Notification, Never>()

    func handleNotification(response: UNNotificationResponse) {
        let content = response.notification.request.content
        notificationPubl.send(.init(title: content.title, body: content.body))
    }
}
