import SwiftUI

/// Right sidebar — manages target app list and shows status.
/// Supports collapsed (icon-only) and expanded (full) modes.
struct SidebarView: View {
    @EnvironmentObject var appState: AppState
    @State private var showAddSheet = false
    @State private var newAppName = ""
    @State private var newBundleId = ""

    private var isExpanded: Bool { appState.sidebarExpanded }

    var body: some View {
        VStack(spacing: 0) {
            // Toggle button at top
            HStack {
                Spacer()
                Button {
                    appState.sidebarExpanded.toggle()
                } label: {
                    Image(systemName: isExpanded ? "chevron.right" : "chevron.left")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .frame(width: 30, height: 30)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.top, DesignSystem.Spacing.sm)

            if isExpanded {
                // Expanded: Full view
                expandedContent
            } else {
                // Collapsed: Icon-only view
                collapsedContent
            }
        }
        .background(DesignSystem.Colors.backgroundSecondary)
        .sheet(isPresented: $showAddSheet) {
            AddAppSheet(isPresented: $showAddSheet)
        }
    }

    // MARK: - Expanded Content
    private var expandedContent: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(DesignSystem.Colors.accent)
                    Text("AutoBot")
                        .font(DesignSystem.Typography.titleLarge)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
                Spacer()
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.top, DesignSystem.Spacing.md)
            .padding(.bottom, DesignSystem.Spacing.lg)

            // Section Label
            HStack {
                SectionLabel(title: "TARGET APPS")
                Spacer()
                Button {
                    appState.refreshRunningApps()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                .buttonStyle(.plain)
                .disabled(appState.mode == .running)
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)

            // App List
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.xs) {
                    ForEach(appState.allTargetApps) { app in
                        AppRowView(app: app)
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.sm)
                .padding(.vertical, DesignSystem.Spacing.xs)
            }

            Spacer()

            // Add Button
            Button {
                showAddSheet = true
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("Add Application")
                }
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.sm)
                .background(DesignSystem.Colors.backgroundTertiary)
                .cornerRadius(DesignSystem.Radius.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.sm)
                        .stroke(DesignSystem.Colors.border, lineWidth: 1)
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(DesignSystem.Spacing.md)
            .disabled(appState.mode == .running)

            // Status Footer
            StatusFooter()
        }
    }

    // MARK: - Collapsed Content (Icon Only)
    private var collapsedContent: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // App icons only
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.sm) {
                    ForEach(appState.allTargetApps) { app in
                        CollapsedAppIcon(app: app)
                    }
                }
                .padding(.vertical, DesignSystem.Spacing.sm)
            }

            Spacer()

            // Add button (icon only)
            Button {
                showAddSheet = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 14))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(DesignSystem.Colors.backgroundTertiary)
                    .cornerRadius(DesignSystem.Radius.sm)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(appState.mode == .running)
            .padding(.bottom, DesignSystem.Spacing.md)

            // Status indicator
            Circle()
                .fill(appState.mode == .running ? DesignSystem.Colors.accentGreen : DesignSystem.Colors.textTertiary)
                .frame(width: 8, height: 8)
                .padding(.bottom, DesignSystem.Spacing.lg)
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
    }
}

// MARK: - Collapsed App Icon
struct CollapsedAppIcon: View {
    let app: AppState.TargetApp
    @EnvironmentObject var appState: AppState

    private var isSelected: Bool { appState.selectedAppId == app.id }

    var body: some View {
        Button {
            if appState.mode == .idle {
                let wasNotSelected = appState.selectedAppId != app.id
                appState.selectedAppId = appState.selectedAppId == app.id ? nil : app.id
                if wasNotSelected {
                    WindowManager.shared.focusAndSnap(bundleIdentifier: app.bundleIdentifier, appState: appState)
                }
            }
        } label: {
            ZStack {
                Circle()
                    .fill(isSelected ? DesignSystem.Colors.accent.opacity(0.2) : DesignSystem.Colors.backgroundTertiary)
                    .frame(width: 36, height: 36)

                Text(String(app.name.prefix(1)))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? DesignSystem.Colors.accent : DesignSystem.Colors.textSecondary)
            }
            .frame(width: 36, height: 36)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(appState.mode == .running ? 0.7 : 1.0)
    }
}

// MARK: - App Row
struct AppRowView: View {
    let app: AppState.TargetApp
    @EnvironmentObject var appState: AppState
    @State private var isHovered = false

