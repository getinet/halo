// nulooqd — user-space driver for the Logitech/3Dconnexion NuLOOQ Navigator (046d:c640).
//
//   nulooqd monitor            print live input (use this to see what the device sends)
//   nulooqd [--config FILE]    run, mapping input to actions from config.json
//
// Needs Accessibility permission (System Settings > Privacy & Security > Accessibility)
// to post keyboard/scroll events.

import AppKit
import ApplicationServices
import Foundation
import IOKit.hid

// MARK: - Config

struct Config: Codable {
    struct Puck: Codable {
        var mode = "scroll"          // scroll | mouse | none
        var speed = 1.0
        var deadzone = 25
        var invertX = false
        var invertY = false
    }
    struct Twist: Codable {
        var positive = "key:cmd+="   // twist clockwise
        var negative = "key:cmd+-"   // twist counter-clockwise
        var threshold = 120
        var repeatMs = 250
    }
    struct Ring: Codable {
        var mode = "actions"         // actions | scroll | none
        var positive = "media:volup" // slide clockwise
        var negative = "media:voldown"
        var step = 150               // ring units (of 4096 per turn) per action
        var scrollSpeed = 1.0
    }
    var puck = Puck()
    var twist = Twist()
    var ring = Ring()
    var buttons: [String: String] = [
        "1": "key:cmd+z",
        "2": "key:cmd+shift+z",
        "3": "key:cmd+c",
        "4": "key:cmd+v",
        "5": "key:ctrl+up",
    ]
    var leds = true
}

func loadConfig(_ path: String) -> Config {
    guard let data = FileManager.default.contents(atPath: path) else {
        log("no config at \(path), using defaults")
        return Config()
    }
    do { return try JSONDecoder().decode(Config.self, from: data) } catch {
        log("bad config \(path): \(error) — using defaults")
        return Config()
    }
}

func log(_ s: String) {
    FileHandle.standardError.write((s + "\n").data(using: .utf8)!)
}

// MARK: - Actions

let keyCodes: [String: CGKeyCode] = [
    "a": 0, "s": 1, "d": 2, "f": 3, "h": 4, "g": 5, "z": 6, "x": 7, "c": 8, "v": 9, "b": 11,
    "q": 12, "w": 13, "e": 14, "r": 15, "y": 16, "t": 17, "1": 18, "2": 19, "3": 20, "4": 21,
    "6": 22, "5": 23, "=": 24, "9": 25, "7": 26, "-": 27, "8": 28, "0": 29, "]": 30, "o": 31,
    "u": 32, "[": 33, "i": 34, "p": 35, "return": 36, "l": 37, "j": 38, "'": 39, "k": 40,
    ";": 41, "\\": 42, ",": 43, "/": 44, "n": 45, "m": 46, ".": 47, "tab": 48, "space": 49,
    "`": 50, "delete": 51, "escape": 53, "esc": 53, "f5": 96, "f6": 97, "f7": 98, "f3": 99,
    "f8": 100, "f9": 101, "f11": 103, "f10": 109, "f12": 111, "home": 115, "pageup": 116,
    "forwarddelete": 117, "f4": 118, "end": 119, "f2": 120, "pagedown": 121, "f1": 122,
    "left": 123, "right": 124, "down": 125, "up": 126,
]

let modifierFlags: [String: CGEventFlags] = [
    "cmd": .maskCommand, "command": .maskCommand, "shift": .maskShift,
    "alt": .maskAlternate, "opt": .maskAlternate, "option": .maskAlternate,
    "ctrl": .maskControl, "control": .maskControl, "fn": .maskSecondaryFn,
]

// NX_KEYTYPE_* codes for system-defined media key events
let mediaKeys: [String: Int] = [
    "volup": 0, "voldown": 1, "mute": 7, "brightup": 2, "brightdown": 3,
    "play": 16, "next": 17, "previous": 18,
]

let source = CGEventSource(stateID: .hidSystemState)

