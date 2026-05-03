import Foundation
import Combine
import AppKit

/// Manages the Python backend process lifecycle.
/// Launches social_bot.py as a subprocess, streams its stdout to the log panel,
/// and sends structured JSON commands via stdin.
class PythonBridge: ObservableObject {
    static let shared = PythonBridge()

    private var process: Process?
    private var stdoutPipe: Pipe?
    private var stdinPipe: Pipe?
    private var cancellables = Set<AnyCancellable>()

    private weak var appState: AppState?

    private init() {}

    func configure(appState: AppState) {
        self.appState = appState
    }

    // MARK: - Start

    /// Starts the Python backend script.
    /// - Parameters:
    ///   - scriptPath: Full path to social_bot.py
    ///   - pythonPath: Path to the python3 executable
    func start(scriptPath: String, pythonPath: String = "/usr/bin/python3") {
        guard process == nil else {
            appState?.addLog("Python backend is already running.", level: .warning)
            return
        }

        guard FileManager.default.fileExists(atPath: scriptPath) else {
            appState?.addLog("Script not found: \(scriptPath)", level: .error)
            return
        }

        let proc = Process()
        let outPipe = Pipe()
        let inPipe = Pipe()

        proc.executableURL = URL(fileURLWithPath: pythonPath)
        proc.arguments = [scriptPath, "--mode", "automate"]
        proc.standardOutput = outPipe
        proc.standardError = outPipe  // capture stderr too
        proc.standardInput = inPipe

        // Stream stdout line-by-line to the log
        outPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty,
                  let line = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !line.isEmpty else { return }

            DispatchQueue.main.async {
                self?.handlePythonOutput(line)
            }
        }

        proc.terminationHandler = { [weak self] _ in
            DispatchQueue.main.async {
                self?.appState?.addLog("Python process terminated (exit code: \(proc.terminationStatus)).",
                                       level: proc.terminationStatus == 0 ? .info : .error)
                self?.appState?.pythonRunning = false
                self?.process = nil
                self?.stdoutPipe = nil
                self?.stdinPipe = nil
            }
        }

        do {
            try proc.run()
            self.process = proc
            self.stdoutPipe = outPipe
            self.stdinPipe = inPipe
            appState?.pythonRunning = true
            appState?.addLog("Python backend started (PID: \(proc.processIdentifier)).", level: .success)
        } catch {
            appState?.addLog("Failed to start Python: \(error.localizedDescription)", level: .error)
        }
    }

    // MARK: - Stop

    func stop() {
        guard let proc = process else { return }
        sendCommand(["action": "quit"])
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            if proc.isRunning { proc.terminate() }
            self?.appState?.addLog("Python backend stopped.", level: .warning)
            self?.appState?.pythonRunning = false
            self?.process = nil
        }
    }

    // MARK: - Config UI
    
    /// Starts the standalone Python config UI script.
    func startConfigUI(bundleId: String) {
        let scriptPath = "/Users/xiyuhe/Desktop/antigravity/social_bot/config_ui.py"
        guard FileManager.default.fileExists(atPath: scriptPath) else {
            appState?.addLog("Config UI script not found at \(scriptPath)", level: .error)
            return
        }
        
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        proc.arguments = [scriptPath, bundleId]
        
        // We do not need to stream output for this standalone script, but we can capture it just in case
        let outPipe = Pipe()
        proc.standardOutput = outPipe
        proc.standardError = outPipe
        
        outPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if !data.isEmpty, let line = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !line.isEmpty {
                DispatchQueue.main.async {
                    self?.appState?.addLog("[config_ui] \(line)", level: .info)
                }
            }
        }
        
        do {
            try proc.run()
            appState?.addLog("Started Config UI for \(bundleId).", level: .success)
        } catch {
            appState?.addLog("Failed to start Config UI: \(error.localizedDescription)", level: .error)
        }
    }

    // MARK: - Send Command

    /// Sends a JSON command dictionary to the Python process via stdin.
    func sendCommand(_ command: [String: String]) {
        guard let inPipe = stdinPipe,
              let data = try? JSONSerialization.data(withJSONObject: command),
              let line = String(data: data, encoding: .utf8) else { return }
        let payload = (line + "\n").data(using: .utf8)!
        inPipe.fileHandleForWriting.write(payload)
    }

    // MARK: - Handle Python Output

    private func handlePythonOutput(_ line: String) {
        // Try to parse as structured JSON from Python
        if let data = line.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            handleStructuredOutput(json)
        } else {
            // Plain text log line
            let level: AppState.LogEntry.LogLevel = line.lowercased().contains("error") ? .error
                : line.lowercased().contains("warn") ? .warning
                : line.lowercased().contains("success") || line.lowercased().contains("done") ? .success
                : .info
            appState?.addLog("[py] \(line)", level: level)
        }
    }

    /// Handles structured JSON payloads from Python, e.g. OCR results.
    private func handleStructuredOutput(_ json: [String: Any]) {
        guard let type = json["type"] as? String else { return }

        switch type {
        case "ocr_result":
            // Expected: { "type": "ocr_result", "screenshot_path": "...", "annotations": [...] }
            handleOCRResult(json)

        case "log":
            if let message = json["message"] as? String {
                let rawLevel = json["level"] as? String ?? "info"
                let level: AppState.LogEntry.LogLevel = rawLevel == "error" ? .error
                    : rawLevel == "warning" ? .warning
                    : rawLevel == "success" ? .success
                    : .info
                appState?.addLog("[py] \(message)", level: level)
            }

        case "status":
            if let status = json["status"] as? String {
                appState?.addLog("[py] Status: \(status)", level: .info)
            }

        default:
            appState?.addLog("[py] Unknown payload type: \(type)", level: .info)
        }
    }

    private func handleOCRResult(_ json: [String: Any]) {
        // Load screenshot if a path was provided
        if let screenshotPath = json["screenshot_path"] as? String {
            let image = NSImage(contentsOfFile: screenshotPath)
            DispatchQueue.main.async { self.appState?.trackerSnapshot = image }
        }

        // Parse annotations
        if let rawAnnotations = json["annotations"] as? [[String: Any]] {
            let annotations: [AppState.TrackerAnnotation] = rawAnnotations.compactMap { raw in
                guard let x = raw["x"] as? CGFloat,
                      let y = raw["y"] as? CGFloat,
                      let w = raw["w"] as? CGFloat,
                      let h = raw["h"] as? CGFloat,
                      let label = raw["label"] as? String else { return nil }
                let rawType = raw["type"] as? String ?? "ocrText"
                let type: AppState.TrackerAnnotation.AnnotationType = rawType == "clickTarget" ? .clickTarget : .ocrText
                return AppState.TrackerAnnotation(
                    rect: CGRect(x: x, y: y, width: w, height: h),
                    label: label,
                    type: type
                )
            }
            DispatchQueue.main.async { self.appState?.trackerAnnotations = annotations }
        }

        appState?.addLog("OCR scan refreshed — \(json["annotations"] != nil ? "\((json["annotations"] as! [[String: Any]]).count)" : "0") elements detected.", level: .info)
    }
}
