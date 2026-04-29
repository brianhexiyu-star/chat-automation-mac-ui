import Foundation

/// Saves and loads per-app UI element configs to/from disk.
/// Each app gets its own JSON file at:
/// ~/.chat-automator/<bundleIdentifier>_ui_config.json
enum ConfigPersistence {

    // MARK: - Directory

    private static var configDirectory: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let dir = home.appendingPathComponent(".chat-automator", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private static func configURL(for bundleIdentifier: String) -> URL {
        // Sanitize bundleId for use as a filename
        let safe = bundleIdentifier.replacingOccurrences(of: "/", with: "_")
        return configDirectory.appendingPathComponent("\(safe)_ui_config.json")
    }

    // MARK: - Save

    static func save(_ config: AppUIConfig) {
        let url = configURL(for: config.targetBundleIdentifier)
        do {
            let data = try JSONEncoder().encode(config)
            try data.write(to: url, options: .atomic)
        } catch {
            print("[ConfigPersistence] Save failed: \(error)")
        }
    }

    // MARK: - Load

    static func load(for bundleIdentifier: String) -> AppUIConfig? {
        let url = configURL(for: bundleIdentifier)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(AppUIConfig.self, from: data)
        } catch {
            print("[ConfigPersistence] Load failed: \(error)")
            return nil
        }
    }

    // MARK: - Delete

    static func delete(for bundleIdentifier: String) {
        let url = configURL(for: bundleIdentifier)
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - Check

    static func hasConfig(for bundleIdentifier: String) -> Bool {
        FileManager.default.fileExists(atPath: configURL(for: bundleIdentifier).path)
    }

    // MARK: - Export as Python-readable dict

    /// Generates a flat JSON dict readable by social_bot.py.
    /// Pixel coordinates are computed from normalized values × screen size.
    static func exportAsPixelJSON(config: AppUIConfig, screenSize: CGSize) -> String {
        var dict: [String: [String: Double]] = [:]
        for element in config.elements {
            let key: String
            switch element.type {
            case .entryBox:     key = "entry_box"
            case .submitButton: key = "submit_button"
            case .messagesArea: key = "messages_area"
            }
            dict[key] = [
                "x": element.rect.x * screenSize.width,
                "y": element.rect.y * screenSize.height,
                "w": element.rect.width * screenSize.width,
                "h": element.rect.height * screenSize.height
            ]
        }

        let wrapper: [String: Any] = [
            "target_app": config.targetBundleIdentifier,
            "screen_width": screenSize.width,
            "screen_height": screenSize.height,
            "elements": dict
        ]

        guard let data = try? JSONSerialization.data(
            withJSONObject: wrapper, options: [.prettyPrinted, .sortedKeys]
        ) else { return "{}" }

        return String(data: data, encoding: .utf8) ?? "{}"
    }
}
