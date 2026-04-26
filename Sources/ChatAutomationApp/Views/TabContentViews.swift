import SwiftUI

// MARK: - Logs Tab
struct LogsTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var autoScroll = true

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Text("Execution Logs")
                    .font(DesignSystem.Typography.title)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                Spacer()
                Toggle(isOn: $autoScroll) {
                    Text("Auto-scroll")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                .toggleStyle(.switch)
                .tint(DesignSystem.Colors.accent)

                Button {
                    appState.logs.removeAll()
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(DesignSystem.Spacing.lg)

            Divider().background(DesignSystem.Colors.separator)

            // Log list
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(appState.logs) { entry in
                            LogRowView(entry: entry)
                                .id(entry.id)
                        }
                    }
                    .padding(DesignSystem.Spacing.sm)
                }
                .onChange(of: appState.logs.count) { _ in
                    if autoScroll, let last = appState.logs.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }
        }
    }
}

struct LogRowView: View {
    let entry: AppState.LogEntry

    var levelColor: Color {
        switch entry.level {
        case .info:    return DesignSystem.Colors.textSecondary
        case .success: return DesignSystem.Colors.accentGreen
        case .warning: return DesignSystem.Colors.accentAmber
        case .error:   return DesignSystem.Colors.accentRed
        }
    }

    var levelIcon: String {
        switch entry.level {
        case .info:    return "circle.fill"
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error:   return "xmark.circle.fill"
        }
    }

    var timeString: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f.string(from: entry.timestamp)
    }

    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.sm) {
            Image(systemName: levelIcon)
                .font(.system(size: 10))
                .foregroundColor(levelColor)
                .padding(.top, 2)

            Text(timeString)
                .font(DesignSystem.Typography.mono)
                .foregroundColor(DesignSystem.Colors.textTertiary)
                .frame(width: 60, alignment: .leading)

            Text(entry.message)
                .font(DesignSystem.Typography.mono)
                .foregroundColor(levelColor)
                .textSelection(.enabled)
                .lineLimit(nil)
                .multilineTextAlignment(.leading)

            Spacer()
        }
        .padding(.vertical, 3)
        .padding(.horizontal, DesignSystem.Spacing.sm)
    }
}

// MARK: - Editor Tab
struct EditorTabView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Flow Editor")
                    .font(DesignSystem.Typography.title)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                Spacer()
                Label("Beta", systemImage: "flask")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.accentAmber)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(DesignSystem.Colors.accentAmber.opacity(0.15))
                    .cornerRadius(DesignSystem.Radius.sm)
            }
            .padding(DesignSystem.Spacing.lg)

            Divider().background(DesignSystem.Colors.separator)

            // Placeholder canvas
            ZStack {
                // Grid background
                Canvas { context, size in
                    let gridSize: CGFloat = 24
                    var path = Path()
                    var x: CGFloat = 0
                    while x <= size.width {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: size.height))
                        x += gridSize
                    }
                    var y: CGFloat = 0
                    while y <= size.height {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: size.width, y: y))
                        y += gridSize
                    }
                    context.stroke(path, with: .color(DesignSystem.Colors.separator), lineWidth: 0.5)
                }

                VStack(spacing: DesignSystem.Spacing.md) {
                    Image(systemName: "flowchart")
                        .font(.system(size: 40))
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                    Text("Flow Editor — Coming Soon")
                        .font(DesignSystem.Typography.title)
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                    Text("Drag-and-drop automation steps will appear here.")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Config Tab
struct ConfigTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var interval: Double = 3.0
    @State private var ocrEnabled = true
    @State private var screenshotOnError = true
    @State private var pythonPath = "/usr/bin/python3"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xl) {

                ConfigSection(title: "Automation") {
                    ConfigRow(label: "OCR Detection", description: "Enable periodic screen text recognition") {
                        Toggle("", isOn: $ocrEnabled)
                            .toggleStyle(.switch)
                            .tint(DesignSystem.Colors.accent)
                            .labelsHidden()
                    }
                    ConfigRow(label: "OCR Interval", description: "Seconds between each screen scan") {
                        HStack {
                            Slider(value: $interval, in: 1...10, step: 0.5)
                                .tint(DesignSystem.Colors.accent)
                                .frame(width: 120)
                            Text(String(format: "%.1fs", interval))
                                .font(DesignSystem.Typography.mono)
                                .foregroundColor(DesignSystem.Colors.accent)
                                .frame(width: 36)
                        }
                    }
                    ConfigRow(label: "Screenshot on Error", description: "Save a snapshot when an error occurs") {
                        Toggle("", isOn: $screenshotOnError)
                            .toggleStyle(.switch)
                            .tint(DesignSystem.Colors.accent)
                            .labelsHidden()
                    }
                }

                ConfigSection(title: "Python Backend") {
                    ConfigRow(label: "Python Path", description: "Path to python3 executable") {
                        TextField("/usr/bin/python3", text: $pythonPath)
                            .textFieldStyle(.plain)
                            .font(DesignSystem.Typography.mono)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(DesignSystem.Colors.backgroundTertiary)
                            .cornerRadius(DesignSystem.Radius.sm)
                            .frame(width: 200)
                    }
                }

                ConfigSection(title: "Window Layout") {
                    ConfigRow(label: "Target App Region", description: "Top-left quarter reserved for the automated app") {
                        Label("Auto-managed", systemImage: "checkmark.seal.fill")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.accentGreen)
                    }
                }
            }
            .padding(DesignSystem.Spacing.xl)
        }
    }
}