func perform(_ action: String) {
    let parts = action.split(separator: ":", maxSplits: 1).map(String.init)
    guard parts.count == 2 else { if action != "none" && !action.isEmpty { log("bad action: \(action)") }; return }
    switch parts[0] {
    case "key":
        var flags: CGEventFlags = []
        var code: CGKeyCode?
        // split on "+", but allow "=" / "-" etc. as the final key (e.g. "cmd+=")
        for token in parts[1].lowercased().split(separator: "+", omittingEmptySubsequences: false).map(String.init) {
            if let m = modifierFlags[token] { flags.insert(m) }
            else if let k = keyCodes[token] { code = k }
            else if token.isEmpty { code = 24 } // "cmd++" → "="
            else { log("unknown key '\(token)' in \(action)"); return }
        }
        guard let k = code else { return }
        for down in [true, false] {
            let e = CGEvent(keyboardEventSource: source, virtualKey: k, keyDown: down)
            e?.flags = flags
            e?.post(tap: .cghidEventTap)
        }
    case "media":
        guard let k = mediaKeys[parts[1].lowercased()] else { log("unknown media key \(parts[1])"); return }
        for down in [true, false] {
            let data1 = (k << 16) | ((down ? 0xa : 0xb) << 8)
            NSEvent.otherEvent(with: .systemDefined, location: .zero,
                               modifierFlags: NSEvent.ModifierFlags(rawValue: down ? 0xa00 : 0xb00),
                               timestamp: 0, windowNumber: 0, context: nil, subtype: 8,
                               data1: data1, data2: -1)?.cgEvent?.post(tap: .cghidEventTap)
        }
    case "click":
        let pos = CGEvent(source: nil)?.location ?? .zero
        let (dn, up, btn): (CGEventType, CGEventType, CGMouseButton) =
            parts[1] == "right" ? (.rightMouseDown, .rightMouseUp, .right) : (.leftMouseDown, .leftMouseUp, .left)
        CGEvent(mouseEventSource: source, mouseType: dn, mouseCursorPosition: pos, mouseButton: btn)?.post(tap: .cghidEventTap)
        CGEvent(mouseEventSource: source, mouseType: up, mouseCursorPosition: pos, mouseButton: btn)?.post(tap: .cghidEventTap)
    case "open":
        NSWorkspace.shared.open(URL(fileURLWithPath: parts[1]))
    case "shell":
        let p = Process(); p.executableURL = URL(fileURLWithPath: "/bin/sh"); p.arguments = ["-c", parts[1]]
        try? p.run()
    default:
        log("unknown action type: \(action)")
    }
}

func scroll(dx: Int32, dy: Int32) {
    CGEvent(scrollWheelEvent2Source: source, units: .pixel, wheelCount: 2, wheel1: dy, wheel2: dx, wheel3: 0)?
        .post(tap: .cghidEventTap)
}

func moveMouse(dx: Double, dy: Double) {
    guard var p = CGEvent(source: nil)?.location else { return }
    p.x += dx; p.y += dy
    CGEvent(mouseEventSource: source, mouseType: .mouseMoved, mouseCursorPosition: p, mouseButton: .left)?
        .post(tap: .cghidEventTap)
}

// MARK: - Device state

final class NuLOOQ {
    let monitorOnly: Bool
    let cfg: Config
    var device: IOHIDDevice?
    var x = 0, y = 0, twist = 0
    var ringAngle: Int?, ringTouched = false, ringAccum = 0.0
    var buttons = Set<Int>()
    var twistLastFire = Date.distantPast
    var scrollRemX = 0.0, scrollRemY = 0.0

    init(cfg: Config, monitorOnly: Bool) { self.cfg = cfg; self.monitorOnly = monitorOnly }

    func value(page: UInt32, usage: UInt32, v: Int) {
        switch (page, usage) {
        case (1, 0x30): x = v
        case (1, 0x31): y = v
        case (1, 0x35): twist = v
        case (1, 0x32): ring(angle: v)
        case (0x0d, 0x30):
            ringTouched = v > 0
            if !ringTouched { ringAngle = nil; ringAccum = 0 }
        case (9, let b) where b >= 1 && b <= 8:
            if v != 0 { buttons.insert(Int(b)); if !monitorOnly { perform(cfg.buttons[String(b)] ?? "none") } }
            else { buttons.remove(Int(b)) }
            setLEDs()
        default: break
        }
        if monitorOnly {
            print(String(format: "puck x=%5d y=%5d twist=%5d | ring=%@ touch=%@ | buttons=%@",
                         x, y, twist, ringAngle.map { String($0) } ?? "-", ringTouched ? "yes" : "no",
                         buttons.sorted().map(String.init).joined(separator: ",")))
        }
    }

