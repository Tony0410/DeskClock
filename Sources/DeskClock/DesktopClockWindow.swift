import AppKit

final class DesktopClockWindow: NSWindow {
    private let textField = NSTextField(labelWithString: "")
    private var config: DeskConfig
    private var timer: Timer?
    private var shadow: NSShadow?
    private var lastWallpaperMtime: Date?
    private var lastWallpaperPath: String?

    init(config: DeskConfig) {
        self.config = config
        let screen = NSScreen.main ?? NSScreen.screens.first!
        let frame = DesktopClockWindow.frame(for: config, on: screen)
        super.init(contentRect: frame, styleMask: [.borderless], backing: .buffered, defer: false)
        self.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)))
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.ignoresMouseEvents = true
        self.isMovableByWindowBackground = false

        let view = NSView(frame: frame)
        view.wantsLayer = true
        textField.alignment = .center
        textField.isBezeled = false
        textField.drawsBackground = false
        textField.isEditable = false
        textField.isSelectable = false
        textField.lineBreakMode = .byClipping
        view.addSubview(textField)
        self.contentView = view

        apply(config: config)
        startTimers()
    }

    static func frame(for config: DeskConfig, on screen: NSScreen) -> NSRect {
        let f = screen.frame
        let fontSize = f.height * CGFloat(config.fontScale)
        let w = f.width * 0.9
        let h = fontSize * 1.35
        let cx = f.minX + f.width * CGFloat(config.xRatio)
        let cy = f.maxY - f.height * CGFloat(config.yRatio)
        let origin = NSPoint(x: cx - w / 2, y: cy - h / 2)
        return NSRect(origin: origin, size: CGSize(width: w, height: h))
    }

    func apply(config: DeskConfig) {
        self.config = config
        guard let screen = self.screen ?? NSScreen.main else { return }
        self.setFrame(DesktopClockWindow.frame(for: config, on: screen), display: true)
        self.alphaValue = CGFloat(config.opacity)

        let fontSize = screen.frame.height * CGFloat(config.fontScale)
        let font = resolveFont(config: config, size: fontSize)
        let color = resolveColor(config: config)
        let attr = NSMutableAttributedString(string: formattedTime())
        let range = NSRange(location: 0, length: attr.length)
        attr.addAttribute(.font, value: font, range: range)
        attr.addAttribute(.foregroundColor, value: color, range: range)
        attr.addAttribute(.kern, value: NSNumber(value: config.letterSpacing), range: range)
        let sh = NSShadow()
        sh.shadowColor = color == .white ? NSColor.black.withAlphaComponent(0.35) : NSColor.white.withAlphaComponent(0.35)
        sh.shadowBlurRadius = 6
        sh.shadowOffset = NSSize(width: 0, height: -1)
        attr.addAttribute(.shadow, value: sh, range: range)
        textField.attributedStringValue = attr

        if let v = contentView {
            textField.frame = v.bounds
            textField.autoresizingMask = [.width, .height]
        }
    }

    private func resolveFont(config: DeskConfig, size: CGFloat) -> NSFont {
        let weight = NSFont.Weight(rawValue: CGFloat(config.fontWeight) / 1000.0)
        if config.fontFamily.isEmpty || config.fontFamily.lowercased() == "system" {
            return NSFont.systemFont(ofSize: size, weight: weight)
        }
        if let f = NSFont(name: config.fontFamily, size: size) {
            return f
        }
        return NSFont.systemFont(ofSize: size, weight: weight)
    }

    private func resolveColor(config: DeskConfig) -> NSColor {
        if config.colorMode == "custom", let c = WallpaperColor.color(from: config.color) {
            return c.withAlphaComponent(CGFloat(config.opacity))
        }
        let url = currentWallpaperURL()
        let avg = WallpaperColor.averageRGB(for: url)
        return WallpaperColor.contrastingText(for: avg)
    }

    private func currentWallpaperURL() -> URL? {
        guard let screen = self.screen ?? NSScreen.main else { return nil }
        return NSWorkspace.shared.desktopImageURL(for: screen)
    }

    private func formattedTime() -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = config.format
        return fmt.string(from: Date())
    }

    private func updateText() {
        let font = textField.font ?? NSFont.systemFont(ofSize: 12)
        let color = textField.textColor ?? NSColor.white
        let attr = NSMutableAttributedString(string: formattedTime())
        let range = NSRange(location: 0, length: attr.length)
        attr.addAttribute(.font, value: font, range: range)
        attr.addAttribute(.foregroundColor, value: color, range: range)
        attr.addAttribute(.kern, value: NSNumber(value: config.letterSpacing), range: range)
        textField.attributedStringValue = attr
    }

    private var lastConfigMtime: Date?

    private func startTimers() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateText()
            self?.checkConfigReload()
            self?.checkWallpaper()
        }
        RunLoop.main.add(timer!, forMode: .common)
        updateText()
        checkConfigReload()
        checkWallpaper()
    }

    private func checkConfigReload() {
        let url = DeskConfig.fileURL
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let mtime = attrs[.modificationDate] as? Date else { return }
        if lastConfigMtime == nil { lastConfigMtime = mtime; let newCfg = DeskConfig.load(); self.config = newCfg; apply(config: newCfg); return }
        if mtime != lastConfigMtime {
            lastConfigMtime = mtime
            let newCfg = DeskConfig.load()
            self.config = newCfg
            apply(config: newCfg)
        }
    }

    private func checkWallpaper() {
        guard config.colorMode == "auto" else { return }
        guard let url = currentWallpaperURL() else { return }
        let path = url.path
        let mtime: Date? = (try? FileManager.default.attributesOfItem(atPath: path))?[.modificationDate] as? Date
        let changed = (path != lastWallpaperPath) || (mtime != nil && mtime != lastWallpaperMtime)
        guard changed else { return }
        lastWallpaperPath = path
        lastWallpaperMtime = mtime
        apply(config: config)
    }

    deinit {
        timer?.invalidate()
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }
}
