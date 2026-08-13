//
//  GlassOverlayScaffold.swift
//  AssistanceKit
//
//  Extracted from SoundCheck/GlassOverlayScaffold.swift for cross-project reuse.
//

#if canImport(SwiftUI)
import SwiftUI
import SharedUI

/// Lightweight model for an action button in the overlay bottom bar.
public struct OverlayAction {
    public let icon: String
    public let label: String
    public let handler: () -> Void

    public init(icon: String, label: String, handler: @escaping () -> Void) {
        self.icon = icon
        self.label = label
        self.handler = handler
    }
}

// MARK: - Title Bar

/// Simple header area for overlays: title + optional subtitle, no action buttons.
public struct OverlayTitleBar: View {
    public let title: String
    public let subtitle: String?

    public init(title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    public var body: some View {
        VStack(spacing: GlassOverlayStyle.titleSpacing) {
            Text(title)
                .font(.title.bold())
                .neon(.header)
                .multilineTextAlignment(.center)

            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .neon(.subtitle)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - Bottom Bar

/// Standardized three-slot action bar: cancel (left), destructive (center), primary (right).
public struct OverlayBottomBar: View {
    public let cancelAction: OverlayAction?
    public let destructiveAction: OverlayAction?
    public let primaryAction: OverlayAction?
    public let buttonSize: CGFloat

    public init(
        cancelAction: OverlayAction? = nil,
        destructiveAction: OverlayAction? = nil,
        primaryAction: OverlayAction? = nil,
        buttonSize: CGFloat = GlassOverlayStyle.defaultButtonSize
    ) {
        self.cancelAction = cancelAction
        self.destructiveAction = destructiveAction
        self.primaryAction = primaryAction
        self.buttonSize = buttonSize
    }

    public var body: some View {
        HStack {
            if let cancel = cancelAction {
                ActionButton(systemName: cancel.icon, size: buttonSize, action: cancel.handler)
                    .accessibilityLabel(Text(cancel.label))
            } else {
                Color.clear
                    .frame(width: buttonSize, height: buttonSize)
            }

            Spacer()

            if let destructive = destructiveAction {
                ActionButton(systemName: destructive.icon, size: buttonSize, action: destructive.handler)
                    .accessibilityLabel(Text(destructive.label))
            }

            Spacer()

            if let primary = primaryAction {
                ActionButton(systemName: primary.icon, size: buttonSize, action: primary.handler)
                    .accessibilityLabel(Text(primary.label))
            } else {
                Color.clear
                    .frame(width: buttonSize, height: buttonSize)
            }
        }
        .padding(.horizontal, GlassOverlayStyle.bottomBarHorizontalPadding)
        .padding(.vertical, GlassOverlayStyle.bottomBarVerticalPadding)
    }
}

// MARK: - Glass Overlay Scaffold

/// Reusable overlay wrapper providing a dimmed backdrop, glass container, title bar,
/// bottom action bar (anchored via `safeAreaInset`), and backdrop-only tap-to-dismiss.
///
/// Keyboard avoidance: the scaffold relies on SwiftUI's default keyboard avoidance.
/// Screens that show an overlay should add `.ignoresSafeArea(.keyboard)` to their
/// background content so only the overlay layer adjusts when the keyboard appears.
public struct GlassOverlayScaffold<Content: View, Background: View>: View {
    /// Optional title displayed in the overlay header (portrait) or as rotated text
    /// on the left column (landscape). When `nil`, the title area is omitted entirely.
    public let title: String?
    public let subtitle: String?
    public let cancelAction: OverlayAction?
    public let destructiveAction: OverlayAction?
    public let primaryAction: OverlayAction?
    /// Custom handler for backdrop taps. When nil, defaults to cancel → primary fallback.
    public let onBackdropTap: (() -> Void)?
    public let background: Background
    public let content: Content

    @State private var isKeyboardVisible = false

    public init(
        title: String?,
        subtitle: String? = nil,
        cancelAction: OverlayAction? = nil,
        destructiveAction: OverlayAction? = nil,
        primaryAction: OverlayAction? = nil,
        onBackdropTap: (() -> Void)? = nil,
        @ViewBuilder background: () -> Background,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.cancelAction = cancelAction
        self.destructiveAction = destructiveAction
        self.primaryAction = primaryAction
        self.onBackdropTap = onBackdropTap
        self.background = background()
        self.content = content()
    }

    public var body: some View {
        GeometryReader { proxy in
            let isLandscape = proxy.size.width > proxy.size.height
            let base = min(proxy.size.width, proxy.size.height)
            let cornerRadius = max(
                base * GlassOverlayStyle.cornerRadiusScale,
                GlassOverlayStyle.cornerRadiusMin
            )
            let padding = max(
                base * GlassOverlayStyle.containerPaddingScale,
                GlassOverlayStyle.containerPaddingMin
            )

            ZStack {
                // Dimmed backdrop with tap-to-dismiss.
                Color.black.opacity(GlassOverlayStyle.backdropOpacity)
                    .ignoresSafeArea()
                    .onTapGesture {
                        handleBackdropTap()
                    }

                if isLandscape {
                    landscapeOverlay(
                        proxy: proxy,
                        cornerRadius: cornerRadius,
                        padding: padding
                    )
                } else {
                    portraitOverlay(
                        proxy: proxy,
                        cornerRadius: cornerRadius,
                        padding: padding
                    )
                }
            }
        }
        .transition(.opacity.combined(with: .scale))
        #if canImport(UIKit)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            isKeyboardVisible = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            isKeyboardVisible = false
        }
        #endif
    }

    // MARK: - Portrait Layout (original)

    private func portraitOverlay(
        proxy: GeometryProxy,
        cornerRadius: CGFloat,
        padding: CGFloat
    ) -> some View {
        let maxWidth = GlassOverlayStyle.containerMaxWidth
        let containerWidth = min(
            proxy.size.width * GlassOverlayStyle.containerWidthScale,
            maxWidth
        )

        return VStack(spacing: GlassOverlayStyle.portraitButtonSpacing) {
            // Glass container: title + content only (buttons live outside).
            VStack(spacing: padding) {
                if let title {
                    OverlayTitleBar(title: title, subtitle: subtitle)
                }
                content
                    .environment(\.overlayIsLandscape, false)
            }
            .padding(padding)
            .padding(GlassOverlayStyle.glowInset)
            .glassBackground(cornerRadius: cornerRadius, background: background)

            // Action buttons below the glass container.
            OverlayBottomBar(
                cancelAction: cancelAction,
                destructiveAction: destructiveAction,
                primaryAction: primaryAction,
                buttonSize: GlassOverlayStyle.defaultButtonSize
            )
        }
        .frame(width: containerWidth)
        .frame(maxHeight: proxy.size.height * GlassOverlayStyle.containerMaxHeightScale)
    }

    // MARK: - Landscape Layout (rotated title left, buttons outside right)

    private func landscapeOverlay(
        proxy: GeometryProxy,
        cornerRadius: CGFloat,
        padding: CGFloat
    ) -> some View {
        let buttonSize = GlassOverlayStyle.defaultButtonSize
        let sideButtonColumnWidth = buttonSize + GlassOverlayStyle.landscapeSideButtonPadding * 2
        let maxGlassWidth = GlassOverlayStyle.containerMaxWidthLandscape
        let availableWidth = proxy.size.width * GlassOverlayStyle.containerWidthScale - sideButtonColumnWidth
        let containerWidth = min(availableWidth, maxGlassWidth)
        let maxHeight = proxy.size.height * GlassOverlayStyle.containerMaxHeightScale

        return HStack(alignment: .center, spacing: GlassOverlayStyle.landscapeSideButtonSpacing) {
            // Glass container: rotated title on left (when present) + content on right
            HStack(spacing: 0) {
                // Rotated title (counter-clockwise) — only when title is provided
                if let title {
                    Text(title)
                        .font(.title2.bold())
                        .neon(.header)
                        .lineLimit(1)
                        .fixedSize()
                        .rotationEffect(.degrees(-90))
                        .frame(width: GlassOverlayStyle.landscapeTitleColumnWidth)
                }

                // Content area (no ScrollView — designed to fit)
                VStack(spacing: padding) {
                    content
                        .environment(\.overlayIsLandscape, true)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(padding)
                .padding(GlassOverlayStyle.glowInset)
            }
            .frame(width: containerWidth)
            .frame(maxHeight: maxHeight)
            .glassBackground(cornerRadius: cornerRadius, background: background)

            // Action buttons column (outside glass container)
            overlaySideButtons(buttonSize: buttonSize, maxHeight: maxHeight)
        }
    }

    /// Vertical column of action buttons for landscape mode: cancel top, middle center, primary bottom.
    private func overlaySideButtons(buttonSize: CGFloat, maxHeight: CGFloat) -> some View {
        VStack {
            if let cancel = cancelAction {
                ActionButton(systemName: cancel.icon, size: buttonSize, action: cancel.handler)
                    .accessibilityLabel(Text(cancel.label))
            }

            Spacer()

            if let destructive = destructiveAction {
                ActionButton(systemName: destructive.icon, size: buttonSize, action: destructive.handler)
                    .accessibilityLabel(Text(destructive.label))
            }

            Spacer()

            if let primary = primaryAction {
                ActionButton(systemName: primary.icon, size: buttonSize, action: primary.handler)
                    .accessibilityLabel(Text(primary.label))
            }
        }
        .frame(maxHeight: maxHeight)
    }

    private func dismissAction() {
        if let onBackdropTap {
            onBackdropTap()
        } else if let cancel = cancelAction {
            cancel.handler()
        } else if let primary = primaryAction {
            primary.handler()
        }
    }

    /// When the keyboard is visible, dismiss it instead of closing the overlay.
    private func handleBackdropTap() {
        #if canImport(UIKit)
        if isKeyboardVisible {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil, from: nil, for: nil
            )
        } else {
            dismissAction()
        }
        #else
        dismissAction()
        #endif
    }
}

// MARK: - Glass Background Modifier

private extension View {
    func glassBackground<B: View>(cornerRadius: CGFloat, background: B) -> some View {
        self
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.thinMaterial)
                    background
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(GlassOverlayStyle.strokeOpacity), lineWidth: GlassOverlayStyle.strokeWidth)
            )
            .shadow(
                color: .black.opacity(GlassOverlayStyle.shadowOpacity),
                radius: GlassOverlayStyle.shadowRadius,
                x: 0,
                y: GlassOverlayStyle.shadowY
            )
    }
}

