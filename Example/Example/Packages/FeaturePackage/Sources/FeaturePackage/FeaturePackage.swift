import SwiftUI
import VAPersistentNavigator

public enum FeaturePackageDestination: Codable, Hashable {
    case root
    case details
    case more
}

public struct FeaturePackageScreenFactoryView<OuterDestination: Codable & Hashable, TabViewTag: Codable & Hashable, SheetTag: Codable & Hashable>: View {
    let navigator: Navigator<OuterDestination, TabViewTag, SheetTag>
    let destination: FeaturePackageDestination
    let getOuterDestination: (FeaturePackageDestination) -> OuterDestination

    public init(
        navigator: Navigator<OuterDestination, TabViewTag, SheetTag>,
        destination: FeaturePackageDestination,
        getOuterDestination: @escaping (FeaturePackageDestination) -> OuterDestination
    ) {
        self.navigator = navigator
        self.destination = destination
        self.getOuterDestination = getOuterDestination
    }

    public var body: some View {
        switch destination {
        case .root:
            FeatureRootScreenView(context: .init(
                next: { navigator.push(destination: getOuterDestination(.details)) }
            ))
        case .details:
            FeatureDetailsScreenView(context: .init(
                more: { navigator.present(.init(root: getOuterDestination(.more))) }
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
            Text("Current: Some package feature flow root")
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
            Text("Current: Some package feature flow details")
                .multilineTextAlignment(.center)
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
            Text("Current: Some package feature flow presented more")
                .multilineTextAlignment(.center)
            Button("Dismiss", action: context.dismiss)
        }
    }
}
