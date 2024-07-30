//
//  NavigatorTabItem.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 30.07.2024.
//

import Foundation

public struct NavigatorTabItem: Codable, Hashable {
    public var title: String
    public var image: String
    public var tag: Int

    public init(
        title: String,
        image: String,
        tag: Int
    ) {
        self.title = title
        self.image = image
        self.tag = tag
    }
}