struct ConfigSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.uppercased())
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textTertiary)
                .tracking(1.2)
                .padding(.bottom, DesignSystem.Spacing.sm)

            VStack(spacing: 0) {
                content
            }
            .background(DesignSystem.Colors.backgroundSecondary)
            .cornerRadius(DesignSystem.Radius.md)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.md)
                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
            )
        }
    }
}

struct ConfigRow<Control: View>: View {
    let label: String
    let description: String
    @ViewBuilder let control: Control

    var body: some View {
        HStack(alignment: .center, spacing: DesignSystem.Spacing.lg) {
            VStack(alignment: .leading, spacing: 3) {
                Text(label)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                Text(description)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            Spacer()
            control
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.vertical, DesignSystem.Spacing.md)
        Divider()
            .background(DesignSystem.Colors.separator)
            .padding(.leading, DesignSystem.Spacing.lg)
    }
}

// MARK: - Chat Feed Tab
struct ChatFeedTabView: View {
    @EnvironmentObject var appState: AppState

    // Sample placeholder data
    let mockMessages: [MockMessage] = [
        MockMessage(platform: "WeChat", sender: "Alice", preview: "Hey, are you there?", time: "14:32", unread: 2),
        MockMessage(platform: "Chrome", sender: "Bob", preview: "Check this out!", time: "14:28", unread: 0),
        MockMessage(platform: "WeChat", sender: "Team Chat", preview: "Meeting at 3pm", time: "13:55", unread: 5)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Chat Feed")
                    .font(DesignSystem.Typography.title)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                Spacer()
                Text("\(mockMessages.filter { $0.unread > 0 }.count) active")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.accentGreen)
            }
            .padding(DesignSystem.Spacing.lg)

            Divider().background(DesignSystem.Colors.separator)

            ScrollView {
                LazyVStack(spacing: DesignSystem.Spacing.xs) {
                    ForEach(mockMessages) { msg in
                        ChatRowView(message: msg)
                    }
                }
                .padding(DesignSystem.Spacing.sm)
            }
        }
    }
}

struct MockMessage: Identifiable {
    let id = UUID()
    let platform: String
    let sender: String
    let preview: String
    let time: String
    let unread: Int
}

struct ChatRowView: View {
    let message: MockMessage
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // Avatar
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.accent.opacity(0.2))
                    .frame(width: 38, height: 38)
                Text(String(message.sender.prefix(1)))
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.accent)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(message.sender)
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    Spacer()
                    Text(message.time)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                }
                HStack {
                    Text("[\(message.platform)]")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.accent)
                    Text(message.preview)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .lineLimit(1)
                    Spacer()
                    if message.unread > 0 {
                        Text("\(message.unread)")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(DesignSystem.Colors.accent)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.md)
                .fill(isHovered ? DesignSystem.Colors.backgroundHover : DesignSystem.Colors.backgroundSecondary)
        )
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.12), value: isHovered)
    }
}
