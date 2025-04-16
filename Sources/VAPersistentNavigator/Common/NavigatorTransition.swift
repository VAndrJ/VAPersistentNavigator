//
//  ZoomData.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 4/16/25.
//

import SwiftUI

/// A protocol that marks a navigation destination as eligible for zoom transitions.
///
/// Conforming types provide optional `NavigatorTransition`, which contains the necessary information
/// to participate in transition, such as `id` and `namespace` for `zoom` transition.
///
/// If `transition` is `nil`, the destination will not be included in transitions.
///
/// - Note: Because `Namespace.ID` cannot be persisted, zoom transitions are not restorable
///         from persisted navigation state and only work during the current session.
public protocol TransitionalDestination {
    var transition: NavigatorTransition? { get }
}

/// A type-erased container for representing a transition during navigation.
///
/// `NavigatorTransition` currently encapsulates optional `ZoomData`, which holds the information
/// required for performing a matched geometry effect, such as an `id` and a `Namespace.ID`.
///
/// - Important: Since `Namespace.ID` is not `Codable`, zoom transitions contained in
///   `NavigatorTransition` are not persistable and will not be restored after app relaunch
///   or state recreation.
public struct NavigatorTransition: Hashable, Codable {
    public let wrapped: ZoomData?

    public init(zoom: Namespace.ID, id: some Hashable) {
        self.wrapped = .init(id: id, namespace: zoom)
    }
}

/// A container that represents metadata used for zoom transitions.
///
/// This structure carries the `id` and `namespace` needed to link views via a matched
/// geometry effect. However, due to SwiftUI's `Namespace.ID` being non-Codable,
/// this type only formally conforms to `Codable` without actually encoding or decoding any values.
///
/// - Note: Although `ZoomData` conforms to `Codable`, its `namespace` is not persisted.
///         When decoded, the `id` is set to `nil` and `namespace` is set to `nil`.
///         As a result, zoom transitions will not be restored across launches.
public struct ZoomData: Hashable, Codable {
    public let id: AnyHashable?
    public let namespace: Namespace.ID?

    public init(id: some Hashable, namespace: Namespace.ID) {
        self.id = id
        self.namespace = namespace
    }

    public func encode(to encoder: any Encoder) throws {}

    public init(from decoder: any Decoder) throws {
        self.id = nil
        self.namespace = nil
    }
}
