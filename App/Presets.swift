import AppKit
import Foundation

enum Presets {
    private static func ring(_ cw: String, _ ccw: String, step: Int = 200) -> RingSettings {
        RingSettings(mode: "actions", positive: cw, negative: ccw, step: step)
    }
    private static func twist(_ cw: String, _ ccw: String, repeatMs: Int = 250) -> TwistSettings {
        TwistSettings(positive: cw, negative: ccw, repeatMs: repeatMs)
    }
    private static let zoom = twist("key:cmd+=", "key:cmd+-")

    static let general = Profile(
        name: "General (macOS)", bundleID: nil,
        twist: zoom,
        ring: ring("media:volup", "media:voldown", step: 150),
        buttons: ["key:cmd+z", "key:cmd+shift+z", "key:cmd+c", "key:cmd+v", "key:ctrl+up"])

    static let apps: [Profile] = [
        Profile(name: "Safari", bundleID: "com.apple.Safari",
                twist: zoom, ring: ring("key:ctrl+tab", "key:ctrl+shift+tab", step: 300),
                buttons: ["key:cmd+[", "key:cmd+]", "key:cmd+t", "key:cmd+w", "key:cmd+r"]),
        Profile(name: "Google Chrome", bundleID: "com.google.Chrome",
                twist: zoom, ring: ring("key:ctrl+tab", "key:ctrl+shift+tab", step: 300),
                buttons: ["key:cmd+[", "key:cmd+]", "key:cmd+t", "key:cmd+w", "key:cmd+r"]),
        Profile(name: "Finder", bundleID: "com.apple.finder",
                twist: zoom, ring: ring("key:down", "key:up"),
                buttons: ["key:cmd+[", "key:cmd+]", "key:space", "key:cmd+up", "key:cmd+n"]),
        Profile(name: "Preview", bundleID: "com.apple.Preview",
                twist: zoom, ring: ring("key:pagedown", "key:pageup", step: 300),
                buttons: ["key:cmd+l", "key:cmd+r", "key:cmd+0", "key:cmd+9", "key:cmd+shift+a"]),
        Profile(name: "Music", bundleID: "com.apple.Music",
                twist: twist("media:next", "media:previous", repeatMs: 600),
                ring: ring("media:volup", "media:voldown", step: 150),
                buttons: ["media:play", "media:previous", "media:next", "key:cmd+l", "key:cmd+f"]),
        Profile(name: "Adobe Photoshop", bundleID: "com.adobe.Photoshop",
                twist: zoom, ring: ring("key:]", "key:[", step: 80),
                buttons: ["key:b", "key:e", "key:v", "key:cmd+z", "key:cmd+0"]),
        Profile(name: "Adobe Illustrator", bundleID: "com.adobe.illustrator",
                twist: twist("key:cmd+shift+z", "key:cmd+z", repeatMs: 350), ring: ring("key:cmd+=", "key:cmd+-", step: 250),
                buttons: ["key:v", "key:a", "key:p", "key:t", "key:cmd+0"]),
        Profile(name: "Lightroom Classic", bundleID: "com.adobe.LightroomClassicCC7",
                twist: zoom, ring: ring("key:right", "key:left", step: 250),
                buttons: ["key:p", "key:x", "key:u", "key:cmd+z", "key:d"]),
        Profile(name: "Figma", bundleID: "com.figma.Desktop",
                twist: twist("key:cmd+shift+z", "key:cmd+z", repeatMs: 350), ring: ring("key:cmd+=", "key:cmd+-", step: 250),
                buttons: ["key:v", "key:r", "key:t", "key:f", "key:shift+1"]),
        Profile(name: "Final Cut Pro", bundleID: "com.apple.FinalCut",
                twist: zoom, ring: ring("key:right", "key:left", step: 80),
                buttons: ["key:space", "key:b", "key:a", "key:cmd+z", "key:i"]),
        Profile(name: "Visual Studio Code", bundleID: "com.microsoft.VSCode",
                twist: zoom, ring: ring("key:cmd+alt+right", "key:cmd+alt+left", step: 300),
                buttons: ["key:cmd+p", "key:cmd+shift+p", "key:cmd+/", "key:cmd+z", "key:cmd+s"]),
        Profile(name: "Firefox", bundleID: "org.mozilla.firefox",
                twist: twist("key:cmd+=", "key:cmd+-", repeatMs: 250), ring: ring("key:ctrl+tab", "key:ctrl+shift+tab", step: 300),
                buttons: ["key:cmd+[", "key:cmd+]", "key:cmd+t", "key:cmd+w", "key:cmd+r"]),
        Profile(name: "Spotify", bundleID: "com.spotify.client",
                twist: twist("media:next", "media:previous", repeatMs: 600), ring: ring("media:volup", "media:voldown", step: 150),
                buttons: ["media:play", "media:previous", "media:next", "key:alt+shift+b", "key:cmd+k"]),
        Profile(name: "VLC", bundleID: "org.videolan.vlc",
                twist: twist("key:cmd+alt+right", "key:cmd+alt+left", repeatMs: 300), ring: ring("media:volup", "media:voldown", step: 150),
                buttons: ["key:space", "key:cmd+f", "key:cmd+.", "media:mute", "key:cmd+o"]),
        Profile(name: "Keynote", bundleID: "com.apple.iWork.Keynote",
                twist: twist("key:cmd+shift+.", "key:cmd+shift+,", repeatMs: 250), ring: ring("key:right", "key:left", step: 300),
                buttons: ["key:cmd+alt+p", "key:escape", "key:cmd+shift+n", "key:cmd+d", "key:cmd+z"]),
        Profile(name: "Pages", bundleID: "com.apple.iWork.Pages",
                twist: twist("key:cmd+shift+.", "key:cmd+shift+,", repeatMs: 250), ring: ring("key:pagedown", "key:pageup", step: 300),
                buttons: ["key:cmd+b", "key:cmd+i", "key:cmd+u", "key:cmd+z", "key:cmd+shift+z"]),
        Profile(name: "Numbers", bundleID: "com.apple.iWork.Numbers",
                twist: twist("key:cmd+shift+.", "key:cmd+shift+,", repeatMs: 250), ring: ring("key:tab", "key:shift+tab", step: 250),
                buttons: ["key:cmd+z", "key:cmd+shift+z", "key:cmd+c", "key:cmd+v", "key:return"]),
        Profile(name: "Xcode", bundleID: "com.apple.dt.Xcode",
                twist: twist("key:cmd+=", "key:cmd+-", repeatMs: 250), ring: ring("key:cmd+shift+]", "key:cmd+shift+[", step: 300),
                buttons: ["key:cmd+r", "key:cmd+b", "key:cmd+.", "key:cmd+shift+o", "key:cmd+u"]),
        Profile(name: "Sketch", bundleID: "com.bohemiancoding.sketch3.beta",
                twist: twist("key:cmd+shift+z", "key:cmd+z", repeatMs: 350), ring: ring("key:cmd+=", "key:cmd+-", step: 250),
                buttons: ["key:v", "key:r", "key:t", "key:o", "key:cmd+z"]),
        Profile(name: "iMovie", bundleID: "com.apple.iMovieApp",
                twist: twist("key:cmd+=", "key:cmd+-", repeatMs: 250), ring: ring("key:right", "key:left", step: 80),
                buttons: ["key:space", "key:cmd+b", "key:/", "key:cmd+z", "key:cmd+shift+f"]),
        Profile(name: "GarageBand", bundleID: "com.apple.garageband10",
                twist: twist("key:cmd+right", "key:cmd+left", repeatMs: 250), ring: ring("key:right", "key:left", step: 150),
                buttons: ["key:space", "key:r", "key:k", "key:return", "key:cmd+z"]),
        Profile(name: "Ghostty", bundleID: "com.mitchellh.ghostty",
                twist: twist("key:cmd+=", "key:cmd+-", repeatMs: 250), ring: ring("key:cmd+shift+]", "key:cmd+shift+[", step: 300),
                buttons: ["key:cmd+t", "key:cmd+w", "key:cmd+d", "key:cmd+k", "key:ctrl+c"]),
    ]

    static func preset(for bundleID: String) -> Profile? {
        apps.first { $0.bundleID == bundleID }.map { var p = $0; p.id = UUID(); return p }
    }

    static func isInstalled(_ bundleID: String?) -> Bool {
        guard let b = bundleID else { return false }
        return NSWorkspace.shared.urlForApplication(withBundleIdentifier: b) != nil
    }

    static func initialConfig() -> MapperConfig {
        var g = general
        if let legacy = loadLegacy() {
            g.puck = legacy.puck; g.twist = legacy.twist; g.ring = legacy.ring
            swap(&g.ring.positive, &g.ring.negative)  // old driver used the raw (counter-clockwise) ring direction
            for i in 0..<5 { if let a = legacy.buttons[String(i + 1)] { g.buttons[i] = a } }
        }
        return MapperConfig(general: g, apps: apps.filter { isInstalled($0.bundleID) })
    }

    // config.json from the earlier command-line nulooqd
    private struct Legacy: Decodable {
        var puck: PuckSettings; var twist: TwistSettings; var ring: RingSettings; var buttons: [String: String]
    }
    private static func loadLegacy() -> Legacy? {
        let url = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Documents/halo/config.json")
        guard let d = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(Legacy.self, from: d)
    }
}
