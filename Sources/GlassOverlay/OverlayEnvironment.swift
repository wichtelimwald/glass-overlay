//
//  OverlayEnvironment.swift
//  AssistanceKit
//
//  Environment keys shared by `GlassOverlayScaffold` and its content views.
//

#if canImport(SwiftUI)
import SwiftUI

// MARK: - Overlay Is Landscape

/// Environment key indicating whether the enclosing `GlassOverlayScaffold`
/// is currently in landscape orientation.
///
/// Set automatically by the scaffold; content views can read it to adapt
/// their layout without adding their own orientation-detection boilerplate.
///
/// ```swift
/// @Environment(\.overlayIsLandscape) private var isLandscape
/// ```
/// Environment key for `overlayIsLandscape`.
/// Defaults to `false` so views used outside a scaffold context (e.g.
/// in previews or standalone) assume portrait layout.
private struct OverlayIsLandscapeKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// `true` when the enclosing ``GlassOverlayScaffold`` is laid out in
    /// landscape orientation.
    ///
    /// Falls back to `false` when read outside a scaffold.
    public var overlayIsLandscape: Bool {
        get { self[OverlayIsLandscapeKey.self] }
        set { self[OverlayIsLandscapeKey.self] = newValue }
    }
}

#endif
