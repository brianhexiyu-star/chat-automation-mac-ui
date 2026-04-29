import SwiftUI
import AppKit

/// The interactive config drawing view shown inside the Tracker window.
/// Displays the top-left screenshot and lets the user draw labelled bounding boxes.
struct ConfigDrawingView: View {
    @EnvironmentObject var appState: AppState
    @State private var dragStart: CGPoint? = nil
    @State private var dragCurrent: CGPoint? = nil

    var body: some View {
        VStack(spacing: 0) {
            // ── Top Toolbar ──────────────────────────────────────
            ConfigToolbar()

            Divider().background(DesignSystem.Colors.separator)

            // ── Drawing Canvas ───────────────────────────────────
            GeometryReader { geo in
                ZStack(alignment: .topLeading) {
                    // Screenshot base image
                    if let image = appState.configSnapshot {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        Color(hex: "#1a1a1a")
                        Text("No screenshot available")
                            .foregroundColor(DesignSystem.Colors.textTertiary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }

                    // Existing boxes overlay
                    ExistingBoxesOverlay(canvasSize: geo.size)

                    // Live drawing box preview
                    if let start = dragStart, let current = dragCurrent {
                        let liveRect = rectFrom(start: start, current: current)
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(
                                appState.selectedElementType.color.opacity(0.9),
                                style: StrokeStyle(lineWidth: 2, dash: [6, 3])
                            )
                            .background(
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(appState.selectedElementType.color.opacity(0.08))
                            )
                            .frame(width: liveRect.width, height: liveRect.height)
                            .offset(x: liveRect.minX, y: liveRect.minY)
                            .allowsHitTesting(false)
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 4)
                        .onChanged { value in
                            if dragStart == nil { dragStart = value.startLocation }
                            dragCurrent = value.location
                        }
                        .onEnded { value in
                            defer {
                                dragStart = nil
                                dragCurrent = nil
                            }
                            guard let start = dragStart else { return }
                            let rawRect = rectFrom(start: start, current: value.location)
                            guard rawRect.width > 10 && rawRect.height > 10 else { return }

                            // Convert to normalized coordinates
                            let imageSize = computeImageSize(in: geo.size)
                            let imageOrigin = computeImageOrigin(in: geo.size, imageSize: imageSize)
                            let normalized = normalizeRect(rawRect, imageOrigin: imageOrigin, imageSize: imageSize)

                            // Upsert (one box per type)
                            let newElement = UIElementConfig(
                                id: UUID(),
                                rect: normalized,
                                type: appState.selectedElementType
                            )
                            appState.uiElementConfigs.removeAll { $0.type == newElement.type }
                            appState.uiElementConfigs.append(newElement)
                        }
                )
            }
        }
        .background(DesignSystem.Colors.backgroundPrimary)
        .preferredColorScheme(.dark)
    }

    // MARK: - Geometry helpers

    /// Returns a positive-size CGRect regardless of drag direction.
    private func rectFrom(start: CGPoint, current: CGPoint) -> CGRect {
        let x = min(start.x, current.x)
        let y = min(start.y, current.y)
        let w = abs(current.x - start.x)
        let h = abs(current.y - start.y)
        return CGRect(x: x, y: y, width: w, height: h)
    }

    /// Compute the actual rendered image size inside the aspect-fit container.
    private func computeImageSize(in canvasSize: CGSize) -> CGSize {
        guard let image = appState.configSnapshot else { return canvasSize }
        let imgW = image.size.width
        let imgH = image.size.height
        let scaleX = canvasSize.width  / imgW
        let scaleY = canvasSize.height / imgH
        let scale  = min(scaleX, scaleY)
        return CGSize(width: imgW * scale, height: imgH * scale)
    }

    /// Compute the top-left origin of the image inside the canvas (letterboxing offset).
    private func computeImageOrigin(in canvasSize: CGSize, imageSize: CGSize) -> CGPoint {
        CGPoint(
            x: (canvasSize.width  - imageSize.width)  / 2,
            y: (canvasSize.height - imageSize.height) / 2
        )
    }

    /// Convert a canvas-space rect to normalized [0,1] rect relative to image.
    private func normalizeRect(_ rect: CGRect, imageOrigin: CGPoint, imageSize: CGSize) -> NormalizedRect {
        let relX = (rect.minX - imageOrigin.x) / imageSize.width
        let relY = (rect.minY - imageOrigin.y) / imageSize.height
        let relW = rect.width  / imageSize.width
        let relH = rect.height / imageSize.height
        let clamped = NormalizedRect(
            CGRect(
                x: max(0, min(1, relX)),
                y: max(0, min(1, relY)),
                width:  max(0, min(1 - max(0, relX), relW)),
                height: max(0, min(1 - max(0, relY), relH))
            ),
            in: CGSize(width: 1, height: 1)   // already normalized
        )
        return clamped
    }
}

// MARK: - Config Toolbar
struct ConfigToolbar: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            // Title
            Image(systemName: "square.dashed")
                .foregroundColor(DesignSystem.Colors.accent)
            Text("Configure UI")
                .font(DesignSystem.Typography.title)
                .foregroundColor(DesignSystem.Colors.textPrimary)

