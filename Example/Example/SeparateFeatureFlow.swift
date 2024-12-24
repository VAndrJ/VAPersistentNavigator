//
//  SeparateFeatureFlow.swift
//  Example
//
//  Created by VAndrJ on 8/8/24.
//

import SwiftUI
import VAPersistentNavigator

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
    @Environment(\.persistentNavigator) var navigator: any PersistentNavigator

    var body: some View {
        VStack(spacing: 16) {
            Text("Current: Some separate feature flow root")
                .multilineTextAlignment(.center)
            Button("Next") {
                navigator.push(Destination.feature(.details))
            }
            Button("Dismiss") {
                navigator.dismissTop()
            }
        }
    }
}

struct FeatureDetailsScreenView: View {
    @Environment(\.persistentNavigator) var navigator: any PersistentNavigator

    var body: some View {
        VStack(spacing: 16) {
            Text("Current: Some separate feature flow details")
                .multilineTextAlignment(.center)
            Button("More") {
                navigator.present(.view(Destination.feature(.more)))
            }
            Button("Pop") {
                navigator.pop()
            }
        }
    }
}

struct FeatureMoreScreenView: View {
    @Environment(\.persistentNavigator) var navigator: any PersistentNavigator

    var body: some View {
        VStack(spacing: 16) {
            Text("Current: Some separate feature flow presented more")
                .multilineTextAlignment(.center)
            Button("Dismiss") {
                navigator.dismissTop()
            }
        }
    }
}
