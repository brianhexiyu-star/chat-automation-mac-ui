import SwiftUI
import AppKit

/// Bottom-left quarter window — shows periodic OCR snapshots with annotation overlays.
struct TrackerWindowView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            TrackerHeaderView()
            Divider().background(DesignSystem.Colors.separator)
            TrackerCanvasView()
        }
        .background(DesignSystem.Colors.backgroundPrimary)
        .preferredColorScheme(.dark)
    }
}

// MARK: - Header
struct TrackerHeaderView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "eye.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(DesignSystem.Colors.accent)

            Text("Vision Tracker")
                .font(DesignSystem.Typography.title)
                .foregroundColor(DesignSystem.Colors.textPrimary)

            Spacer()

            // OCR refresh status pill
            HStack(spacing: 5) {
                Circle()
                    .fill(appState.mode == .running ? DesignSystem.Colors.accentGreen : DesignSystem.Colors.textTertiary)
                    .frame(width: 6, height: 6)
                    .shadow(color: appState.mode == .running ? DesignSystem.Colors.accentGreen.opacity(0.7) : .clear, radius: 3)
                Text(appState.mode == .running ? "Scanning" : "Standby")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(appState.mode == .running ? DesignSystem.Colors.accentGreen : DesignSystem.Colors.textTertiary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(appState.mode == .running
                          ? DesignSystem.Colors.accentGreen.opacity(0.12)
                          : DesignSystem.Colors.backgroundTertiary)
            )

            // Annotation count badge
            if !appState.trackerAnnotations.isEmpty {
                Text("\(appState.trackerAnnotations.count) detected")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(DesignSystem.Colors.accent.opacity(0.12))
                    .cornerRadius(DesignSystem.Radius.sm)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .frame(height: 44)
        .background(DesignSystem.Colors.backgroundSecondary)
    }
}

// MARK: - Canvas (Screenshot + Annotations)
struct TrackerCanvasView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            // Background when no screenshot
            if appState.trackerSnapshot == nil {
                StandbyPlaceholderView()
            } else {
                // Screenshot image
                GeometryReader { geo in
                    if let image = appState.trackerSnapshot {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .overlay(
                                AnnotationOverlayView(
                                    annotations: appState.trackerAnnotations,
                                    imageSize: CGSize(width: image.size.width, height: image.size.height),
                                    canvasSize: geo.size
                                )
                            )
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Standby Placeholder
struct StandbyPlaceholderView: View {
    @EnvironmentObject var appState: AppState
    @State private var pulse = false

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.accent.opacity(0.08))
                    .frame(width: 80, height: 80)
                    .scaleEffect(pulse ? 1.15 : 1.0)
                    .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: pulse)

                Image(systemName: "viewfinder")
                    .font(.system(size: 36, weight: .thin))
                    .foregroundColor(DesignSystem.Colors.accent.opacity(0.5))
            }
            .onAppear { pulse = true }

            VStack(spacing: DesignSystem.Spacing.sm) {
                Text("Waiting for OCR scan")
                    .font(DesignSystem.Typography.title)
                    .foregroundColor(DesignSystem.Colors.textSecondary)

                Text(appState.selectedAppId != nil
                     ? "Press Run to start the automation."
                     : "Select a target app from the sidebar first.")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Annotation Overlay
struct AnnotationOverlayView: View {
    let annotations: [AppState.TrackerAnnotation]
    let imageSize: CGSize
    let canvasSize: CGSize

    /// Scale factor to map image coordinates to canvas coordinates
    private var scale: CGFloat {
        let scaleX = canvasSize.width / imageSize.width
        let scaleY = canvasSize.height / imageSize.height
        return min(scaleX, scaleY)
    }

    /// Offset for centering when aspect fit has letterboxing
    private var offset: CGPoint {
        let scaledW = imageSize.width * scale
        let scaledH = imageSize.height * scale
        return CGPoint(
            x: (canvasSize.width - scaledW) / 2,
            y: (canvasSize.height - scaledH) / 2
        )
    }

    var body: some View {
        Canvas { context, size in
            for annotation in annotations {
                let scaledRect = CGRect(
                    x: annotation.rect.minX * scale + offset.x,
                    y: annotation.rect.minY * scale + offset.y,
                    width: annotation.rect.width * scale,
                    height: annotation.rect.height * scale
                )

                let color: Color = annotation.type == .clickTarget
                    ? DesignSystem.Colors.accentGreen
                    : DesignSystem.Colors.accent

                // Draw bounding box
                let path = Path(roundedRect: scaledRect, cornerRadius: 3)
                context.stroke(path, with: .color(color), lineWidth: 1.5)
                context.fill(path, with: .color(color.opacity(0.08)))

                // Draw label
                let labelRect = CGRect(
                    x: scaledRect.minX,
                    y: scaledRect.minY - 18,
                    width: max(60, scaledRect.width),
                    height: 16
                )
                context.draw(
                    Text(annotation.label)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(color),
                    in: labelRect
                )
            }
        }
        .allowsHitTesting(false)
    }
}