    func ring(angle: Int) {
        defer { ringAngle = angle }
        guard let prev = ringAngle else { return }
        var d = angle - prev
        if d > 2048 { d -= 4096 } else if d < -2048 { d += 4096 }   // wrap-around
        if monitorOnly || cfg.ring.mode == "none" { return }
        if cfg.ring.mode == "scroll" {
            scroll(dx: 0, dy: Int32(Double(d) * cfg.ring.scrollSpeed))
            return
        }
        ringAccum += Double(d)
        let step = Double(max(cfg.ring.step, 1))
        while ringAccum >= step { ringAccum -= step; perform(cfg.ring.positive) }
        while ringAccum <= -step { ringAccum += step; perform(cfg.ring.negative) }
    }

    // Called ~60×/s: the puck and twist are spring-loaded, so act on held deflection.
    func tick() {
        guard !monitorOnly else { return }
        let dz = cfg.puck.deadzone
        func curve(_ v: Int) -> Double {
            guard abs(v) > dz else { return 0 }
            let n = Double(abs(v) - dz) / Double(512 - dz)          // 0…1
            return (v < 0 ? -1 : 1) * n * n * 40 * cfg.puck.speed   // quadratic for fine control
        }
        let fx = curve(x) * (cfg.puck.invertX ? -1 : 1)
        let fy = curve(y) * (cfg.puck.invertY ? -1 : 1)
        if fx != 0 || fy != 0 {
            switch cfg.puck.mode {
            case "scroll":
                scrollRemX += -fx; scrollRemY += -fy
                let ix = Int32(scrollRemX), iy = Int32(scrollRemY)
                scrollRemX -= Double(ix); scrollRemY -= Double(iy)
                if ix != 0 || iy != 0 { scroll(dx: ix, dy: iy) }
            case "mouse": moveMouse(dx: fx / 2, dy: fy / 2)
            default: break
            }
        }
        if abs(twist) > cfg.twist.threshold,
           Date().timeIntervalSince(twistLastFire) * 1000 >= Double(cfg.twist.repeatMs) {
            twistLastFire = Date()
            perform(twist > 0 ? cfg.twist.positive : cfg.twist.negative)
        }
    }

    // Output report 4: 5 LED bits. Light the LED of whichever button is held.
    func setLEDs() {
        guard cfg.leds, let d = device else { return }
        var bits: UInt8 = 0
        for b in buttons where b <= 5 { bits |= 1 << (b - 1) }
        var report: [UInt8] = [4, bits]
        IOHIDDeviceSetReport(d, kIOHIDReportTypeOutput, 4, &report, report.count)
    }
}

// MARK: - Main

let args = CommandLine.arguments
let monitor = args.contains("monitor")
let exeDir = URL(fileURLWithPath: args[0]).resolvingSymlinksInPath().deletingLastPathComponent().path
var configPath = exeDir + "/config.json"
if let i = args.firstIndex(of: "--config"), i + 1 < args.count { configPath = args[i + 1] }

let cfg = loadConfig(configPath)
let nuloq = NuLOOQ(cfg: cfg, monitorOnly: monitor)

if !monitor {
    let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
    if !AXIsProcessTrustedWithOptions(opts) {
        log("⚠️  Accessibility permission missing — grant it to this program in System Settings > Privacy & Security > Accessibility, then restart it.")
    }
}

let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
IOHIDManagerSetDeviceMatching(manager, [kIOHIDVendorIDKey: 0x046d, kIOHIDProductIDKey: 0xc640] as CFDictionary)

IOHIDManagerRegisterDeviceMatchingCallback(manager, { _, _, _, device in
    log("NuLOOQ connected")
    nuloq.device = device
    nuloq.setLEDs()
}, nil)
IOHIDManagerRegisterDeviceRemovalCallback(manager, { _, _, _, _ in
    log("NuLOOQ disconnected")
    nuloq.device = nil
    nuloq.x = 0; nuloq.y = 0; nuloq.twist = 0; nuloq.buttons = []
}, nil)
IOHIDManagerRegisterInputValueCallback(manager, { _, _, _, value in
    let el = IOHIDValueGetElement(value)
    nuloq.value(page: IOHIDElementGetUsagePage(el), usage: IOHIDElementGetUsage(el),
                v: IOHIDValueGetIntegerValue(value))
}, nil)

IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
let r = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
if r != kIOReturnSuccess {
    log(String(format: "Could not open HID manager (0x%x). If prompted, allow Input Monitoring.", r))
}

Timer.scheduledTimer(withTimeInterval: 1.0 / 60, repeats: true) { _ in nuloq.tick() }
log(monitor ? "Monitoring NuLOOQ input — Ctrl-C to stop." : "nulooqd running (config: \(configPath))")
RunLoop.main.run()
