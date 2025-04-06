//
//  NavigationLinksExampleView.swift
//  Example
//
//  Created by VAndrJ on 4/5/25.
//

import SwiftUI

struct NavigationLinksExampleScreenView: View {
    var body: some View {
        List {
            Text("You can also use NavigationLink to navigate to another view.")
            NavigationLink("Tab1", value: Destination.tab1)
            NavigationLink("Tab2", value: Destination.tab2)
        }
    }
}
