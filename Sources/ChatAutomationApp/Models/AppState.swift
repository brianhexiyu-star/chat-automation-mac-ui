import SwiftUI
import CoreGraphics



/// Central shared state for the entire application.
/// Passed as an @EnvironmentObject to all views.
class AppState: ObservableObject {

    // MARK: - Mode
    enum AppMode {
        case idle       // Configuring — UI is fully interactive
        case running    // Automation active — UI locked, tabs auto-rotate
    }

    @Published var mode: AppMode = .idle

    // MARK: - Sidebar
    @Published var sidebarExpanded: Bool = false
    @Published var sidebarWidth: CGFloat = 220

    // MARK: - Target App Management
    struct TargetApp: Identifiable, Codable {
        let id: UUID
        var name: String
        var bundleIdentifier: String
        var isActive: Bool = false
    }

    // Default apps shown before any apps are running
    private let defaultApps: [TargetApp] = [
        TargetApp(id: UUID(), name: "Google Chrome", bundleIdentifier: "com.google.Chrome"),
        TargetApp(id: UUID(), name: "微信 (WeChat)", bundleIdentifier: "com.tencent.xinWeChat")
    ]

    // Dynamic: get running apps from workspace + default apps (manually added)
    @Published var targetApps: [TargetApp] = []
    @Published var manuallyAddedApps: [TargetApp] = []
    @Published var selectedAppId: UUID? = nil

    // Combined: running apps + manually added apps
    var allTargetApps: [TargetApp] {
        let runningBundleIds = Set(targetApps.map { $0.bundleIdentifier })
        
        // Running apps first, then manually added (that aren't running)
        let manuallyAddedNotRunning = manuallyAddedApps.filter { !runningBundleIds.contains($0.bundleIdentifier) }
        
        return targetApps + manuallyAddedNotRunning
    }

    // Refresh target apps from currently running applications
    // Only includes apps that have a GUI window on screen (kCGWindowLayer == 0)
    func refreshRunningApps() {
        // Get all windows on screen
        guard let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] else { return }
        
        // Filter only application windows (kCGWindowLayer == 0, excluding desktop elements)
        let appWindows = windowList.filter { window in
            guard let layer = window[kCGWindowLayer as String] as? Int32 else { return false }
            return layer == 0  // Only GUI windows
        }
        
        // Get unique PIDs that own windows
        let appsWithWindows = Set(appWindows.compactMap { $0[kCGWindowOwnerPID as String] as? Int32 })
        
        // Get running apps that have windows
        let running = NSWorkspace.shared.runningApplications
            .filter { app in
                appsWithWindows.contains(app.processIdentifier)
            }
            .compactMap { app -> TargetApp? in
                guard let bundleId = app.bundleIdentifier,
                      let name = app.localizedName else { return nil }
                return TargetApp(id: UUID(), name: name, bundleIdentifier: bundleId)
            }
        
        // Preserve isActive state from existing targetApps
        let activeBundleIds = Set(targetApps.filter { $0.isActive }.map { $0.bundleIdentifier })
        targetApps = running.map { app in
            var updated = app
            updated.isActive = activeBundleIds.contains(app.bundleIdentifier)
            return updated
        }
    }

    // Manually add a new app (saved for future sessions)
    func addManualApp(name: String, bundleIdentifier: String) {
        let newApp = TargetApp(id: UUID(), name: name, bundleIdentifier: bundleIdentifier)
        manuallyAddedApps.append(newApp)
    }

    // Remove a manually added app
    func removeManualApp(_ app: TargetApp) {
        manuallyAddedApps.removeAll { $0.id == app.id }
    }

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



    /// The bundle ID of the currently selected target app, if any.
    var selectedBundleIdentifier: String? {
        guard let id = selectedAppId else { return nil }
        return allTargetApps.first(where: { $0.id == id })?.bundleIdentifier
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
