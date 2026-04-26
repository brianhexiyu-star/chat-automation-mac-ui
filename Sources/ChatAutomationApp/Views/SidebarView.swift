import SwiftUI

/// Left sidebar — manages target app list and shows status.
struct SidebarView: View {
    @EnvironmentObject var appState: AppState
    @State private var showAddSheet = false
    @State private var newAppName = ""
    @State private var newBundleId = ""

    var body: some View {
        VStack(spacing: 0) {

            // ── Header ──────────────────────────────────────────
            HStack {
                // App Logo / Title
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
            .padding(.top, DesignSystem.Spacing.xl)
            .padding(.bottom, DesignSystem.Spacing.lg)

            // ── Section Label ────────────────────────────────────
            SectionLabel(title: "TARGET APPS")

            // ── App List ─────────────────────────────────────────
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.xs) {
                    ForEach(appState.targetApps) { app in
                        AppRowView(app: app)
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.sm)
                .padding(.vertical, DesignSystem.Spacing.xs)
            }

            Spacer()

            // ── Add Button ───────────────────────────────────────
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
            }
            .buttonStyle(.plain)
            .padding(DesignSystem.Spacing.md)
            .disabled(appState.mode == .running)

            // ── Status Footer ────────────────────────────────────
            StatusFooter()
        }
        .background(DesignSystem.Colors.backgroundSecondary)
        .sheet(isPresented: $showAddSheet) {
            AddAppSheet(isPresented: $showAddSheet)
        }
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
        .onHover { isHovered = $0 }
        .onTapGesture {
            if appState.mode == .idle {
                withAnimation(.easeInOut(duration: 0.2)) {
                    appState.selectedAppId = isSelected ? nil : app.id
                }
                if !isSelected {
                    WindowManager.shared.focusAndSnap(bundleIdentifier: app.bundleIdentifier, appState: appState)
                }
            }
        }
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
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
                    let newApp = AppState.TargetApp(id: UUID(), name: name, bundleIdentifier: bundleId)
                    appState.targetApps.append(newApp)
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
