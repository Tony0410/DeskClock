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
            // Use a unicode clock glyph as the title so the item is always visible
            // regardless of SF Symbol availability or menu-bar overflow.
            button.title = "⏱"
            button.font = NSFont.systemFont(ofSize: 14)
            button.action = #selector(toggleSettings)
            button.target = self
            button.toolTip = "DeskClock — click for settings"
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
