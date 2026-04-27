import SwiftUI

/// Right-half main window — tabbed work area + Sidebar.
struct MainWindowView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 0) {
            // Left: Tabbed main area
            VStack(spacing: 0) {
                TabBarView()
                Divider()
                    .background(DesignSystem.Colors.separator)
                TabContentView()
            }

            // Divider
            Rectangle()
                .fill(DesignSystem.Colors.separator)
                .frame(width: 1)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let newWidth = 220 + value.translation.width
                            appState.sidebarWidth = max(50, min(400, newWidth))
                        }
                )

            // Right: Sidebar
            SidebarView()
                .frame(width: appState.sidebarExpanded ? appState.sidebarWidth : 50)
        }
        .background(DesignSystem.Colors.backgroundPrimary)
        .preferredColorScheme(.dark)
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
                appState.activeTab = tab
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
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            isHovered && isInteractive
                ? DesignSystem.Colors.backgroundHover
                : Color.clear
        )
        .onHover { isHovered = $0 }
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
            isRunning ? appState.stopAutomation() : appState.startAutomation()
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
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.15), value: isHovered)
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
    }
}
