import Foundation

enum DailyWallpaperScheduler {
    static let label = "com.xian.BingWallpaperSwitcher.daily"

    static var plistURL: URL {
        FileManager.default
            .homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents", isDirectory: true)
            .appendingPathComponent("\(label).plist", isDirectory: false)
    }

    static func isInstalled() -> Bool {
        FileManager.default.fileExists(atPath: plistURL.path)
    }

    static func install(appBundleURL: URL) throws {
        let agentURL = appBundleURL
            .appendingPathComponent("Contents", isDirectory: true)
            .appendingPathComponent("MacOS", isDirectory: true)
            .appendingPathComponent("BingWallpaperAgent", isDirectory: false)

        guard FileManager.default.fileExists(atPath: agentURL.path) else {
            throw SchedulerError.missingAgent(agentURL.path)
        }

        try FileManager.default.createDirectory(
            at: plistURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        try launchctl(["bootout", domain, plistURL.path], allowsFailure: true)
        try plist(agentPath: agentURL.path).write(to: plistURL, atomically: true, encoding: .utf8)
        try launchctl(["bootstrap", domain, plistURL.path], allowsFailure: false)
    }

    static func uninstall() throws {
        try launchctl(["bootout", domain, plistURL.path], allowsFailure: true)
        if FileManager.default.fileExists(atPath: plistURL.path) {
            try FileManager.default.removeItem(at: plistURL)
        }
    }

    private static var domain: String {
        "gui/\(getuid())"
    }

    private static func launchctl(_ arguments: [String], allowsFailure: Bool) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = arguments

        let errorPipe = Pipe()
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 || allowsFailure else {
            let data = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let message = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            throw SchedulerError.launchctl(message ?? "launchctl failed")
        }
    }

    private static func plist(agentPath: String) -> String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
          <key>Label</key>
          <string>\(label)</string>
          <key>ProgramArguments</key>
          <array>
            <string>\(agentPath.xmlEscaped)</string>
          </array>
          <key>StartCalendarInterval</key>
          <dict>
            <key>Hour</key>
            <integer>8</integer>
            <key>Minute</key>
            <integer>30</integer>
          </dict>
          <key>StandardOutPath</key>
          <string>\(logPath("daily.log").xmlEscaped)</string>
          <key>StandardErrorPath</key>
          <string>\(logPath("daily.error.log").xmlEscaped)</string>
        </dict>
        </plist>
        """
    }

    private static func logPath(_ fileName: String) -> String {
        FileManager.default
            .homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Logs", isDirectory: true)
            .appendingPathComponent(fileName, isDirectory: false)
            .path
    }

    enum SchedulerError: LocalizedError {
        case missingAgent(String)
        case launchctl(String)

        var errorDescription: String? {
            switch self {
            case .missingAgent(let path):
                return "Background helper was not found at \(path). Build the app bundle first."
            case .launchctl(let message):
                return message
            }
        }
    }
}

private extension String {
    var xmlEscaped: String {
        replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
}
