//
//  ExampleViews.swift
//  Example
//
//  Created by VAndrJ on 4/5/25.
//

import SwiftUI

struct GreetingScreenView: View {
    struct Context {
        let start: () -> Void
        let hello: () -> Void
        let nextToAssert: () -> Void
    }

    let context: Context

    var body: some View {
        VStack(spacing: 16) {
            Text("Hello, world!")
            Button("Hello", action: context.hello)
            Button("Start", action: context.start)
            Button("Next to assert", action: context.nextToAssert)
        }
        .transition(.scale)
    }
}

struct HelloScreenView: View {
    struct Context {
        let start: () -> Void
        let greeting: () -> Void
        let nextToAssert: () -> Void
    }

    let context: Context

    var body: some View {
        VStack(spacing: 16) {
            Text("Hello!")
            Button("Hello", action: context.greeting)
            Button("Start", action: context.start)
            Button("Next to assert", action: context.nextToAssert)
        }
        .transition(.scale)
    }
}

struct RootScreenView: View {
    struct Context {
        struct Related {
            let isReplacementAvailable: Bool
        }

        struct Navigation {
            let replaceRoot: () -> Void
            let replaceWindowWithTabView: () -> Void
            let next: () -> Void
            let navigationLinks: () -> Void
            let presentFeature: () -> Void
            let presentPackageFeature: () -> Void
        }

        let related: Related
        let navigation: Navigation
    }

    let context: Context

    var body: some View {
        VStack(spacing: 16) {
            Text("Current: Root")
            Button("Other root", action: context.navigation.replaceRoot)
            Button("Replace window with TabView", action: context.navigation.replaceWindowWithTabView)
                .disabled(!context.related.isReplacementAvailable)
            Button("Next", action: context.navigation.next)
            Button("NavigationLink example", action: context.navigation.navigationLinks)
            Button(#"Present "Feature""#, action: context.navigation.presentFeature)
            Button(#"Present "Package Feature""#, action: context.navigation.presentPackageFeature)
        }
        .navigationTitle("Root")
    }
}

struct Root1ScreenView: View {
    struct Context {
        let present: () -> Void
        let dismiss: () -> Void
    }

    let context: Context

    var body: some View {
        VStack(spacing: 16) {
            Text("Current: Root1")
            Button("Present", action: context.present)
            Button("Dismiss", action: context.dismiss)
        }
    }
}

struct Root2ScreenView: View {
    struct Context {
        let present: () -> Void
        let dismiss: () -> Void
    }

    let context: Context

    var body: some View {
        VStack(spacing: 16) {
            Text("Current: Root2")
            Button("Present", action: context.present)
            Button("Dismiss", action: context.dismiss)
        }
    }
}

struct Root3ScreenView: View {
    struct Context {
        let closeToInitial: () -> Void
        let closeToRoot1: () -> Void
        let dismiss: () -> Void
    }

    let context: Context

    var body: some View {
        VStack(spacing: 16) {
            Text("Current: Root3")
            Button("Close to initial", action: context.closeToInitial)
            Button("Close to root 1", action: context.closeToRoot1)
            Button("Dismiss", action: context.dismiss)
        }
    }
}

struct OtherRootScreenView: View {
    struct Context {
        let replaceRoot: () -> Void
        let navigationLinks: () -> Void
        let next: () -> Void
    }

    let context: Context

    var body: some View {
        VStack(spacing: 16) {
            Text("Current: Other Root")
            Button("Root", action: context.replaceRoot)
            Button("NavigationLink example", action: context.navigationLinks)
            Button("Next", action: context.next)
        }
        .navigationTitle("Other Root")
    }
}

struct MainScreenView: View {
    struct Context {
        let next: (Int) -> Void
    }

    let context: Context

    var body: some View {
        VStack(spacing: 16) {
            Text("Current: Main")
            Button("Next", action: context.next <<| .random(in: 0...1000))
        }
    }
}

struct DetailScreenView: View {
    struct Context {
        struct Related {
            let number: Int
            let isReplacementAvailable: Bool
            let isTabChangeAvailable: Bool
        }

        struct Navigation {
            let present: () -> Void
            let fullScreenCover: () -> Void
            let reset: () -> Void
            let presentTabs: () -> Void
            let popToMain: () -> Void
            let changeTabs: () -> Void
        }

        let related: Related
        let navigation: Navigation
    }

    let context: Context

    var body: some View {
        VStack(spacing: 16) {
            Text("Current: Detail \(context.related.number)")
            Button("Present", action: context.navigation.present)
            Button("Present full screen", action: context.navigation.fullScreenCover)
            Button("Reset navigator to root", action: context.navigation.reset)
                .disabled(!context.related.isReplacementAvailable)
            Button("Present tabs", action: context.navigation.presentTabs)
            Button("Pop to Main", action: context.navigation.popToMain)
            Button("Change tab if available", action: context.navigation.changeTabs)
                .disabled(!context.related.isTabChangeAvailable)
        }
    }
}
