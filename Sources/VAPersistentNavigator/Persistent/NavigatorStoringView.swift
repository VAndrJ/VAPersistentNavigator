//
//  NavigatorStoringView.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 30.07.2024.
//

import Combine
import SwiftUI

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
    @ViewBuilder private let content: () -> Content

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
                #if DEBUG
                    navigatorLog?("Navigation storing...")
                #endif
                storage.store(navigator: navigator)
            }
    }
}
