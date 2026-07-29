//
//  NavigatorChildSubject.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 7/29/26.
//

import Combine

/// A current-value publisher that validates navigator hierarchy changes before publishing them.
///
/// Unlike a raw `CurrentValueSubject`, rejected child updates never become observable state.
public final class NavigatorChildSubject<Navigator: AnyObject>: Publisher {
    public typealias Output = Navigator?
    public typealias Failure = Never

    private let subject: CurrentValueSubject<Output, Failure>
    private var isValidUpdate: ((Output) -> Bool)?

    public var value: Output { subject.value }

    public init(_ value: Output) {
        self.subject = .init(value)
    }

    public func send(_ value: Output) {
        guard isValidUpdate?(value) != false else { return }

        subject.send(value)
    }

    public func receive<S: Subscriber>(subscriber: S)
    where S.Input == Output, S.Failure == Failure {
        subject.receive(subscriber: subscriber)
    }

    func validateUpdates(with isValidUpdate: @escaping (Output) -> Bool) {
        self.isValidUpdate = isValidUpdate
    }
}
