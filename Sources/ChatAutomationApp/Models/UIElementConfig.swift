import SwiftUI

/// Represents a single labeled bounding box that the user draws on the
/// target app screenshot during configuration.
struct UIElementConfig: Identifiable, Codable {
    let id: UUID
    /// Normalized rect (0.0–1.0) relative to the screenshot dimensions.
    var rect: NormalizedRect
    var type: ElementType

    enum ElementType: String, CaseIterable, Codable {
        case entryBox      = "Entry Box"
        case submitButton  = "Submit Button"
        case messagesArea  = "Messages Area"

        var icon: String {
            switch self {
            case .entryBox:     return "pencil.line"
            case .submitButton: return "paperplane.fill"
            case .messagesArea: return "bubble.left.and.bubble.right.fill"
            }
        }

        var color: Color {
            switch self {
            case .entryBox:     return Color(hex: "#3DDC84")  // green
            case .submitButton: return Color(hex: "#F5A623")  // amber
            case .messagesArea: return Color(hex: "#6C63FF")  // accent indigo
            }
        }

        var shortLabel: String {
            switch self {
            case .entryBox:     return "Input"
            case .submitButton: return "Send"
            case .messagesArea: return "Chat"
            }
        }
    }
}

/// A rect stored as normalized [0,1] values independent of resolution.
struct NormalizedRect: Codable {
    var x, y, width, height: Double

    /// Initialize from a canvas-space CGRect, normalizing by canvasSize.
    init(_ rect: CGRect, in canvasSize: CGSize) {
        x      = rect.minX  / canvasSize.width
        y      = rect.minY  / canvasSize.height
        width  = rect.width / canvasSize.width
        height = rect.height / canvasSize.height
    }

    /// Initialize directly from pre-normalized values.
    init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x; self.y = y; self.width = width; self.height = height
    }

    /// Convert back to a CGRect given a canvas size.
    func toRect(in canvasSize: CGSize) -> CGRect {
        CGRect(
            x:      x      * canvasSize.width,
            y:      y      * canvasSize.height,
            width:  width  * canvasSize.width,
            height: height * canvasSize.height
        )
    }
}

/// The full per-app UI configuration that gets saved to disk.
struct AppUIConfig: Codable {
    var targetBundleIdentifier: String
    var elements: [UIElementConfig]

    /// Returns the config element for a given type, if it exists.
    func element(for type: UIElementConfig.ElementType) -> UIElementConfig? {
        elements.first { $0.type == type }
    }
}
