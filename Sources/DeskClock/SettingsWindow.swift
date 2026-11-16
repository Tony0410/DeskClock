import AppKit
import ServiceManagement

final class SettingsWindow: NSWindow {
    private var config: DeskConfig
    private let onChange: (DeskConfig) -> Void
    private var controls: [NSView] = []

    // controls
    private let sizeSlider = NSSlider()
    private let xSlider = NSSlider()
    private let ySlider = NSSlider()
    private let opacitySlider = NSSlider()
    private let formatPopup = NSPopUpButton()
    private let colorModePopup = NSPopUpButton()
    private let colorField = NSTextField()
    private let fontPopup = NSPopUpButton()
    private let loginCheckbox = NSButton(checkboxWithTitle: "Start at login", target: nil, action: nil)
    private let resetButton = NSButton(title: "Reset", target: nil, action: nil)

    init(config: DeskConfig, onChange: @escaping (DeskConfig) -> Void) {
        self.config = config
        self.onChange = onChange
        super.init(contentRect: NSRect(x: 0, y: 0, width: 420, height: 520),
                   styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
        self.title = "DeskClock Settings"
        self.isReleasedWhenClosed = false
        buildUI()
        syncFromConfig()
    }

    private func buildUI() {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.edgeInsets = NSEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)

        func row(_ label: String, _ control: NSView) -> NSView {
            let l = NSTextField(labelWithString: label)
            l.font = NSFont.systemFont(ofSize: 12)
            let r = NSStackView(views: [l, control])
            r.orientation = .horizontal
            r.spacing = 8
            control.translatesAutoresizingMaskIntoConstraints = false
            return r
        }

        sizeSlider.minValue = 5; sizeSlider.maxValue = 45; sizeSlider.target = self; sizeSlider.action = #selector(changed)
        xSlider.minValue = 0; xSlider.maxValue = 100; xSlider.target = self; xSlider.action = #selector(changed)
        ySlider.minValue = 0; ySlider.maxValue = 100; ySlider.target = self; ySlider.action = #selector(changed)
        opacitySlider.minValue = 0; opacitySlider.maxValue = 100; opacitySlider.target = self; opacitySlider.action = #selector(changed)

        formatPopup.addItems(withTitles: ["12h", "12h + seconds", "24h", "24h + seconds"])
        formatPopup.target = self; formatPopup.action = #selector(changed)

        colorModePopup.addItems(withTitles: ["Auto (wallpaper)", "Custom hex"])
        colorModePopup.target = self; colorModePopup.action = #selector(changed)

        colorField.placeholderString = "#ffcc00"
        colorField.target = self; colorField.action = #selector(colorApplied)

        fontPopup.removeAllItems()
        fontPopup.addItem(withTitle: "System")
        let families = NSFontManager.shared.availableFontFamilies.sorted()
        fontPopup.addItems(withTitles: families)
        fontPopup.target = self; fontPopup.action = #selector(changed)

        loginCheckbox.target = self; loginCheckbox.action = #selector(changed)
        resetButton.target = self; resetButton.action = #selector(reset)

        stack.addArrangedSubview(row("Size (% of screen height)", sizeSlider))
        stack.addArrangedSubview(row("X position (%)", xSlider))
        stack.addArrangedSubview(row("Y position (% from top)", ySlider))
        stack.addArrangedSubview(row("Opacity (%)", opacitySlider))
        stack.addArrangedSubview(row("Format", formatPopup))
        stack.addArrangedSubview(row("Colour mode", colorModePopup))
        stack.addArrangedSubview(row("Custom colour", colorField))
        stack.addArrangedSubview(row("Font", fontPopup))
        stack.addArrangedSubview(loginCheckbox)
        stack.addArrangedSubview(resetButton)

        let scroll = NSScrollView()
        scroll.documentView = stack
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers = true
        self.contentView = scroll
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scroll.contentView.topAnchor),
            stack.leadingAnchor.constraint(equalTo: scroll.contentView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scroll.contentView.trailingAnchor),
            stack.widthAnchor.constraint(equalTo: scroll.contentView.widthAnchor),
        ])
    }

    private func syncFromConfig() {
        sizeSlider.doubleValue = config.fontScale * 100.0 * (100.0/15.0) // approximate: fontScale 0.15 -> 15%; slider 5..45 represents percent
        // Actually keep slider in percent of screen height directly:
        sizeSlider.doubleValue = config.fontScale * 100.0
        xSlider.doubleValue = config.xRatio * 100.0
        ySlider.doubleValue = config.yRatio * 100.0
        opacitySlider.doubleValue = config.opacity * 100.0
        let fmtIndex: Int
        switch config.format {
        case "h:mm": fmtIndex = 0
        case "h:mm:ss": fmtIndex = 1
        case "HH:mm": fmtIndex = 2
        case "HH:mm:ss": fmtIndex = 3
        default: fmtIndex = 0
        }
        formatPopup.selectItem(at: fmtIndex)
        colorModePopup.selectItem(at: config.colorMode == "custom" ? 1 : 0)
        colorField.stringValue = config.color
        colorField.isEnabled = config.colorMode == "custom"
        if config.fontFamily.isEmpty {
            fontPopup.selectItem(at: 0)
        } else {
            if let idx = fontPopup.itemTitles.firstIndex(of: config.fontFamily) {
                fontPopup.selectItem(at: idx)
            }
        }
        loginCheckbox.state = LaunchAtLogin.isEnabled ? .on : .off
    }

    @objc private func changed() {
        config.fontScale = sizeSlider.doubleValue / 100.0
        config.xRatio = xSlider.doubleValue / 100.0
        config.yRatio = ySlider.doubleValue / 100.0
        config.opacity = opacitySlider.doubleValue / 100.0
        let formats = ["h:mm", "h:mm:ss", "HH:mm", "HH:mm:ss"]
        config.format = formats[max(0, min(3, formatPopup.indexOfSelectedItem))]
        config.colorMode = (colorModePopup.indexOfSelectedItem == 1) ? "custom" : "auto"
        config.color = colorField.stringValue
        colorField.isEnabled = config.colorMode == "custom"
        if fontPopup.indexOfSelectedItem == 0 {
            config.fontFamily = ""
        } else {
            config.fontFamily = fontPopup.titleOfSelectedItem ?? ""
        }
        if loginCheckbox.state == .on {
            LaunchAtLogin.setEnabled(true)
        } else {
            LaunchAtLogin.setEnabled(false)
        }
        config.startAtLogin = (loginCheckbox.state == .on)
        config.save()
        onChange(config)
    }

    @objc private func colorApplied() {
        changed()
    }

    @objc private func reset() {
        config = .defaults
        syncFromConfig()
        config.save()
        onChange(config)
    }

    func show() {
        syncFromConfig()
        makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
