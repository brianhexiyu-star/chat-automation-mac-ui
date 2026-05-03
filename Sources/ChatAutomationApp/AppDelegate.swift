import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {

    var mainWindow: NSWindow?
    var trackerWindow: NSWindow?

    private let appState = AppState()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Wire up services with shared state
        PythonBridge.shared.configure(appState: appState)

        // Initial refresh of running apps
        appState.refreshRunningApps()

        guard let screen = NSScreen.main else { return }

        let screenFrame = screen.visibleFrame  // respects Dock and menu bar
        let halfW = screenFrame.width / 2
        let halfH = screenFrame.height / 2

        setupMainWindow(screenFrame: screenFrame, halfW: halfW)
        setupTrackerWindow(screenFrame: screenFrame, halfW: halfW, halfH: halfH)


        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Main Window (Right Half)
    private func setupMainWindow(screenFrame: CGRect, halfW: CGFloat) {
        let frame = NSRect(
            x: screenFrame.minX + halfW,
            y: screenFrame.minY,
            width: halfW,
            height: screenFrame.height
        )

        let window = NSWindow(
            contentRect: frame,
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.title = "Chat Automator"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.backgroundColor = NSColor(DesignSystem.Colors.backgroundPrimary)
        window.isMovableByWindowBackground = false
        window.collectionBehavior = [.canJoinAllSpaces]
        window.level = .normal

        let contentView = MainWindowView()
            .environmentObject(appState)
        window.contentView = NSHostingView(rootView: contentView)
        window.setFrameOrigin(frame.origin)
        window.makeKeyAndOrderFront(nil)
        self.mainWindow = window
    }

    // MARK: - Tracker Window (Bottom-Left Quarter)
    private func setupTrackerWindow(screenFrame: CGRect, halfW: CGFloat, halfH: CGFloat) {
        let frame = NSRect(
            x: screenFrame.minX,
            y: screenFrame.minY,
            width: halfW,
            height: halfH
        )

        let window = NSWindow(
            contentRect: frame,
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.title = "Vision Tracker"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.backgroundColor = NSColor(DesignSystem.Colors.backgroundPrimary)
        window.isMovableByWindowBackground = false
        window.collectionBehavior = [.canJoinAllSpaces]
        window.level = .normal

        let contentView = TrackerWindowView()
            .environmentObject(appState)
        window.contentView = NSHostingView(rootView: contentView)
        window.setFrameOrigin(frame.origin)
        window.orderFront(nil)
        self.trackerWindow = window
    }



    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
