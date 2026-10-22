import AppKit
import ServiceManagement
import SwiftUI

/// Lets the app delegate open the mapper window (e.g. when the app is re-launched from Finder).
enum WindowOpener {
    static var open: (() -> Void)?
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        Driver.shared.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        Driver.shared.lightsOff()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        WindowOpener.open?()
        return true
    }
}

@main
struct HaloApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @StateObject private var store = Store.shared
    @StateObject private var driver = Driver.shared

    // Show the window when opened by hand, but stay quietly in the menu bar when launched at login.
    private let showAtLaunch = Store.shared.firstRun || SMAppService.mainApp.status != .enabled

    var body: some Scene {
        Window("Halo", id: "mapper") {
            MapperView()
                .environmentObject(store)
                .environmentObject(driver)
                .frame(minWidth: 820, minHeight: 560)
        }
        .defaultSize(width: 940, height: 720)
        .defaultLaunchBehavior(showAtLaunch ? .presented : .suppressed)

        MenuBarExtra {
            MenuContent()
                .environmentObject(store)
                .environmentObject(driver)
        } label: {
            MenuLabel()
        }
    }
}

struct MenuLabel: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Image(systemName: "circle.circle")
            .onAppear {
                WindowOpener.open = {
                    openWindow(id: "mapper")
                    NSApp.activate()
                }
            }
    }
}

struct MenuContent: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var driver: Driver
    @Environment(\.openWindow) private var openWindow
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        Text(driver.live.connected ? "NuLOOQ connected" : "NuLOOQ not connected")
        Text("Profile: \(driver.profile.name)")
        Divider()
        Toggle("Mapping Enabled", isOn: $store.config.enabled)
        Button("Open Mapper…") {
            openWindow(id: "mapper")
            NSApp.activate()
        }
        .keyboardShortcut(",")
        Toggle("Launch at Login", isOn: Binding(
            get: { launchAtLogin },
            set: { on in
                do {
                    if on { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
                } catch {
                    NSLog("Launch at login: \(error)")
                }
                launchAtLogin = SMAppService.mainApp.status == .enabled
            }))
        Divider()
        Button("Quit Halo") { NSApp.terminate(nil) }
            .keyboardShortcut("q")
    }
}
