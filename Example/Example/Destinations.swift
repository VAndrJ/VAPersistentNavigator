//
//  Destinations.swift
//  Example
//
//  Created by VAndrJ on 30.07.2024.
//

import Foundation

enum Destination: Codable, Hashable {
    case greeting
    case hello
    case empty
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
}

enum TabViewTag: Codable, Hashable {
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

enum SheetTag: Codable, Hashable {
    case first
}
