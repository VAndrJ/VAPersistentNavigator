//
//  NavigatorStoringView.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 30.07.2024.
//

import SwiftUI
import Combine

public struct NavigatorStoringView<Content, Destination: Codable & Hashable, Storage: NavigatorStorage>: View where Content: View, Storage.Destination == Destination {
    @ViewBuilder private let content: () -> Content
    @State private var bag: Set<AnyCancellable> = []

    public init<S>(
        navigator: Navigator<Destination>,
        storage: Storage,
        interval: S.SchedulerTimeType.Stride = .seconds(5),
        scheduler: S,
        options: S.SchedulerOptions? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) where S: Scheduler {
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
