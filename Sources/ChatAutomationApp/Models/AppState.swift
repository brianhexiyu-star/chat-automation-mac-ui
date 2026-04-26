import SwiftUI

/// Central shared state for the entire application.
/// Passed as an @EnvironmentObject to all views.
class AppState: ObservableObject {

    // MARK: - Mode
    enum AppMode {
        case idle       // Configuring — UI is fully interactive
        case running    // Automation active — UI locked, tabs auto-rotate
    }

    @Published var mode: AppMode = .idle

    // MARK: - Target App Management
    struct TargetApp: Identifiable, Codable {
        let id: UUID
        var name: String
        var bundleIdentifier: String
        var isActive: Bool = false
    }

    @Published var targetApps: [TargetApp] = [
        TargetApp(id: UUID(), name: "Google Chrome", bundleIdentifier: "com.google.Chrome"),
        TargetApp(id: UUID(), name: "微信 (WeChat)", bundleIdentifier: "com.tencent.xinWeChat")
    ]
    @Published var selectedAppId: UUID? = nil

    // MARK: - Tabs (right main window)
    enum Tab: String, CaseIterable {
        case logs      = "Logs"
        case editor    = "Editor"
        case config    = "Config"
        case chat      = "Chat Feed"

        var icon: String {
            switch self {
            case .logs:   return "terminal"
            case .editor: return "flowchart"
            case .config: return "slider.horizontal.3"
            case .chat:   return "bubble.left.and.bubble.right"
            }
        }
    }

    @Published var activeTab: Tab = .logs

    // MARK: - Logs
    struct LogEntry: Identifiable {
        let id = UUID()
        let timestamp: Date
        let message: String
        var level: LogLevel = .info

        enum LogLevel { case info, warning, error, success }
    }

    @Published var logs: [LogEntry] = [
        LogEntry(timestamp: Date(), message: "Application started. Ready.", level: .success),
        LogEntry(timestamp: Date(), message: "Accessibility API available.", level: .info)
    ]

    // MARK: - Vision Tracker
    @Published var trackerSnapshot: NSImage? = nil
    @Published var trackerAnnotations: [TrackerAnnotation] = []

    struct TrackerAnnotation {
        var rect: CGRect
        var label: String
        var type: AnnotationType

        enum AnnotationType { case clickTarget, ocrText }
    }

    // MARK: - Python Bridge
    @Published var pythonRunning: Bool = false

    // MARK: - Helpers
    func addLog(_ message: String, level: LogEntry.LogLevel = .info) {
        DispatchQueue.main.async {
            self.logs.append(LogEntry(timestamp: Date(), message: message, level: level))
            if self.logs.count > 500 { self.logs.removeFirst() }
        }
    }

    func startAutomation() {
        mode = .running
        addLog("Automation started.", level: .success)
    }

    func stopAutomation() {
        mode = .idle
        addLog("Automation stopped.", level: .warning)
    }
}
