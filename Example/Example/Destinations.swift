//
//  Destinations.swift
//  Example
//
//  Created by VAndrJ on 30.07.2024.
//

import Foundation
import FeaturePackage
import VAPersistentNavigator

enum Destination: PersistentDestination {
    case greeting
    case hello
    case root
    case root1
    case root2
    case root3
    case otherRoot
    case tab1
    case tab2
    case main
    case detail(number: Int)
    case feature(FeatureDestination)
    case featurePackage(FeaturePackageDestination)
}

enum TabTag: PersistentTabItemTag {
    enum FirstTabView: Codable, Hashable {
        case first
        case second
    }

    enum SecondTabView: Codable, Hashable {
        case first
        case second
    }

    case first(FirstTabView)
    case second(SecondTabView)
}

enum SheetTag: PersistentSheetTag {
    case first
}
