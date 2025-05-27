//
//  Destinations.swift
//  Example
//
//  Created by VAndrJ on 30.07.2024.
//

import FeaturePackage
import Foundation
import VAPersistentNavigator

typealias Navigator = PersistentViewNavigator<Destination, TabTag, SheetTag>

enum Destination: PersistentDestination, TransitionalDestination {
    case main
    case navigationStackExamples(Int, transition: NavigatorTransition? = nil)
    case sheetExamples(Int)
    case fullScreenCoverExamples(Int, transition: NavigatorTransition? = nil)
    case tab1
    case tab2
    case shortcutExample
    case urlExample(URL)
    case notificationExample(title: String, body: String)
    case feature(FeatureDestination)
    case featurePackage(FeaturePackageDestination)
    case url(URL)

    var transition: NavigatorTransition? {
        switch self {
        case let .navigationStackExamples(_, transition),
            let .fullScreenCoverExamples(_, transition):
            transition
        default:
            nil
        }
    }
}

enum TabTag: PersistentTabItemTag {
    case first
    case second
}

enum SheetTag: PersistentSheetTag {
    case first
}

enum MessageAction {
    case review
}

extension String {
    static let auxiliaryWindowId = "auxiliary"
}