    var isSelected: Bool { appState.selectedAppId == app.id }

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            // Status dot
            Circle()
                .fill(app.isActive ? DesignSystem.Colors.accentGreen : DesignSystem.Colors.textTertiary)
                .frame(width: 7, height: 7)
                .shadow(color: app.isActive ? DesignSystem.Colors.accentGreen.opacity(0.6) : .clear, radius: 3)

            // App icon placeholder
            RoundedRectangle(cornerRadius: 5)
                .fill(DesignSystem.Colors.backgroundTertiary)
                .frame(width: 28, height: 28)
                .overlay(
                    Image(systemName: "app.fill")
                        .font(.system(size: 13))
                        .foregroundColor(isSelected ? DesignSystem.Colors.accent : DesignSystem.Colors.textSecondary)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(isSelected ? DesignSystem.Colors.textPrimary : DesignSystem.Colors.textSecondary)
                    .lineLimit(1)
                Text(app.isActive ? "Running" : "Idle")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(app.isActive ? DesignSystem.Colors.accentGreen : DesignSystem.Colors.textTertiary)
            }

            Spacer()
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.sm)
                .fill(isSelected
                    ? DesignSystem.Colors.accent.opacity(0.15)
                    : (isHovered ? DesignSystem.Colors.backgroundHover : Color.clear)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.sm)
                .stroke(isSelected ? DesignSystem.Colors.accent.opacity(0.4) : Color.clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .onTapGesture {
            if appState.mode == .idle {
                let wasNotSelected = appState.selectedAppId != app.id
                appState.selectedAppId = appState.selectedAppId == app.id ? nil : app.id
                if wasNotSelected {
                    WindowManager.shared.focusAndSnap(bundleIdentifier: app.bundleIdentifier, appState: appState)
                }
            }
        }
    }
}

// MARK: - Section Label
struct SectionLabel: View {
    let title: String
    var body: some View {
        HStack {
            Text(title)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textTertiary)
                .tracking(1.2)
            Spacer()
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.bottom, DesignSystem.Spacing.xs)
    }
}

// MARK: - Status Footer
struct StatusFooter: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(appState.mode == .running ? DesignSystem.Colors.accentGreen : DesignSystem.Colors.textTertiary)
                .frame(width: 8, height: 8)
                .shadow(color: appState.mode == .running ? DesignSystem.Colors.accentGreen.opacity(0.7) : .clear, radius: 4)

            Text(appState.mode == .running ? "Automation Running" : "Ready")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(appState.mode == .running ? DesignSystem.Colors.accentGreen : DesignSystem.Colors.textTertiary)

            Spacer()
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.vertical, DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.backgroundSecondary)
    }
}

// MARK: - Add App Sheet
struct AddAppSheet: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var appState: AppState
    @State private var name = ""
    @State private var bundleId = ""

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            Text("Add Target Application")
                .font(DesignSystem.Typography.titleLarge)
                .foregroundColor(DesignSystem.Colors.textPrimary)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Label("App Name", systemImage: "tag")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                TextField("e.g. Telegram", text: $name)
                    .textFieldStyle(.plain)
                    .padding(DesignSystem.Spacing.sm)
                    .background(DesignSystem.Colors.backgroundTertiary)
                    .cornerRadius(DesignSystem.Radius.sm)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Label("Bundle Identifier", systemImage: "chevron.left.forwardslash.chevron.right")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                TextField("e.g. org.telegram.desktop", text: $bundleId)
                    .textFieldStyle(.plain)
                    .font(DesignSystem.Typography.mono)
                    .padding(DesignSystem.Spacing.sm)
                    .background(DesignSystem.Colors.backgroundTertiary)
                    .cornerRadius(DesignSystem.Radius.sm)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }

            Spacer()

            HStack {
                Button("Cancel") { isPresented = false }
                    .buttonStyle(.plain)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                Spacer()
                Button("Add") {
                    guard !name.isEmpty, !bundleId.isEmpty else { return }
                    appState.addManualApp(name: name, bundleIdentifier: bundleId)
                    isPresented = false
                }
                .buttonStyle(.plain)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.sm)
                        .fill(name.isEmpty || bundleId.isEmpty ? DesignSystem.Colors.textTertiary : DesignSystem.Colors.accent)
                )
                .disabled(name.isEmpty || bundleId.isEmpty)
            }
        }
        .padding(DesignSystem.Spacing.xl)
        .frame(width: 360, height: 300)
        .background(DesignSystem.Colors.backgroundSecondary)
        .preferredColorScheme(.dark)
    }
}
