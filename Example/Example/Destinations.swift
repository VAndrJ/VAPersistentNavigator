//
//  Destinations.swift
//  Example
//
//  Created by VAndrJ on 30.07.2024.
//

import Foundation

enum Destination: Codable, Hashable {
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
}
