import Foundation

enum LaunchAtLogin {
    static let label = "com.anthony.deskclock"

    static var plistURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents", isDirectory: true)
            .appendingPathComponent("\(label).plist")
    }

    static var isEnabled: Bool {
        FileManager.default.fileExists(atPath: plistURL.path)
    }

    static func setEnabled(_ on: Bool) {
        let fm = FileManager.default
        let dir = plistURL.deletingLastPathComponent()
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)

        if on {
            let exec = Bundle.main.executablePath ?? "/Applications/DeskClock.app/Contents/MacOS/DeskClock"
            let plist = """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
                <key>Label</key>
                <string>\(label)</string>
                <key>ProgramArguments</key>
                <array>
                    <string>\(exec)</string>
                </array>
                <key>RunAtLoad</key>
                <true/>
                <key>KeepAlive</key>
                <false/>
                <key>StandardOutPath</key>
                <string>/tmp/deskclock.log</string>
                <key>StandardErrorPath</key>
                <string>/tmp/deskclock.log</string>
            </dict>
            </plist>
            """
            try? plist.write(to: plistURL, atomically: true, encoding: .utf8)
            let uid = getuid()
            // best-effort bootstrap
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/bin/launchctl")
            task.arguments = ["bootstrap", "gui/\(uid)", plistURL.path]
            task.standardOutput = Pipe()
            task.standardError = Pipe()
            do { try task.run(); task.waitUntilExit() } catch { }
        } else {
            let uid = getuid()
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/bin/launchctl")
            task.arguments = ["bootout", "gui/\(uid)/\(label)"]
            task.standardOutput = Pipe()
            task.standardError = Pipe()
            do { try task.run(); task.waitUntilExit() } catch { }
            try? fm.removeItem(at: plistURL)
        }
    }

    static func ensureRegistered() {
        if !isEnabled { setEnabled(true) }
    }

    static var statusDescription: String {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        task.arguments = ["print", "gui/\(getuid())/\(label)"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        do { try task.run(); task.waitUntilExit() } catch { return "error" }
        return task.terminationStatus == 0 ? "loaded" : "not-loaded"
    }
}
