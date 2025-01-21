//
//  Operators.swift
//  Example
//
//  Created by VAndrJ on 1/21/25.
//

import Foundation

precedencegroup BackwardApplication {
    associativity: right
    higherThan: AssignmentPrecedence
}

infix operator <<| : BackwardApplication

func <<| <A, R>(_ f: @escaping (A) -> R, _ a: A) -> () -> R {
    { f(a) }
}
