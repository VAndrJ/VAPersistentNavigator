//
//  NavigatorStoringView.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 30.07.2024.
//

import Combine
import SwiftUI

/// A view that observes changes to a `PersistentNavigator` and persists its state using a `NavigatorStorage`.
///
/// This view wraps content and automatically stores the navigator’s state after a specified debounce delay.
/// Pending state is also flushed when the scene enters the background or the wrapper disappears.
/// Useful for persisting navigation state across app launches.
public struct NavigatorStoringView<
    Navigator: PersistentNavigator,
    Storage: NavigatorStorage,
    S: Scheduler,
    Content: View
>: View where Storage.Navigator == Navigator {
    private let navigator: Navigator
    private let storage: Storage
    private let delay: S.SchedulerTimeType.Stride
    private let scheduler: S
    private let options: S.SchedulerOptions?
    private let content: () -> Content
    @Environment(\.scenePhase) private var scenePhase

    /// Init the view that observes changes to a `PersistentNavigator` and persists its state using a `NavigatorStorage`.
    ///
    /// This view wraps content and automatically stores the navigator’s state after a specified debounce delay.
    /// Pending state is also flushed when the scene enters the background or the wrapper disappears.
    /// Useful for persisting navigation state across app launches.
    ///
    /// - Parameters:
    ///   - navigator: The persistent navigator whose state should be tracked and stored.
    ///   - storage: The storage backend responsible for saving the navigator's state.
    ///   - delay: The debounce duration to wait before persisting changes. Defaults to 5 seconds.
    ///   - scheduler: The scheduler on which debounce timing and storage execution occurs.
    ///   - options: Optional scheduler options passed to the debounce operator.
    ///   - content: A view builder producing the content of this view.
    public init(
        navigator: Navigator,
        storage: Storage,
        delay: S.SchedulerTimeType.Stride = .seconds(5),
        options: S.SchedulerOptions? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) where S == DispatchQueue {
        self.navigator = navigator
        self.storage = storage
        self.delay = delay
        self.scheduler = DispatchQueue.main
        self.options = options
        self.content = content
    }

    public init(
        navigator: Navigator,
        storage: Storage,
        delay: S.SchedulerTimeType.Stride = .seconds(5),
        scheduler: S,
        options: S.SchedulerOptions? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.navigator = navigator
        self.storage = storage
        self.delay = delay
        self.scheduler = scheduler
        self.options = options
        self.content = content
    }

    public var body: some View {
        content()
            .onReceive(
                navigator.storeSubj
                    .prepend(())
                    .debounce(for: delay, scheduler: scheduler, options: options)
            ) {
                storeNow()
            }
            .onScenePhaseChange(scenePhase) { value in
                guard value == .background else { return }

                storeNow()
            }
            .onDisappear(perform: storeNow)
    }

    private func storeNow() {
        navigatorLog?("Navigation storing...")
        storage.store(navigator: navigator)
    }
}

private extension View {
    @ViewBuilder
    func onScenePhaseChange(_ scenePhase: ScenePhase, perform action: @escaping (ScenePhase) -> Void) -> some View {
        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
            onChange(of: scenePhase) { _, value in
                action(value)
            }
        } else {
            onChange(of: scenePhase) { value in
                action(value)
            }
        }
    }
}
