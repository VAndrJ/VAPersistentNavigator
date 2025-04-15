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
typealias Navigator = PersistentViewNavigator<Destination, TabTag, SheetTag>

struct WindowView: View {
    let navigatorStorage: DefaultsNavigatorStorage
    let navigator: Navigator

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


## Navigation methods


- `push`. Pushes a new `Destination` onto the `NavigationStack`.

- `pop`. Pops the top-most view off the `NavigationStack`, returning to the previous view. This is equivalent to tapping the back button in a standard navigation interface.

- `pop(to:)`. Pops to a specified `Destination` in the `NavigationStack`. Useful for skipping intermediate views and jumping directly to a particular destination.

- `popToRoot`. Pops all views off the `NavigationStack` until the root view is reached. This resets the navigation stack to the initial state.

- `replace(root:isPopToRoot:)`. Replaces the current root view in the `NavigationStack` with a new root `Destination`. Optionally, you can choose to pop to the root after replacement.

- `present`. Presents a new view as a `sheet` or `fullScreenCover`. This is used to modally display views on top of the current screen.

- `dismissTop`. Dismisses the top-most presented `sheet` or `fullScreenCover`, returning to the previous screen. This is commonly used to close modally presented views.

- `dismiss(to:)`. Dismisses presented `sheets` or `fullScreenCovers` until a specified `Destination` or `id` is reached. This allows for more controlled dismissal in cases with multiple modal presentations.

- `closeToInitial`. Dismisses all presented `sheets` and `fullScreenCovers`, and resets the initial `NavigationStack`'s navigation path to its root state. This is useful for completely resetting the navigation flow.

- `close(to:)`. Attempts to navigate to and close all modally presented views, while navigating to a specified target `Destination`. This can be used to programmatically close views and move to a specific part of the navigation flow.

- `close(where:)`. Similar to `close(to:)`, but allows for specifying a predicate to determine which `Destination` to navigate to and close. This offers more flexibility in choosing the navigation target.

- `onReplaceInitialNavigator`. A callback that is triggered when the initial `Navigator` needs to be replaced with a new one. This allows for dynamic changes in the navigator setup.

- `currentTab`. A variable that holds the current tab in a `TabView`. This allows for both getting and setting the active tab programmatically.

- `open(url:)`. Opens a given URL.


- `open(window:)`. Opens a new window with the specified identifier.


- `dismiss(window:)`. Dismisses a window with the specified identifier.


## Navigation using NavigationLink


In addition to the `Navigator`'s methods, you can also use SwiftUI's standard `NavigationLink` for navigation. This integrates seamlessly with the navigator as long as your destinations conform to `PersistentDestination` for `PersistentNavigator` or `Hashable` for `TypedNavigator`.


Example:


```
NavigationLink(value: Destination.player(file.url)) {
    FileView(file: file)
}
```


## Environment values for simplified usage


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

struct FeatureDetailsScreenView: View {
    @Environment(\.baseNavigator) var navigator

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

// If you need a concrete type of navigator

extension EnvironmentValues {
    var navigator: Navigator { persistentNavigator as! Navigator }
}

struct FeatureDetailsScreenView: View {
    @Environment(\.navigator) var navigator

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


- Description.


- Examples.


## Author


Volodymyr Andriienko, vandrjios@gmail.com


## License


VAPersistentNavigator is available under the MIT license. See the LICENSE file for more info.
