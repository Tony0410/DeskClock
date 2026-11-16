import AppKit

final class StatusItemController {
    private let statusItem: NSStatusItem
    private let settingsWindow: SettingsWindow
    private let onQuit: () -> Void

    init(settingsWindow: SettingsWindow, config: DeskConfig, onQuit: @escaping () -> Void) {
        self.settingsWindow = settingsWindow
        self.onQuit = onQuit
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "clock", accessibilityDescription: "DeskClock")
            button.action = #selector(toggleSettings)
            button.target = self
        }
        let menu = NSMenu()
        let show = NSMenuItem(title: "Settings…", action: #selector(toggleSettings), keyEquivalent: ",")
        show.target = self
        menu.addItem(show)
        menu.addItem(NSMenuItem.separator())
        let quit = NSMenuItem(title: "Quit DeskClock", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
        statusItem.menu = menu
    }

    @objc private func toggleSettings() {
        if settingsWindow.isVisible {
            settingsWindow.orderOut(nil)
        } else {
            settingsWindow.show()
        }
    }

    @objc private func quit() {
        onQuit()
    }
}
