//
//  NavigationLinksExampleView.swift
//  Example
//
//  Created by VAndrJ on 4/5/25.
//

import SwiftUI

struct NavigationLinksExampleView: View {
    var body: some View {
        List {
            Text("You can also use NavigationLink to navigate to another view.")
            NavigationLink("Root1", value: Destination.root1)
            NavigationLink("Root2", value: Destination.root2)
            NavigationLink("Root3", value: Destination.root3)
            NavigationLink("Hello", value: Destination.hello)
            NavigationLink("Greeting", value: Destination.greeting)
            NavigationLink("Tab1", value: Destination.tab1)
            NavigationLink("Tab2", value: Destination.tab2)
        }
    }
}
