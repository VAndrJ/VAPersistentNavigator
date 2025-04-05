//
//  PersistentViewNavigator.swift
//  VAPersistentNavigator
//
//  Created by VAndrJ on 4/3/25.
//

import Foundation
import Combine

/// A typealis representing a navigator that manages navigation states and presentations and can also be persisted.
public typealias PersistentViewNavigator<
    Destination: PersistentDestination,
    TabItemTag: PersistentTabItemTag,
    SheetTag: PersistentSheetTag
> = TypedViewNavigator<Destination, TabItemTag, SheetTag>
