import AppKit
import Combine
import ApplicationServices
import Foundation
import IOKit.hid

struct LiveState: Equatable {
    var connected = false
    var x = 0, y = 0, twist = 0
    var ringAngle: Int?
    var ringTouched = false
    var buttons = Set<Int>()
}

/// Reads the NuLOOQ Navigator (046d:c640) and runs the active profile's actions.
final class Driver: ObservableObject {
    static let shared = Driver()

    @Published private(set) var live = LiveState()
    @Published private(set) var frontBundleID: String?
    @Published private(set) var axTrusted = AXIsProcessTrusted()
    /// Set while the mapper records a shortcut, so the device doesn't fire actions.
    var suspended = false

    private let store = Store.shared
    private var manager: IOHIDManager?
    private var device: IOHIDDevice?
    private var state = LiveState()
    private var ringAccum = 0.0
    private var twistLastFire = Date.distantPast
    private var remX = 0.0, remY = 0.0
    // The puck's worn spring can rest off-centre and creep back slowly, so learn its
    // resting point: if it holds still near the middle for a moment, treat that as centre.
    private var rawX = 0, rawY = 0, restX = 0, restY = 0
    private var stillX = 0, stillY = 0, stillSince = Date()

    private var displayAsleep = false
    private var configObserver: Any?

    var profile: Profile { store.profile(for: frontBundleID) }
    private var active: Bool { store.config.enabled && !suspended }

    func start() {
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        axTrusted = AXIsProcessTrustedWithOptions(opts)

        frontBundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main
        ) { [weak self] n in
            let app = n.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            self?.frontBundleID = app?.bundleIdentifier
        }

