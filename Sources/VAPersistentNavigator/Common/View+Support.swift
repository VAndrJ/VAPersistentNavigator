//
//  View+Support.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 8/6/24.
//

import Combine
import SwiftUI

extension View {

    @ViewBuilder
    func with(navigator: any BaseNavigator) -> some View {
        switch navigator {
        case let navigator as any PersistentNavigator:
            self.environment(\.persistentNavigator, navigator)
                .environment(\.baseNavigator, navigator)
        default:
            self.environment(\.baseNavigator, navigator)
        }
    }

    func withDetentsIfNeeded(
        _ detents: (detents: Set<PresentationDetent>, dragIndicatorVisibility: Visibility)?
    ) -> some View {
        modifier(DetentsViewModifier(detents: detents))
    }

    public func synchronize<T: Equatable>(
        _ binding: Binding<T>,
        with subject: CurrentValueSubject<T, Never>
    ) -> some View {
        modifier(SynchronizingViewModifier(binding: binding, subject: subject))
    }

    public func synchronize<T: Equatable>(
        _ binding: Binding<T>,
        with subject: CurrentValueSubject<T, Never>,
        animated: CurrentValueSubject<Bool, Never>
    ) -> some View {
        modifier(AnimatedSynchronizingViewModifier(binding: binding, subject: subject, animated: animated))
    }

    public func synchronize<Navigator: BaseNavigator>(
        _ binding: Binding<Bool>,
        with subject: CurrentValueSubject<Navigator?, Never>,
        isFirstAppearanceOccured: Binding<Bool>,
        isFullScreen: Bool,
        animated: CurrentValueSubject<Bool, Never>
    ) -> some View {
        modifier(SynchronizingBaseNavigatorPresentationViewModifier(
            binding: binding,
            isFirstAppearanceOccured: isFirstAppearanceOccured,
            subject: subject,
            isFullScreen: isFullScreen,
            animated: animated
        ))
    }
}

struct DetentsViewModifier: ViewModifier {
    let detents: (detents: Set<PresentationDetent>, dragIndicatorVisibility: Visibility)?

    func body(content: Content) -> some View {
        if let detents {
            content
                .presentationDetents(detents.detents)
                .presentationDragIndicator(detents.dragIndicatorVisibility)
        } else {
            content
        }
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

struct AnimatedSynchronizingViewModifier<T: Equatable>: ViewModifier {
    @Binding var binding: T
    let subject: CurrentValueSubject<T, Never>
    let animated: CurrentValueSubject<Bool, Never>

    func body(content: Content) -> some View {
        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
            content
                .onChange(of: binding) { _, value in
                    guard subject.value != value else { return }

                    subject.send(value)
                }
                .onReceive(subject) {
                    update(value: $0)
                }
        } else {
            content
                .onChange(of: binding) { value in
                    guard subject.value != value else { return }

                    subject.send(value)
                }
                .onReceive(subject) {
                    update(value: $0)
                }
        }
    }

    private func update(value: T) {
        guard binding != value else { return }

        var transaction = Transaction()
        transaction.disablesAnimations = !animated.value
        animated.send(true)
        withTransaction(transaction) {
            binding = value
        }
    }
}

struct SynchronizingBaseNavigatorPresentationViewModifier<Navigator: BaseNavigator>: ViewModifier {
    @Binding var binding: Bool
    @Binding var isFirstAppearanceOccured: Bool
    let subject: CurrentValueSubject<Navigator?, Never>
    let isFullScreen: Bool
    let animated: CurrentValueSubject<Bool, Never>

    func body(content: Content) -> some View {
        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
            content
                .onReceive(subject) { value in
                    update(value: value, isFirstAppearanceOccured: isFirstAppearanceOccured)
                }
                .onChange(of: isFirstAppearanceOccured) { _, value in
                    update(value: subject.value, isFirstAppearanceOccured: value)
                }
                .onChange(of: binding) { _, value in
                    if !value {
                        subject.send(nil)
                    }
                }
        } else {
            content
                .onReceive(subject) { value in
                    update(value: value, isFirstAppearanceOccured: isFirstAppearanceOccured)
                }
                .onChange(of: isFirstAppearanceOccured) { value in
                    update(value: subject.value, isFirstAppearanceOccured: isFirstAppearanceOccured)
                }
                .onChange(of: binding) { value in
                    if !value {
                        subject.send(nil)
                    }
                }
        }
    }

    private func update(value: Navigator?, isFirstAppearanceOccured: Bool) {
        if isFirstAppearanceOccured {
            var transaction = Transaction()
            transaction.disablesAnimations = !animated.value
            let isPresented = getIsPresented(presentation: value?.presentation)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [animated] in
                animated.send(true)
            }
            withTransaction(transaction) {
                binding = isPresented
            }
        } else {
            binding = false
        }
    }

    private func getIsPresented(presentation: TypedNavigatorPresentation<Navigator.SheetTag>?) -> Bool {
        switch presentation {
        case .fullScreenCover: isFullScreen
        case .sheet(_): !isFullScreen
        case .none: false
        }
    }
}
