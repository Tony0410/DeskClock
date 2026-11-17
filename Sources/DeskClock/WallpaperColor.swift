import AppKit
import CoreGraphics

enum WallpaperColor {
    // Returns an average RGB (0..1) for the current wallpaper (or the given image URL).
    static func averageRGB(for url: URL?) -> (r: Double, g: Double, b: Double)? {
        guard let url = url, let ns = NSImage(contentsOf: url) else { return nil }
        guard let cg = ns.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        let w = 64, h = 64
        guard let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                                 space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
        guard let data = ctx.data else { return nil }
        let ptr = data.bindMemory(to: UInt8.self, capacity: w * h * 4)
        var r = 0.0, g = 0.0, b = 0.0, n = 0.0
        for i in 0..<(w * h) {
            let o = i * 4
            r += Double(ptr[o]) / 255.0
            g += Double(ptr[o + 1]) / 255.0
            b += Double(ptr[o + 2]) / 255.0
            n += 1
        }
        guard n > 0 else { return nil }
        return (r / n, g / n, b / n)
    }

    static func contrastingText(for avg: (r: Double, g: Double, b: Double)?) -> NSColor {
        guard let a = avg else { return NSColor.white }
        let lum = 0.299 * a.r + 0.587 * a.g + 0.114 * a.b
        // Tint the text toward the wallpaper's hue so it complements the desktop,
        // while keeping strong contrast (dark on light wallpapers, light on dark).
        if lum > 0.55 {
            // dark text: blend wallpaper hue into near-black at ~25%
            return NSColor(calibratedRed: a.r * 0.22,
                           green: a.g * 0.22,
                           blue: a.b * 0.22, alpha: 1.0)
        } else {
            // light text: blend wallpaper hue into near-white at ~25%
            return NSColor(calibratedRed: 0.82 + a.r * 0.18,
                           green: 0.82 + a.g * 0.18,
                           blue: 0.82 + a.b * 0.18, alpha: 1.0)
        }
    }

    static func color(from hex: String) -> NSColor? {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = UInt32(s, radix: 16) else { return nil }
        let r = Double((v >> 16) & 0xFF) / 255.0
        let g = Double((v >> 8) & 0xFF) / 255.0
        let b = Double(v & 0xFF) / 255.0
        return NSColor(calibratedRed: r, green: g, blue: b, alpha: 1.0)
    }
}
