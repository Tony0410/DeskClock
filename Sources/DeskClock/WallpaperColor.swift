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
        // pick a color with strong contrast; slight tint toward complement for character
        if lum > 0.55 {
            return NSColor(calibratedRed: 0.06, green: 0.06, blue: 0.08, alpha: 1.0)
        } else {
            return NSColor(calibratedRed: 0.96, green: 0.96, blue: 0.98, alpha: 1.0)
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
