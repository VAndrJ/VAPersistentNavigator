//
//  NavigatorLogger.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 12/24/24.
//

import Foundation
import OSLog

#if DEBUG
nonisolated(unsafe) public var navigatorLog: ((_ items: Any...) -> Void)? = navigatorLogger.log(_:)

private let navigatorLogger = Logger.navigator

extension Logger {
    static let navigator = Logger(subsystem: "VAPersistentNavigator", category: "PersistentNavigator")

    func log(_ items: Any...) {
        self.info("\(items.map { String(describing: $0) }.joined(separator: " | "), privacy: .private)")
    }
}
#else
nonisolated(unsafe) public var navigatorLog: ((_ items: Any...) -> Void)?
#endif
