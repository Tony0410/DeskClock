import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var clockWindow: DesktopClockWindow!
    private var settingsWindow: SettingsWindow!
    private var statusController: StatusItemController!
    private var config: DeskConfig!

    func applicationDidFinishLaunching(_ notification: Notification) {
        config = DeskConfig.load()
        clockWindow = DesktopClockWindow(config: config)
        settingsWindow = SettingsWindow(config: config) { [weak self] newConfig in
            guard let self = self else { return }
            self.config = newConfig
            self.clockWindow.apply(config: newConfig)
        }
        statusController = StatusItemController(settingsWindow: settingsWindow, config: config) {
            NSApp.terminate(nil)
        }
        clockWindow.showWindow()
        LaunchAtLogin.ensureRegistered()
        // allow `kill -USR1 <pid>` over SSH to open settings
        signal(SIGUSR1, SIG_IGN)
        let src = DispatchSource.makeSignalSource(signal: SIGUSR1, queue: .main)
        src.setEventHandler { [weak self] in self?.settingsWindow.show() }
        src.resume()
        objc_setAssociatedObject(app, "sigsrc", src, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        let level = clockWindow.level.rawValue
        let ignores = clockWindow.ignoresMouseEvents
        let coll = clockWindow.collectionBehavior.rawValue
        let statusText = "pid=\(ProcessInfo.processInfo.processIdentifier) loginStatus=\(LaunchAtLogin.statusDescription) enabled=\(LaunchAtLogin.isEnabled) windowLevel=\(level) ignoresMouseEvents=\(ignores) collectionBehavior=\(coll) frame=\(clockWindow.frame)"
        NSLog("DeskClock launched. \(statusText)")
        if let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let dir = base.appendingPathComponent("DeskClock", isDirectory: true)
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            try? statusText.write(to: dir.appendingPathComponent("status.txt"), atomically: true, encoding: .utf8)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}

// NSWindow helper
extension DesktopClockWindow {
    func showWindow() {
        self.orderFrontRegardless()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
// LSUIElement is set via Info.plist; also enforce here
app.setActivationPolicy(.accessory)
app.run()
