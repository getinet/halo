import AppKit
import Foundation

// Actions are stored as strings: "key:cmd+shift+z", "media:play", "click:left",
// "open:/Applications/Safari.app", "shell:say hi", or "none".

enum ActionKind: String, CaseIterable, Identifiable {
    case none, key, media, click, open, shell
    var id: Self { self }
    var label: String {
        switch self {
        case .none: "Do nothing"
        case .key: "Keyboard shortcut"
        case .media: "Media key"
        case .click: "Mouse click"
        case .open: "Open app or file"
        case .shell: "Shell command"
        }
    }
    var defaultValue: String {
        switch self {
        case .media: "play"
        case .click: "left"
        default: ""
        }
    }
}

struct ActionSpec {
    var kind: ActionKind
    var value: String

    init(_ s: String) {
        if let i = s.firstIndex(of: ":"), let k = ActionKind(rawValue: String(s[..<i])) {
            kind = k; value = String(s[s.index(after: i)...])
        } else {
            kind = .none; value = ""
        }
    }
    init(kind: ActionKind, value: String) { self.kind = kind; self.value = value }

    var string: String { kind == .none ? "none" : "\(kind.rawValue):\(value)" }
}

let mediaKeyNames: [(id: String, label: String)] = [
    ("play", "Play / Pause"), ("next", "Next Track"), ("previous", "Previous Track"),
    ("volup", "Volume Up"), ("voldown", "Volume Down"), ("mute", "Mute"),
    ("brightup", "Brightness Up"), ("brightdown", "Brightness Down"),
]

enum Shortcut {
    static let keyCodes: [String: CGKeyCode] = [
        "a": 0, "s": 1, "d": 2, "f": 3, "h": 4, "g": 5, "z": 6, "x": 7, "c": 8, "v": 9, "b": 11,
        "q": 12, "w": 13, "e": 14, "r": 15, "y": 16, "t": 17, "1": 18, "2": 19, "3": 20, "4": 21,
        "6": 22, "5": 23, "=": 24, "9": 25, "7": 26, "-": 27, "8": 28, "0": 29, "]": 30, "o": 31,
        "u": 32, "[": 33, "i": 34, "p": 35, "return": 36, "l": 37, "j": 38, "'": 39, "k": 40,
        ";": 41, "\\": 42, ",": 43, "/": 44, "n": 45, "m": 46, ".": 47, "tab": 48, "space": 49,
        "`": 50, "delete": 51, "escape": 53, "f5": 96, "f6": 97, "f7": 98, "f3": 99,
        "f8": 100, "f9": 101, "f11": 103, "f10": 109, "f12": 111, "home": 115, "pageup": 116,
        "forwarddelete": 117, "f4": 118, "end": 119, "f2": 120, "pagedown": 121, "f1": 122,
        "left": 123, "right": 124, "down": 125, "up": 126,
    ]
    static let names: [CGKeyCode: String] = Dictionary(uniqueKeysWithValues: keyCodes.map { ($1, $0) })

    static let modifiers: [String: CGEventFlags] = [
        "cmd": .maskCommand, "shift": .maskShift, "alt": .maskAlternate, "opt": .maskAlternate,
        "ctrl": .maskControl, "fn": .maskSecondaryFn,
    ]

    /// Parses "cmd+shift+z" into a key code + flags. "kc50" means raw key code 50.
    static func parse(_ combo: String) -> (CGKeyCode, CGEventFlags)? {
        var flags: CGEventFlags = []
        var code: CGKeyCode?
        for token in combo.lowercased().split(separator: "+").map(String.init) {
            if let m = modifiers[token] { flags.insert(m) }
            else if let k = keyCodes[token] { code = k }
            else if token.hasPrefix("kc"), let n = UInt16(token.dropFirst(2)) { code = n }
            else { return nil }
        }
        return code.map { ($0, flags) }
    }

    static func combo(from e: NSEvent) -> String {
        var parts: [String] = []
        let f = e.modifierFlags
        if f.contains(.control) { parts.append("ctrl") }
        if f.contains(.option) { parts.append("alt") }
        if f.contains(.shift) { parts.append("shift") }
        if f.contains(.command) { parts.append("cmd") }
        parts.append(names[e.keyCode] ?? "kc\(e.keyCode)")
        return parts.joined(separator: "+")
    }

