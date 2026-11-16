import Foundation

struct DeskConfig: Codable, Equatable {
    var format: String = "h:mm"
    var fontFamily: String = ""
    var fontWeight: Int = 200
    var fontScale: Double = 0.15
    var letterSpacing: Double = -3
    var colorMode: String = "auto" // auto | custom
    var color: String = ""
    var opacity: Double = 0.92
    var xRatio: Double = 0.5
    var yRatio: Double = 0.20
    var startAtLogin: Bool = true

    static let defaults = DeskConfig()

    static var fileURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("DeskClock", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("config.json")
    }

    static func load() -> DeskConfig {
        let url = fileURL
        guard let data = try? Data(contentsOf: url) else { return .defaults }
        let dec = JSONDecoder()
        return (try? dec.decode(DeskConfig.self, from: data)) ?? .defaults
    }

    func save() {
        let url = DeskConfig.fileURL
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted]
        if let data = try? enc.encode(self) {
            try? data.write(to: url, options: .atomic)
        }
    }
}
