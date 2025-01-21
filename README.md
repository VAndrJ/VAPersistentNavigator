# VAPersistentNavigator


[![StandWithUkraine](https://raw.githubusercontent.com/vshymanskyy/StandWithUkraine/main/badges/StandWithUkraine.svg)](https://github.com/vshymanskyy/StandWithUkraine/blob/main/docs/README.md)
[![Support Ukraine](https://img.shields.io/badge/Support-Ukraine-FFD500?style=flat&labelColor=005BBB)](https://opensource.fb.com/support-ukraine)


[![Language](https://img.shields.io/badge/language-Swift%206.0-orangered.svg?style=flat)](https://www.swift.org)
[![SPM](https://img.shields.io/badge/SPM-compatible-limegreen.svg?style=flat)](https://github.com/apple/swift-package-manager)
[![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20watchOS%20%7C%20tvOS%20%7C%20macOS%20%7C%20macCatalyst-lightgray.svg?style=flat)](https://developer.apple.com/discover)


## SwiftUI navigation with persistence.


To save the current state in applications using SwiftUI, there are various mechanisms, for example, `@SceneStorage`. However, due to the tight coupling to `View`, this complicates the possibility of separating the logic of navigation and state saving. Additionally, due to SwiftUI bugs, the built-in mechanisms do not work in some cases and lead to various issues.

For navigation, use `PersistentNavigator` with `NavigatorScreenFactoryView`, which synchronizes the state of the navigator and navigation.

To store the current navigation state, simply use any storage that implements the `NavigatorStorage` protocol. It doesn't matter if it's UserDefaults, a file, or encrypted storage. 

Wrap everything in a `NavigatorStoringView`, which will save the current navigation state whenever any changes occur.


## Example


```swift
struct WindowView<Storage: NavigatorStorage>: View where Storage.Destination == Destination, Storage.TabItemTag == TabItemTag, Storage.SheetTag == SheetTag {
    let navigatorStorage: Storage
    let navigator: CodablePersistentNavigator<Destination, TabItemTag, SheetTag>

    var body: some View {
        NavigatorStoringView(navigator: navigator, storage: navigatorStorage) {
            NavigatorScreenFactoryView(
                navigator: navigator, 
                buildView: { destination, navigator in
                    switch destination {
                    case .root: RootScreenView()
                    case .details: DetailsScreenView()
                    case .more: MoreScreenView()
                    }
                },
                buildTab: { tabTag in
                    switch tabTag {
                    case .first: Label("Tab 1", systemImage: "pencil.circle")
                    case .second: Label("Tab 2", systemImage: "square.and.pencil.circle")
                    case .none: EmptyView()
                    }
                },
                getDetents: { sheetTag in
                    switch sheetTag {
                    case .first: ([.medium, .large], .visible)
                    case .none: nil
                    }
                }
            )
        }
    }
}
```


More detailed information can be found in the example project.


## Implemented


- `push`. Using `NavigationStack`.

- `pop`.

- `pop(to:)`. Pops to the specified `Destination`.

- `popToRoot`.

- `replace(root:isPopToRoot:)`. Replaces the root view in `NavigationStack`.

- `present`. `sheet` and `fullScreenCover`.

- `dismissTop`. Dismisses the presented `sheet` or `fullScreenCover`.

- `dismiss(to:)`. Dismisses presented `sheet`s or `fullScreenCover`s to specified `Destination` or `id`.

- `closeToInitial`. Dismisses all presented `sheet`s and `fullScreenCover`s, and clears the initial `NavigationStack`'s navigation path.

- `close(to:)`. Attempts to navigate to a specified target `Destination`.

- `close(where:)`. Attempts to navigate to a specified target `Destination` using predicate.

- `onReplaceInitialNavigator`. Callback to replace the initial `Navigator` with a new one.

- `currentTab`. Variable to get and change the current tab in `TabView`.


## PersistentNavigator for simplified usage


```swift
struct FeatureDetailsScreenView: View {
    @Environment(\.persistentNavigator) var navigator

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
            Button("Dismiss") {
                navigator.dismissTop()
            }
            Button("Close all") {
                navigator.closeToInitial()
            }
        }
    }
}
```


More detailed information can be found in the example project.


## TBD


- Documentation.

- Split.


## Author


Volodymyr Andriienko, vandrjios@gmail.com


## License


VAPersistentNavigator is available under the MIT license. See the LICENSE file for more info.
