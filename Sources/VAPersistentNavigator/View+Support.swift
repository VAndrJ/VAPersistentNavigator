//
//  View+Support.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 8/6/24.
//

import SwiftUI
import Combine

extension View {

    func synchronize<Destination: Codable & Hashable, TabItemTag: Codable & Hashable, SheetTag: Codable & Hashable>(
        _ binding: Binding<Bool>,
        with subject: CurrentValueSubject<Navigator<Destination, TabItemTag, SheetTag>?, Never>,
        isFirstAppearanceOccured: Binding<Bool>,
        isFullScreen: Bool
    ) -> some View {
        modifier(SynchronizingNavigatorPresentationViewModifier(
            binding: binding,
            isFirstAppearanceOccured: isFirstAppearanceOccured,
            subject: subject,
            isFullScreen: isFullScreen
        ))
    }

    func synchronize<T: Equatable>(
        _ binding: Binding<T>,
        with subject: CurrentValueSubject<T, Never>
    ) -> some View {
        modifier(SynchronizingViewModifier(binding: binding, subject: subject))
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

struct SynchronizingNavigatorPresentationViewModifier<
    Destination: PersistentDestination,
    TabItemTag: PersistentTabItemTag,
    SheetTag: PersistentSheetTag
>: ViewModifier {
    @Binding var binding: Bool
    @Binding var isFirstAppearanceOccured: Bool
    let subject: CurrentValueSubject<Navigator<Destination, TabItemTag, SheetTag>?, Never>
    let isFullScreen: Bool

    func body(content: Content) -> some View {
        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
            content
                .onReceive(subject) { value in
                    binding = getIsPresented(presentation: value?.presentation) && isFirstAppearanceOccured
                }
                .onChange(of: isFirstAppearanceOccured) { _, value in
                    binding = getIsPresented(presentation: subject.value?.presentation) && value
                }
                .onChange(of: binding) { _, value in
                    if !value {
                        subject.send(nil)
                    }
                }
        } else {
            content
                .onReceive(subject) { value in
                    binding = getIsPresented(presentation: value?.presentation) && isFirstAppearanceOccured
                }
                .onChange(of: isFirstAppearanceOccured) { value in
                    binding = getIsPresented(presentation: subject.value?.presentation) && value
                }
                .onChange(of: binding) { value in
                    if !value {
                        subject.send(nil)
                    }
                }
        }
    }

    private func getIsPresented(presentation: NavigatorPresentation<SheetTag>?) -> Bool {
        switch presentation {
        case .fullScreenCover: isFullScreen
        case .sheet(_): !isFullScreen
        case .none: false
        }
    }
}

extension View {

    func withDetentsIfNeeded(_ detents: (detents: Set<PresentationDetent>, dragIndicatorVisibility: Visibility)?) -> some View {
        modifier(DetentsViewModifier(detents: detents))
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
