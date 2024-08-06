//
//  NavigatorTabItem.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 30.07.2024.
//

import Foundation

public struct NavigatorTabItem<Tag: Codable & Hashable>: Codable, Hashable {
    public var title: String
    public var image: String
    public var tag: Tag

    public init(
        title: String,
        image: String,
        tag: Tag
    ) {
        self.title = title
        self.image = image
        self.tag = tag
    }
}
