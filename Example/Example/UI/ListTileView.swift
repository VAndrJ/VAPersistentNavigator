//
//  ListTileView.swift
//  Example
//
//  Created by VAndrJ on 4/13/25.
//

import SwiftUI

struct ListTileView: View {
    enum Style: String {
        case forward = "chevron.forward"
        case backward = "chevron.backward"
        case replace = "gobackward"
        case apple = "apple.logo"
        case settings = "gear"
        case openWindow = "window.casement"
    }

    let title: String
    var style: Style = .forward
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: style.rawValue)
            }
        }
    }
}
