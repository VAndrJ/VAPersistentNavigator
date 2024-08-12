//
//  Support.swift
//  Example
//
//  Created by VAndrJ on 8/12/24.
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
