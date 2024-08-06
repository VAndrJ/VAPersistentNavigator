//
//  NavigatorStoringView.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 30.07.2024.
//

import SwiftUI
import Combine

public struct NavigatorStoringView<Content, Destination: Codable & Hashable, TabItemTag: Codable & Hashable, Storage: NavigatorStorage, S: Scheduler>: View where Content: View, Storage.Destination == Destination, Storage.TabItemTag == TabItemTag {
    private let navigator: Navigator<Destination, TabItemTag>
    private let storage: Storage
    private let interval: S.SchedulerTimeType.Stride
    private let scheduler: S
    private let options: S.SchedulerOptions?
    @ViewBuilder private let content: () -> Content
    @State private var storageCancellable: AnyCancellable?

    public init(
        navigator: Navigator<Destination, TabItemTag>,
        storage: Storage,
        interval: S.SchedulerTimeType.Stride = .seconds(5),
        scheduler: S,
        options: S.SchedulerOptions? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.navigator = navigator
        self.storage = storage
        self.interval = interval
        self.scheduler = scheduler
        self.options = options
        self.content = content
    }

    public var body: some View {
        content()
            .onAppear {
                guard storageCancellable == nil else { return }

                storageCancellable = navigator.storeSubj
                    .debounce(for: interval, scheduler: scheduler, options: options)
                    .sink {
                        #if DEBUG
                        print("Navigation storing...")
                        #endif
                        storage.store(navigator: navigator)
                    }
            }
    }
}