        // "Always on" LEDs go dark while the display or the Mac sleeps.
        let nc = NSWorkspace.shared.notificationCenter
        for (name, asleep) in [(NSWorkspace.screensDidSleepNotification, true),
                               (NSWorkspace.willSleepNotification, true),
                               (NSWorkspace.screensDidWakeNotification, false),
                               (NSWorkspace.didWakeNotification, false)] {
            nc.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                self?.displayAsleep = asleep
                self?.setLEDs()
            }
        }
        configObserver = store.$config
            .map(\.ledMode).removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.setLEDs() }

        let m = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        IOHIDManagerSetDeviceMatching(m, [kIOHIDVendorIDKey: 0x046d, kIOHIDProductIDKey: 0xc640] as CFDictionary)
        IOHIDManagerRegisterDeviceMatchingCallback(m, { _, _, _, device in
            Driver.shared.attached(device)
        }, nil)
        IOHIDManagerRegisterDeviceRemovalCallback(m, { _, _, _, _ in
            Driver.shared.detached()
        }, nil)
        IOHIDManagerRegisterInputValueCallback(m, { _, _, _, value in
            let el = IOHIDValueGetElement(value)
            Driver.shared.input(page: IOHIDElementGetUsagePage(el), usage: IOHIDElementGetUsage(el),
                                v: IOHIDValueGetIntegerValue(value))
        }, nil)
        IOHIDManagerScheduleWithRunLoop(m, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        IOHIDManagerOpen(m, IOOptionBits(kIOHIDOptionsTypeNone))
        manager = m

        Timer.scheduledTimer(withTimeInterval: 1.0 / 60, repeats: true) { [weak self] _ in self?.tick() }
        Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            let t = AXIsProcessTrusted()
            if self?.axTrusted != t { self?.axTrusted = t }
        }
    }

    private func attached(_ d: IOHIDDevice) {
        device = d
        state.connected = true
        setLEDs()
    }

    private func detached() {
        device = nil
        state = LiveState()
        rawX = 0; rawY = 0; restX = 0; restY = 0
    }

    private func input(page: UInt32, usage: UInt32, v: Int) {
        switch (page, usage) {
        case (1, 0x30): rawX = v; state.x = v - restX
        case (1, 0x31): rawY = v; state.y = v - restY
        case (1, 0x35): state.twist = v
        case (1, 0x32): ring(angle: v)
        case (0x0d, 0x30):
            state.ringTouched = v > 0
            if !state.ringTouched { state.ringAngle = nil; ringAccum = 0 }
        case (9, let b) where (1...8).contains(b):
            if v != 0 {
                state.buttons.insert(Int(b))
                let p = profile
                if active, Int(b) <= p.buttons.count { ActionRunner.perform(p.buttons[Int(b) - 1]) }
            } else {
                state.buttons.remove(Int(b))
            }
            setLEDs()
        default: break
        }
    }

    private func ring(angle: Int) {
        defer { state.ringAngle = angle }
        guard let prev = state.ringAngle else { return }
        var d = angle - prev
        if d > 2048 { d -= 4096 } else if d < -2048 { d += 4096 }   // wrap-around
        d = -d                                                       // hardware angle grows counter-clockwise
        let r = profile.ring
        guard active, r.mode != "none" else { return }
        if r.mode == "scroll" {
            ActionRunner.scroll(dx: 0, dy: Int32(Double(d) * r.scrollSpeed))
            return
        }
        ringAccum += Double(d)
        let step = Double(max(r.step, 1))
        while ringAccum >= step { ringAccum -= step; ActionRunner.perform(r.positive) }
        while ringAccum <= -step { ringAccum += step; ActionRunner.perform(r.negative) }
    }

    // The puck and twist are spring-loaded, so act on held deflection ~60×/s.
    private func tick() {
        recenter()
        if live != state { live = state }
        guard active else { return }
        let p = profile
        let dz = p.puck.deadzone
        func curve(_ v: Int) -> Double {
            guard abs(v) > dz else { return 0 }
            let n = Double(abs(v) - dz) / Double(max(512 - dz, 1))
            return (v < 0 ? -1 : 1) * n * n * 40 * p.puck.speed   // quadratic for fine control
        }
        let fx = curve(state.x) * (p.puck.invertX ? -1 : 1)
        let fy = curve(state.y) * (p.puck.invertY ? -1 : 1)
        if fx != 0 || fy != 0 {
            switch p.puck.mode {
            case "scroll":
                remX -= fx; remY -= fy
                let ix = Int32(remX), iy = Int32(remY)
                remX -= Double(ix); remY -= Double(iy)
                if ix != 0 || iy != 0 { ActionRunner.scroll(dx: ix, dy: iy) }
            case "mouse":
                ActionRunner.moveMouse(dx: fx / 2, dy: fy / 2)
            default: break
            }
        }
        if abs(state.twist) > p.twist.threshold,
           Date().timeIntervalSince(twistLastFire) * 1000 >= Double(p.twist.repeatMs) {
            twistLastFire = Date()
            ActionRunner.perform(state.twist > 0 ? p.twist.positive : p.twist.negative)
        }
    }

    func lightsOff() {
        guard let d = device else { return }
        var report: [UInt8] = [4, 0]
        IOHIDDeviceSetReport(d, kIOHIDReportTypeOutput, 4, &report, report.count)
    }

    private func recenter() {
        if abs(rawX - stillX) > 4 || abs(rawY - stillY) > 4 {
            stillX = rawX; stillY = rawY; stillSince = Date()
        } else if (rawX != restX || rawY != restY), abs(rawX) < 160, abs(rawY) < 160,
                  Date().timeIntervalSince(stillSince) > 0.8 {
            restX = rawX; restY = rawY
            state.x = 0; state.y = 0
        }
    }

    /// Output report 4 holds 5 LED bits, one per button.
    /// While pressed: light the held button. Always on: all lit, the held button blinks off.
    func setLEDs() {
        guard let d = device else { return }
        var held: UInt8 = 0
        for b in state.buttons where b <= 5 { held |= 1 << (b - 1) }
        let bits: UInt8 = switch store.config.ledMode {
        case .off: 0
        case .pressed: held
        case .always: displayAsleep ? 0 : 0x1f & ~held
        }
        var report: [UInt8] = [4, bits]
        IOHIDDeviceSetReport(d, kIOHIDReportTypeOutput, 4, &report, report.count)
    }
}
