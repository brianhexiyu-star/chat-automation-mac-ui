import AppKit
import CoreGraphics

/// Captures a screenshot of the top-left quarter of the main screen.
/// This is the region reserved for the target app window.
enum ScreenshotService {

    /// Captures the top-left quarter of the main screen and returns it as an NSImage.
    /// Returns nil if screen recording permission is not granted.
    static func captureTopLeftQuarter() -> NSImage? {
        guard let screen = NSScreen.main else { return nil }

        let full = screen.frame           // Full screen in points (flipped: origin = bottom-left)
        let half = CGSize(width: full.width / 2, height: full.height / 2)

        // CGWindowListCreateImage uses a coordinate system where (0,0) is top-left of screen
        // So the top-left quarter starts at (0, 0) with size (half.width, half.height)
        let captureRect = CGRect(
            x: 0,
            y: 0,
            width: half.width,
            height: half.height
        )

        guard let cgImage = CGWindowListCreateImage(
            captureRect,
            .optionOnScreenOnly,
            kCGNullWindowID,
            [.bestResolution]
        ) else { return nil }

        let image = NSImage(cgImage: cgImage, size: NSSize(width: half.width, height: half.height))
        return image
    }
}
