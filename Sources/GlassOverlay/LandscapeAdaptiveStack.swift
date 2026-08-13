//
//  LandscapeAdaptiveStack.swift
//  AssistanceKit
//
//  Extracted from earworm-hunt-app's local landscape overlay patterns.
//  Provides a reusable two-section layout that stacks vertically in
//  portrait and side-by-side in landscape.
//

#if canImport(SwiftUI)
import SwiftUI

/// A layout container that arranges two content sections adaptively:
/// - **Portrait**: vertical stack (primary on top, secondary below)
/// - **Landscape**: horizontal stack (primary on left, secondary on right)
///
/// Landscape is detected via the ``overlayIsLandscape`` environment value
/// (set automatically by ``GlassOverlayScaffold``), falling back to
/// `verticalSizeClass == .compact` when used outside a scaffold.
///
/// ### Usage inside a GlassOverlayScaffold
/// ```swift
/// GlassOverlayScaffold(title: "Edit") {
///     LandscapeAdaptiveStack {
///         avatarCarousel
///     } secondary: {
///         VStack { nameField; settings }
///     }
/// }
/// ```
public struct LandscapeAdaptiveStack<Primary: View, Secondary: View>: View {
    @Environment(\.overlayIsLandscape) private var overlayIsLandscape
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private let portraitSpacing: CGFloat
    private let landscapeSpacing: CGFloat
    private let landscapeAlignment: VerticalAlignment
    private let primary: Primary
    private let secondary: Secondary

    /// Creates a landscape-adaptive two-section layout.
    ///
    /// - Parameters:
    ///   - portraitSpacing: Vertical spacing between sections in portrait. Default `16`.
    ///   - landscapeSpacing: Horizontal spacing between sections in landscape. Default `20`.
    ///   - landscapeAlignment: Vertical alignment of the HStack in landscape. Default `.top`.
    ///   - primary: The content shown on top (portrait) or left (landscape).
    ///   - secondary: The content shown below (portrait) or right (landscape).
    public init(
        portraitSpacing: CGFloat = 16,
        landscapeSpacing: CGFloat = 20,
        landscapeAlignment: VerticalAlignment = .top,
        @ViewBuilder primary: () -> Primary,
        @ViewBuilder secondary: () -> Secondary
    ) {
        self.portraitSpacing = portraitSpacing
        self.landscapeSpacing = landscapeSpacing
        self.landscapeAlignment = landscapeAlignment
        self.primary = primary()
        self.secondary = secondary()
    }

    /// Resolved landscape state — prefers the scaffold's environment value,
    /// falls back to vertical size class detection.
    private var isLandscape: Bool {
        overlayIsLandscape || verticalSizeClass == .compact
    }

    public var body: some View {
        if isLandscape {
            HStack(alignment: landscapeAlignment, spacing: landscapeSpacing) {
                primary
                    .frame(maxWidth: .infinity)
                secondary
                    .frame(maxWidth: .infinity)
            }
        } else {
            VStack(spacing: portraitSpacing) {
                primary
                secondary
            }
        }
    }
}

#endif