// Convenience initializer when no custom background is needed.
extension GlassOverlayScaffold where Background == EmptyView {
    public init(
        title: String?,
        subtitle: String? = nil,
        cancelAction: OverlayAction? = nil,
        destructiveAction: OverlayAction? = nil,
        primaryAction: OverlayAction? = nil,
        onBackdropTap: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            title: title,
            subtitle: subtitle,
            cancelAction: cancelAction,
            destructiveAction: destructiveAction,
            primaryAction: primaryAction,
            onBackdropTap: onBackdropTap,
            background: { EmptyView() },
            content: content
        )
    }
}

// MARK: - Style Constants

/// Visual constants for GlassOverlayScaffold and related components.
public enum GlassOverlayStyle {
    /// Backdrop dimming opacity — lightened from 0.6 to 0.45 for better
    /// background visibility and less oppressive feel (SP-090).
    public static let backdropOpacity: Double = 0.45
    public static let containerWidthScale: CGFloat = 0.9
    public static let containerMaxWidth: CGFloat = 520
    /// Wider maximum in landscape to better use the horizontal space.
    public static let containerMaxWidthLandscape: CGFloat = 700
    /// Maximum height as fraction of screen height so the glass container
    /// never overflows the visible area (leaves room for safe area insets).
    public static let containerMaxHeightScale: CGFloat = 0.92
    public static let cornerRadiusScale: CGFloat = 0.04
    public static let cornerRadiusMin: CGFloat = 18
    public static let containerPaddingScale: CGFloat = 0.04
    public static let containerPaddingMin: CGFloat = 16
    /// Stroke lightened from 0.15 to 0.2 for slightly more visible border (SP-090).
    public static let strokeOpacity: Double = 0.2
    public static let strokeWidth: CGFloat = 1
    /// Shadow lightened from 0.5 to 0.35 for softer appearance (SP-090).
    public static let shadowOpacity: Double = 0.35
    public static let shadowRadius: CGFloat = 20
    public static let shadowY: CGFloat = 12
    public static let titleSpacing: CGFloat = 4
    public static let defaultButtonSize: CGFloat = 52
    public static let bottomBarHorizontalPadding: CGFloat = 24
    public static let bottomBarVerticalPadding: CGFloat = 12
    /// Extra inset inside the glass container so neon glow is not cropped by clipShape.
    public static let glowInset: CGFloat = 8

    /// Spacing between the glass container and the bottom button bar in portrait mode.
    public static let portraitButtonSpacing: CGFloat = 12

    // Landscape-specific constants
    /// Width of the rotated title column on the left side of the landscape overlay.
    public static let landscapeTitleColumnWidth: CGFloat = 40
    /// Spacing between the glass container and the side button column.
    public static let landscapeSideButtonSpacing: CGFloat = 12
    /// Padding around buttons in the side column.
    public static let landscapeSideButtonPadding: CGFloat = 4
}

#endif
