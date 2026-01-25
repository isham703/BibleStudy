//
//  ThemeOverrideState.swift
//  BibleStudy
//
//  Override state for sermon theme assignments.
//  Enables user control that persists across rebuilds.
//

import Foundation

// MARK: - Theme Override State

enum ThemeOverrideState: String, Codable, Sendable {
    /// AI-assigned, can be changed on rebuild
    case auto
    /// User manually added, never auto-removed
    case userAdded
    /// User explicitly removed, never auto-added back
    case userRemoved

    /// Whether this is a user override (added or removed)
    var isUserOverride: Bool {
        self != .auto
    }

    /// Whether this theme should be visible in grouping/display
    var isVisible: Bool {
        self != .userRemoved
    }
}
