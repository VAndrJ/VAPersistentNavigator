//
//  View+Synchonization.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 8/6/24.
//

import SwiftUI
import Combine

extension View {

    func synchronize<Destination: Codable & Hashable>(
        _ binding: Binding<Bool>,
        with subject: CurrentValueSubject<Navigator<Destination>?, Never>,
        isAppeared: Binding<Bool>,
        presentation: NavigatorPresentation
    ) -> some View {
        self.modifier(SynchronizingNavigatorPresentationViewModifier(
            binding: binding,
            isAppeared: isAppeared,
            subject: subject,
            presentation: presentation
        ))
    }

    func synchronize<T: Equatable>(
        _ binding: Binding<T>,
        with subject: CurrentValueSubject<T, Never>
    ) -> some View {
        self.modifier(SynchronizingViewModifier(binding: binding, subject: subject))
    }
}

struct SynchronizingViewModifier<T: Equatable>: ViewModifier {
    @Binding var binding: T
    let subject: CurrentValueSubject<T, Never>

    func body(content: Content) -> some View {
        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
            content
                .onChange(of: binding) { _, value in
                    guard subject.value != value else { return }

                    subject.send(value)
                }
                .onReceive(subject) { value in
                    guard binding != value else { return }

                    binding = value
                }
        } else {
            content
                .onChange(of: binding) { value in
                    guard subject.value != value else { return }

                    subject.send(value)
                }
                .onReceive(subject) { value in
                    guard binding != value else { return }

                    binding = value
                }
        }
    }
}

struct SynchronizingNavigatorPresentationViewModifier<Destination: Codable & Hashable>: ViewModifier {
    @Binding var binding: Bool
    @Binding var isAppeared: Bool
    let subject: CurrentValueSubject<Navigator<Destination>?, Never>
    let presentation: NavigatorPresentation

    func body(content: Content) -> some View {
        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
            content
                .onReceive(subject) { value in
                    binding = value?.presentation == presentation && isAppeared
                }
                .onChange(of: isAppeared) { _, value in
                    binding = subject.value?.presentation == presentation && value
                }
                .onChange(of: binding) { _, value in
                    if !value {
                        subject.send(nil)
                    }
                }
        } else {
            content
                .onReceive(subject) { value in
                    binding = value?.presentation == presentation && isAppeared
                }
                .onChange(of: isAppeared) { value in
                    binding = subject.value?.presentation == presentation && value
                }
                .onChange(of: binding) { value in
                    if !value {
                        subject.send(nil)
                    }
                }
        }
    }
}

extension Binding where Value == Bool {

    static func && (_ lhs: Binding<Bool>, _ rhs: Binding<Bool>) -> Binding<Bool> {
        Binding<Bool>(
            get: { lhs.wrappedValue && rhs.wrappedValue },
            set: { lhs.wrappedValue = $0 }
        )
    }

    static func &&<T>(_ lhs: Binding<T?>, _ rhs: Binding<Bool>) -> Binding<Bool> {
        Binding<Bool>(
            get: { lhs.wrappedValue != nil && rhs.wrappedValue },
            set: { value in
                if !value {
                    lhs.wrappedValue = nil
                }
            }
        )
    }
}