    static func display(_ combo: String) -> String {
        let symbols: [String: String] = [
            "ctrl": "⌃", "alt": "⌥", "opt": "⌥", "shift": "⇧", "cmd": "⌘", "fn": "fn ",
            "left": "←", "right": "→", "up": "↑", "down": "↓", "return": "↩", "tab": "⇥",
            "space": "Space", "delete": "⌫", "forwarddelete": "⌦", "escape": "⎋",
            "pageup": "Page Up", "pagedown": "Page Down", "home": "Home", "end": "End",
        ]
        let tokens = combo.lowercased().split(separator: "+").map(String.init)
        let order = ["ctrl", "alt", "opt", "shift", "cmd", "fn"]
        let mods = order.filter(tokens.contains).map { symbols[$0]! }.joined()
        let key = tokens.first { !order.contains($0) }.map { k -> String in
            if let s = symbols[k] { return s }
            if k.hasPrefix("kc") { return "Key \(k.dropFirst(2))" }
            return k.uppercased()
        } ?? ""
        return mods + key
    }
}

enum ActionRunner {
    static let source = CGEventSource(stateID: .hidSystemState)

    static func perform(_ action: String) {
        let spec = ActionSpec(action)
        switch spec.kind {
        case .none: break
        case .key:
            guard let (code, flags) = Shortcut.parse(spec.value) else { return }
            for down in [true, false] {
                let e = CGEvent(keyboardEventSource: source, virtualKey: code, keyDown: down)
                e?.flags = flags
                e?.post(tap: .cghidEventTap)
            }
        case .media:
            let codes = ["volup": 0, "voldown": 1, "brightup": 2, "brightdown": 3, "mute": 7,
                         "play": 16, "next": 17, "previous": 18]
            guard let k = codes[spec.value] else { return }
            for down in [true, false] {
                NSEvent.otherEvent(with: .systemDefined, location: .zero,
                                   modifierFlags: NSEvent.ModifierFlags(rawValue: down ? 0xa00 : 0xb00),
                                   timestamp: 0, windowNumber: 0, context: nil, subtype: 8,
                                   data1: (k << 16) | ((down ? 0xa : 0xb) << 8), data2: -1)?
                    .cgEvent?.post(tap: .cghidEventTap)
            }
        case .click:
            let pos = CGEvent(source: nil)?.location ?? .zero
            let (dn, up, btn): (CGEventType, CGEventType, CGMouseButton) = switch spec.value {
            case "right": (.rightMouseDown, .rightMouseUp, .right)
            case "middle": (.otherMouseDown, .otherMouseUp, .center)
            default: (.leftMouseDown, .leftMouseUp, .left)
            }
            CGEvent(mouseEventSource: source, mouseType: dn, mouseCursorPosition: pos, mouseButton: btn)?.post(tap: .cghidEventTap)
            CGEvent(mouseEventSource: source, mouseType: up, mouseCursorPosition: pos, mouseButton: btn)?.post(tap: .cghidEventTap)
        case .open:
            guard !spec.value.isEmpty else { return }
            NSWorkspace.shared.open(URL(fileURLWithPath: spec.value))
        case .shell:
            guard !spec.value.isEmpty else { return }
            let p = Process()
            p.executableURL = URL(fileURLWithPath: "/bin/sh")
            p.arguments = ["-c", spec.value]
            try? p.run()
        }
    }

    static func scroll(dx: Int32, dy: Int32) {
        CGEvent(scrollWheelEvent2Source: source, units: .pixel, wheelCount: 2, wheel1: dy, wheel2: dx, wheel3: 0)?
            .post(tap: .cghidEventTap)
    }

    static func moveMouse(dx: Double, dy: Double) {
        guard var p = CGEvent(source: nil)?.location else { return }
        p.x += dx; p.y += dy
        CGEvent(mouseEventSource: source, mouseType: .mouseMoved, mouseCursorPosition: p, mouseButton: .left)?
            .post(tap: .cghidEventTap)
    }
}
