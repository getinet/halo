import AppKit
import Foundation

struct PuckSettings: Codable, Hashable {
    var mode = "scroll"          // scroll | mouse | none
    var speed = 1.0
    var deadzone = 25
    var invertX = false
    var invertY = false
}

struct TwistSettings: Codable, Hashable {
    var positive = "key:cmd+="   // twist clockwise
    var negative = "key:cmd+-"   // twist counter-clockwise
    var threshold = 120
    var repeatMs = 250
}

struct RingSettings: Codable, Hashable {
    var mode = "actions"         // actions | scroll | none
    var positive = "media:volup" // slide clockwise
    var negative = "media:voldown"
    var step = 150               // ring units (of 4096 per turn) per action
    var scrollSpeed = 1.0
}

struct Profile: Codable, Hashable, Identifiable {
    var id = UUID()
    var name: String
    var bundleID: String?        // nil = General profile
    var enabled = true
    var puck = PuckSettings()
    var twist = TwistSettings()
    var ring = RingSettings()
    var buttons = ["key:cmd+z", "key:cmd+shift+z", "key:cmd+c", "key:cmd+v", "key:ctrl+up"]
}

enum LEDMode: String, Codable, CaseIterable {
    case off, pressed, always
}

struct MapperConfig: Codable, Equatable {
    var enabled = true
    var ledMode = LEDMode.pressed
    var general: Profile
    var apps: [Profile]

    init(general: Profile, apps: [Profile]) {
        self.general = general
        self.apps = apps
    }

    private enum CodingKeys: String, CodingKey { case enabled, ledMode, leds, general, apps }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        enabled = try c.decodeIfPresent(Bool.self, forKey: .enabled) ?? true
        general = try c.decode(Profile.self, forKey: .general)
        apps = try c.decode([Profile].self, forKey: .apps)
        if let m = try c.decodeIfPresent(LEDMode.self, forKey: .ledMode) {
            ledMode = m
        } else if let old = try c.decodeIfPresent(Bool.self, forKey: .leds) {   // older config
            ledMode = old ? .pressed : .off
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(enabled, forKey: .enabled)
        try c.encode(ledMode, forKey: .ledMode)
        try c.encode(general, forKey: .general)
        try c.encode(apps, forKey: .apps)
    }
}

final class Store: ObservableObject {
    static let shared = Store()

    @Published var config: MapperConfig {
        didSet { if config != oldValue { scheduleSave() } }
    }
    let url: URL
    private(set) var firstRun = false
    private var pendingSave: DispatchWorkItem?

    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Halo")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        url = dir.appendingPathComponent("config.json")
        // Carry settings over from when the app was called "NuLOOQ".
        let old = dir.deletingLastPathComponent().appendingPathComponent("NuLOOQ/config.json")
        if !FileManager.default.fileExists(atPath: url.path) { try? FileManager.default.copyItem(at: old, to: url) }
        if let data = try? Data(contentsOf: url),
           let c = try? JSONDecoder().decode(MapperConfig.self, from: data) {
            config = c
        } else {
            config = Presets.initialConfig()
            firstRun = true
            save()
        }
    }

    func profile(for bundleID: String?) -> Profile {
        if let b = bundleID, let p = config.apps.first(where: { $0.bundleID == b && $0.enabled }) { return p }
        return config.general
    }

    private func scheduleSave() {
        pendingSave?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.save() }
        pendingSave = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: work)
    }

    func save() {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        do { try enc.encode(config).write(to: url, options: .atomic) } catch { NSLog("Halo: saving config failed: \(error)") }
    }
}
