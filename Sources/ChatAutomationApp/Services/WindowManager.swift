import Cocoa
import ApplicationServices

/// Manages target application windows using macOS Accessibility APIs.
/// Finds, moves, and resizes third-party app windows to the top-left quarter.
class WindowManager {
    static let shared = WindowManager()

    private init() {}

    /// Move and resize the target app's main window to the top-left quarter of the screen.
    func focusAndSnap(bundleIdentifier: String, appState: AppState) {
        guard AXIsProcessTrusted() else {
            appState.addLog("⚠️ Accessibility permission not granted. Please enable in System Preferences > Privacy & Security > Accessibility.", level: .warning)
            promptAccessibilityPermission()
            return
        }

        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let targetFrame = CGRect(
            x: screenFrame.minX,
            y: screenFrame.minY + screenFrame.height / 2,
            width: screenFrame.width / 2,
            height: screenFrame.height / 2
        )

        DispatchQueue.global(qos: .userInitiated).async {
            if let app = NSWorkspace.shared.runningApplications.first(where: {
                $0.bundleIdentifier == bundleIdentifier
            }) {
                app.activate(options: .activateIgnoringOtherApps)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.setWindowFrame(pid: app.processIdentifier, frame: targetFrame, appState: appState)
                }
            } else {
                appState.addLog("App with bundle ID \"\(bundleIdentifier)\" is not running.", level: .warning)
            }
        }
    }

    private func setWindowFrame(pid: pid_t, frame: CGRect, appState: AppState) {
        let axApp = AXUIElementCreateApplication(pid)

        var windowsRef: AnyObject?
        let result = AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &windowsRef)

        guard result == .success,
              let windows = windowsRef as? [AXUIElement],
              let window = windows.first else {
            appState.addLog("Could not access window for this application.", level: .error)
            return
        }

        // Set position
        var position = CGPoint(x: frame.origin.x, y: frame.origin.y)
        if let positionValue = AXValueCreate(.cgPoint, &position) {
            AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, positionValue)
        }

        // Set size
        var size = CGSize(width: frame.width, height: frame.height)
        if let sizeValue = AXValueCreate(.cgSize, &size) {
            AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
        }

        appState.addLog("Snapped window to top-left quarter.", level: .success)

        // Mark app as active in state
        DispatchQueue.main.async {
            if let idx = appState.targetApps.firstIndex(where: { $0.bundleIdentifier == appState.targetApps.first?.bundleIdentifier }) {
                appState.targetApps[idx].isActive = true
            }
        }
    }

    /// Prompt user to grant Accessibility permissions in System Preferences.
    private func promptAccessibilityPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: true]
        AXIsProcessTrustedWithOptions(options)
    }
}
