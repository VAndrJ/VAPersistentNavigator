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
    let navigator: Navigator<Destination, TabTag, SheetTag>
    let destination: FeatureDestination

    var body: some View {
        switch destination {
        case .root:
            FeatureRootScreenView(context: .init(
                next: { navigator.push(destination: .feature(.details)) }
            ))
        case .details:
            FeatureDetailsScreenView(context: .init(
                more: { navigator.present(.init(root: .feature(.more))) }
            ))
        case .more:
            FeatureMoreScreenView(context: .init(
                dismiss: { navigator.dismissTop() }
            ))
        }
    }
}

struct FeatureRootScreenView: View {
    struct Context {
        let next: () -> Void
    }

    let context: Context

    var body: some View {
        VStack(spacing: 16) {
            Text("Current: Some separate feature flow root")
                .multilineTextAlignment(.center)
            Button("Next", action: context.next)
        }
    }
}

struct FeatureDetailsScreenView: View {
    struct Context {
        let more: () -> Void
    }

    let context: Context

    var body: some View {
        VStack(spacing: 16) {
            Text("Current: Some separate feature flow details")
                .multilineTextAlignment(.center)
            Button("More", action: context.more)
        }
    }
}

struct FeatureMoreScreenView: View {
    struct Context {
        let dismiss: () -> Void
    }

    let context: Context

    var body: some View {
        VStack(spacing: 16) {
            Text("Current: Some separate feature flow presented more")
                .multilineTextAlignment(.center)
            Button("Dismiss", action: context.dismiss)
        }
    }
}
