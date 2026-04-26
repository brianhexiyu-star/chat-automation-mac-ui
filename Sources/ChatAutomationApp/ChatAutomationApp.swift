import SwiftUI

@main
struct ChatAutomationApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // All windows are managed by AppDelegate for precise positioning.
        // This Settings scene is required to suppress the default SwiftUI window.
        Settings {
            EmptyView()
        }
    }
}
