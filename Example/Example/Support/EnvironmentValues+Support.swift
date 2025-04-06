//
//  EnvironmentValues+Support.swift
//  Example
//
//  Created by VAndrJ on 4/6/25.
//

import SwiftUI
import VAPersistentNavigator

extension EnvironmentValues {
    var navigator: Navigator { persistentNavigator as! Navigator }
}
