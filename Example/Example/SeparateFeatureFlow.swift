//
//  SeparateFeatureFlow.swift
//  Example
//
//  Created by VAndrJ on 8/8/24.
//

import SwiftUI

enum FeatureDestination: Codable, Hashable {
    case root
    case details
    case more
}

struct FeatureScreenFactoryView: View {
    let destination: FeatureDestination

    var body: some View {
        switch destination {
        case .root:
            FeatureRootScreenView()
        case .details:
            FeatureDetailsScreenView()
        case .more:
            FeatureMoreScreenView()
        }
    }
}

struct FeatureRootScreenView: View {
    @Environment(\.persistentNavigator) var navigator

    var body: some View {
        VStack(spacing: 16) {
            Text("Current: Some separate feature flow root")
                .multilineTextAlignment(.center)
            /// `NavigationLink` with a proper `PersistentDestination` can also be used.
            NavigationLink(value: Destination.feature(.details)) {
                Text("Next")
            }
            Button("More") {
                navigator.present(.view(Destination.feature(.more)))
            }
            Button("Dismiss") {
                navigator.dismissTop()
            }
        }
    }
}

struct FeatureDetailsScreenView: View {
    @Environment(\.navigator) var navigator

    var body: some View {
        VStack(spacing: 16) {
            Text("Current: Some separate feature flow details")
                .multilineTextAlignment(.center)
            Button("More") {
                navigator.present(.init(view: .feature(.more)))
            }
            Button("Pop") {
                navigator.pop()
            }
        }
    }
}

struct FeatureMoreScreenView: View {
    @Environment(\.persistentNavigator) var navigator

    var body: some View {
        VStack(spacing: 16) {
            Text("Current: Some separate feature flow presented more")
                .multilineTextAlignment(.center)
            Button("Dismiss") {
                navigator.dismissTop()
            }
            Button("Close all") {
                navigator.closeToInitial()
            }
        }
    }
}
