import SwiftUI
import VAPersistentNavigator

public enum FeaturePackageDestination: Codable, Hashable {
    case root
    case details
    case more
}

public struct FeaturePackageScreenFactoryView<
    OuterDestination: PersistentDestination,
    TabViewTag: PersistentTabItemTag,
    SheetTag: PersistentSheetTag
>: View {
    let navigator: PersistentViewNavigator<OuterDestination, TabViewTag, SheetTag>
    let destination: FeaturePackageDestination
    let getOuterDestination: (FeaturePackageDestination) -> OuterDestination

    public init(
        navigator: PersistentViewNavigator<OuterDestination, TabViewTag, SheetTag>,
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
            FeatureRootScreenView(
                context: .init(
                    next: { navigator.push(destination: getOuterDestination(.details)) }
                )
            )
        case .details:
            FeatureDetailsScreenView(
                context: .init(
                    more: { navigator.present(.init(root: getOuterDestination(.more))) }
                )
            )
        case .more:
            FeatureMoreScreenView()
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
            Button("More", action: context.more)
        }
    }
}

struct FeatureMoreScreenView: View {
    @Environment(\.baseNavigator) private var navigator

    var body: some View {
        VStack(spacing: 16) {
            Text("Current: Some package feature flow presented more")
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
