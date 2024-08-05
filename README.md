# VAPersistentNavigator


[![StandWithUkraine](https://raw.githubusercontent.com/vshymanskyy/StandWithUkraine/main/badges/StandWithUkraine.svg)](https://github.com/vshymanskyy/StandWithUkraine/blob/main/docs/README.md)
[![Support Ukraine](https://img.shields.io/badge/Support-Ukraine-FFD500?style=flat&labelColor=005BBB)](https://opensource.fb.com/support-ukraine)


[![Language](https://img.shields.io/badge/language-Swift%205.10-orangered.svg?style=flat)](https://www.swift.org)
[![SPM](https://img.shields.io/badge/SPM-compatible-limegreen.svg?style=flat)](https://github.com/apple/swift-package-manager)
[![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20watchOS%20%7C%20tvOS%20%7C%20macOS%20%7C%20macCatalyst-lightgray.svg?style=flat)](https://developer.apple.com/discover)


## SwiftUI navigation with persistence.


To save the current state in applications using SwiftUI, there are various mechanisms, for example, `@SceneStorage`. However, due to the tight coupling to `View`, this complicates the possibility of separating the logic of navigation and state saving. Additionally, due to SwiftUI bugs, the built-in mechanisms do not work in some cases and lead to various issues.

For navigation, use `Navigator` with `NavigatorScreenFactoryView`, which synchronizes the state of the navigator and navigation.

To store the current navigation state, simply use any storage that implements the `NavigatorStorage` protocol. It doesn't matter if it's UserDefaults, a file, or encrypted storage. 

Wrap everything in a `NavigatorStoringView`, which will save the current navigation state whenever any changes occur.


## Example


```swift
struct WindowView<Storage: NavigatorStorage>: View where Storage.Destination == Destination {
    let navigatorStorage: Storage
    let navigator: Navigator<Destination>

    var body: some View {
        NavigatorStoringView(navigator: navigator, storage: navigatorStorage, scheduler: DispatchQueue.main) {
            NavigatorScreenFactoryView(navigator: navigator, buildView: { destination, navigator in
                switch destination {
                case .root:
                    RootView()
                case .details:
                    DetailsView()
                case .more:
                    MoreView()
                }
            })
        }
    }
}
```


## Implemented


- `push`. Using `NavigationStack`.

- `pop`.

- `popToRoot`.

- `replace(root:)`. Replaces the root view in `NavigationStack`.

- `present`. `sheet` and `fullScreenCover`.

- `dismissTop`. Dismisses the presented `sheet` or `fullScreenCover`.

- `closeToInitial`. Dismisses all presented `sheet`s and `fullScreenCover`s, and clears the initial `NavigationStack`'s navigation path.

- `onReplaceWindow`. Callback to replace the initial `View` with a new one.

- `currentTab`. Variable to get and change the current tab in `TabView`.


## TBD

- Split.

- Tests.


## Author


Volodymyr Andriienko, vandrjios@gmail.com


## License


VAPersistentNavigator is available under the MIT license. See the LICENSE file for more info.
