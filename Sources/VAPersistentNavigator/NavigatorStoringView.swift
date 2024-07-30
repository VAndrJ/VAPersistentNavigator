//
//  NavigatorStoringView.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 30.07.2024.
//

import SwiftUI
import Combine

public struct NavigatorStoringView<Content>: View where Content: View {
    private let navigator: Navigator
    private let storage: any NavigatorStorage
    @ViewBuilder private let content: () -> Content
    @State private var bag: Set<AnyCancellable> = []

    public init<S>(
        navigator: Navigator,
        storage: any NavigatorStorage,
        interval: S.SchedulerTimeType.Stride = .seconds(5),
        scheduler: S,
        options: S.SchedulerOptions? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) where S: Scheduler {
        self.navigator = navigator
        self.storage = storage
        self.content = content

        navigator.storeSubj
            .debounce(for: interval, scheduler: scheduler)
            .sink {
                #if DEBUG
                print("Navigation storing...")
                #endif
                storage.store(navigator: navigator)
            }
            .store(in: &bag)
    }

    public var body: some View {
        content()
    }
}
