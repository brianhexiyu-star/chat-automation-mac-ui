import SwiftUI

/// Right-half main window — Sidebar + tabbed work area.
struct MainWindowView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 0) {
            // Left: Sidebar
            SidebarView()
                .frame(width: DesignSystem.sidebarWidth)

            // Divider
            Rectangle()
                .fill(DesignSystem.Colors.separator)
                .frame(width: 1)

            // Right: Tabbed main area
            VStack(spacing: 0) {
                TabBarView()
                Divider()
                    .background(DesignSystem.Colors.separator)
                TabContentView()
            }
        }
        .background(DesignSystem.Colors.backgroundPrimary)
        .preferredColorScheme(.dark)
        // Auto-rotate tabs when running
        .onReceive(
            Timer.publish(every: 4, on: .main, in: .common).autoconnect()
        ) { _ in
            if appState.mode == .running {
                rotateTab()
            }
        }
    }

    private func rotateTab() {
        let tabs = AppState.Tab.allCases
        guard let idx = tabs.firstIndex(of: appState.activeTab) else { return }
        let next = (idx + 1) % tabs.count
        withAnimation(.easeInOut(duration: 0.35)) {
            appState.activeTab = tabs[next]
        }
    }
}

// MARK: - Tab Bar
struct TabBarView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppState.Tab.allCases, id: \.self) { tab in
                TabButtonView(tab: tab)
            }

            Spacer()

            // Run / Stop Button
            RunStopButton()
                .padding(.trailing, DesignSystem.Spacing.lg)
        }
        .frame(height: 44)
        .background(DesignSystem.Colors.backgroundSecondary)
    }
}

struct TabButtonView: View {
    let tab: AppState.Tab
    @EnvironmentObject var appState: AppState
    @State private var isHovered = false

    var isSelected: Bool { appState.activeTab == tab }
    var isInteractive: Bool { appState.mode == .idle }

    var body: some View {
        Button {
            if isInteractive {
                withAnimation(.easeInOut(duration: 0.25)) {
                    appState.activeTab = tab
                }
            }
        } label: {
            VStack(spacing: 3) {
                HStack(spacing: 5) {
                    Image(systemName: tab.icon)
                        .font(.system(size: 12, weight: .medium))
                    Text(tab.rawValue)
                        .font(DesignSystem.Typography.bodyMedium)
                }
                .foregroundColor(isSelected ? DesignSystem.Colors.accent : DesignSystem.Colors.textSecondary)
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.vertical, DesignSystem.Spacing.sm)

                // Active indicator bar
                Rectangle()
                    .fill(isSelected ? DesignSystem.Colors.accent : Color.clear)
                    .frame(height: 2)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
            }
        }
        .buttonStyle(.plain)
        .background(
            isHovered && isInteractive
                ? DesignSystem.Colors.backgroundHover
                : Color.clear
        )
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .opacity(isInteractive ? 1.0 : 0.7)
    }
}

// MARK: - Run / Stop Button
struct RunStopButton: View {
    @EnvironmentObject var appState: AppState
    @State private var isHovered = false

    var isRunning: Bool { appState.mode == .running }

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isRunning ? appState.stopAutomation() : appState.startAutomation()
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: isRunning ? "stop.fill" : "play.fill")
                    .font(.system(size: 11, weight: .bold))
                Text(isRunning ? "Stop" : "Run")
                    .font(DesignSystem.Typography.bodyMedium)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.sm)
                    .fill(isRunning ? DesignSystem.Colors.accentRed : DesignSystem.Colors.accent)
                    .shadow(color: (isRunning ? DesignSystem.Colors.accentRed : DesignSystem.Colors.accent).opacity(0.4), radius: 6, y: 2)
            )
            .scaleEffect(isHovered ? 1.03 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.15), value: isHovered)
    }
}

// MARK: - Tab Content Router
struct TabContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            switch appState.activeTab {
            case .logs:   LogsTabView()
            case .editor: EditorTabView()
            case .config: ConfigTabView()
            case .chat:   ChatFeedTabView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Colors.backgroundPrimary)
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.3), value: appState.activeTab)
    }
}