            Divider()
                .frame(height: 20)
                .background(DesignSystem.Colors.separator)
                .padding(.horizontal, DesignSystem.Spacing.xs)

            // Element type selector
            HStack(spacing: DesignSystem.Spacing.xs) {
                ForEach(UIElementConfig.ElementType.allCases, id: \.self) { type in
                    ElementTypeButton(type: type)
                }
            }

            Spacer()

            // Clear all button
            Button {
                appState.uiElementConfigs.removeAll()
            } label: {
                Label("Clear", systemImage: "trash")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(DesignSystem.Colors.backgroundTertiary)
                    .cornerRadius(DesignSystem.Radius.sm)
            }
            .buttonStyle(.plain)

            // Cancel button
            Button {
                appState.exitConfigMode()
            } label: {
                Text("Cancel")
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(DesignSystem.Colors.backgroundTertiary)
                    .cornerRadius(DesignSystem.Radius.sm)
            }
            .buttonStyle(.plain)

            // Save button
            Button {
                appState.saveAndExitConfigMode()
            } label: {
                Label("Save Config", systemImage: "checkmark")
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.Radius.sm)
                            .fill(appState.uiElementConfigs.isEmpty
                                  ? DesignSystem.Colors.textTertiary
                                  : DesignSystem.Colors.accent)
                    )
            }
            .buttonStyle(.plain)
            .disabled(appState.uiElementConfigs.isEmpty)
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .frame(height: 44)
        .background(DesignSystem.Colors.backgroundSecondary)
    }
}

// MARK: - Element Type Selector Button
struct ElementTypeButton: View {
    let type: UIElementConfig.ElementType
    @EnvironmentObject var appState: AppState
    @State private var isHovered = false

    var isSelected: Bool { appState.selectedElementType == type }
    var alreadyDrawn: Bool { appState.uiElementConfigs.contains { $0.type == type } }

    var body: some View {
        Button {
            appState.selectedElementType = type
        } label: {
            HStack(spacing: 4) {
                Image(systemName: type.icon)
                    .font(.system(size: 11))
                Text(type.shortLabel)
                    .font(DesignSystem.Typography.caption)
                if alreadyDrawn {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 9))
                        .foregroundColor(type.color)
                }
            }
            .foregroundColor(isSelected ? .white : DesignSystem.Colors.textSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.sm)
                    .fill(isSelected
                          ? type.color.opacity(0.85)
                          : (isHovered ? DesignSystem.Colors.backgroundHover : DesignSystem.Colors.backgroundTertiary))
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.sm)
                    .stroke(isSelected ? type.color : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Existing Boxes Overlay
struct ExistingBoxesOverlay: View {
    let canvasSize: CGSize
    @EnvironmentObject var appState: AppState

    /// Compute displayed image size within the aspect-fit canvas.
    private var imageSize: CGSize {
        guard let image = appState.configSnapshot else { return canvasSize }
        let scaleX = canvasSize.width  / image.size.width
        let scaleY = canvasSize.height / image.size.height
        let scale  = min(scaleX, scaleY)
        return CGSize(width: image.size.width * scale, height: image.size.height * scale)
    }

    private var imageOrigin: CGPoint {
        CGPoint(
            x: (canvasSize.width  - imageSize.width)  / 2,
            y: (canvasSize.height - imageSize.height) / 2
        )
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(appState.uiElementConfigs) { element in
                let rect = element.rect.toRect(in: imageSize)
                let screenRect = CGRect(
                    x: rect.minX + imageOrigin.x,
                    y: rect.minY + imageOrigin.y,
                    width: rect.width,
                    height: rect.height
                )
                DrawnBoxView(element: element, screenRect: screenRect)
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
        .allowsHitTesting(true)
    }
}

// MARK: - Single Drawn Box
struct DrawnBoxView: View {
    let element: UIElementConfig
    let screenRect: CGRect
    @EnvironmentObject var appState: AppState
    @State private var isHovered = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Box border
            RoundedRectangle(cornerRadius: 3)
                .stroke(element.type.color, lineWidth: isHovered ? 2.5 : 1.5)
                .background(
                    RoundedRectangle(cornerRadius: 3)
                        .fill(element.type.color.opacity(isHovered ? 0.14 : 0.07))
                )
                .frame(width: screenRect.width, height: screenRect.height)

            // Label pill at top-left of the box
            HStack(spacing: 3) {
                Image(systemName: element.type.icon)
                    .font(.system(size: 9, weight: .medium))
                Text(element.type.shortLabel)
                    .font(DesignSystem.Typography.caption)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(Capsule().fill(element.type.color))
            .offset(x: 0, y: -16)

            // Delete (×) button — top-right corner, visible on hover
            if isHovered {
                Button {
                    appState.uiElementConfigs.removeAll { $0.id == element.id }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(DesignSystem.Colors.accentRed)
                        .background(Circle().fill(DesignSystem.Colors.backgroundPrimary))
                }
                .buttonStyle(.plain)
                .offset(x: screenRect.width - 10, y: -10)
            }
        }
        .offset(x: screenRect.minX, y: screenRect.minY)
        .onHover { isHovered = $0 }
    }
}
