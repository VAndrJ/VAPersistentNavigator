//
//  Destinations.swift
//  Example
//
//  Created by VAndrJ on 30.07.2024.
//

import Foundation
import FeaturePackage
import VAPersistentNavigator

typealias Navigator = PersistentViewNavigator<Destination, TabTag, SheetTag>

enum Destination: PersistentDestination {
    case main
    case navigationStackExamples(Int)
    case sheetExamples(Int)
    case fullScreenCoverExamples(Int)
    case tab1
    case tab2
    case shortcutExample
    case notificationExample(title: String, body: String)
    case feature(FeatureDestination)
    case featurePackage(FeaturePackageDestination)
}

enum TabTag: PersistentTabItemTag {
    case first
    case second
}

enum SheetTag: PersistentSheetTag {
    case first
}
