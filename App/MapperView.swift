import AppKit
import SwiftUI
import UniformTypeIdentifiers

func appIcon(_ bundleID: String?) -> NSImage? {
    guard let b = bundleID, let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: b) else { return nil }
    return NSWorkspace.shared.icon(forFile: url.path)
}

private func doubleBinding(_ b: Binding<Int>) -> Binding<Double> {
    Binding(get: { Double(b.wrappedValue) }, set: { b.wrappedValue = Int($0.rounded()) })
}

// MARK: - Main window

struct MapperView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var driver: Driver
    @State private var selection: UUID?

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section("General") {
                    ProfileRow(profile: store.config.general).tag(store.config.general.id)
                }
                Section("Apps") {
                    ForEach(store.config.apps) { p in
                        ProfileRow(profile: p).tag(p.id)
                            .contextMenu { Button("Delete Profile", role: .destructive) { delete(p.id) } }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) { sidebarFooter }
            .navigationSplitViewColumnWidth(min: 220, ideal: 250)
        } detail: {
            VStack(spacing: 0) {
                if !driver.axTrusted { accessibilityBanner }
                if let binding = profileBinding(selection) {
                    ProfileEditor(profile: binding)
                } else {
                    ContentUnavailableView("Select a profile", systemImage: "circle.circle")
                }
            }
        }
        .toolbar {
            ToolbarItem {
                Toggle(isOn: $store.config.enabled) {
                    Label(store.config.enabled ? "Mapping On" : "Mapping Paused",
                          systemImage: store.config.enabled ? "play.circle.fill" : "pause.circle")
                }
                .help("Pause to try the controls without triggering actions")
            }
        }
        .onAppear {
            if selection == nil { selection = store.config.general.id }
            NSApp.setActivationPolicy(.regular)
            NSApp.activate()
        }
        .onDisappear { NSApp.setActivationPolicy(.accessory) }
    }

    private var accessibilityBanner: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.yellow)
            Text("Halo needs Accessibility permission to send keystrokes and scrolling.")
            Spacer()
            Button("Open Settings") {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
            }
        }
        .padding(10)
        .background(.yellow.opacity(0.15))
    }

    private var sidebarFooter: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
            HStack(spacing: 4) {
                Menu {
                    let running = runningApps()
                    if !running.isEmpty {
                        Section("Running Apps") {
                            ForEach(running, id: \.bundleIdentifier) { app in
                                Button(app.localizedName ?? app.bundleIdentifier!) {
                                    add(bundleID: app.bundleIdentifier!, name: app.localizedName ?? app.bundleIdentifier!)
                                }
                            }
                        }
                    }
                    let presets = Presets.apps.filter { p in !store.config.apps.contains { $0.bundleID == p.bundleID } }
                    if !presets.isEmpty {
                        Section("Presets") {
                            ForEach(presets) { p in
                                Button(p.name) { add(bundleID: p.bundleID!, name: p.name) }
                            }
                        }
                    }
                    Divider()
                    Button("Choose Application…") { chooseApp() }
                } label: {
                    Image(systemName: "plus")
                }
                .menuIndicator(.hidden)
                .fixedSize()
                .help("Add an app profile")

                Button {
                    if let s = selection { delete(s) }
                } label: { Image(systemName: "minus") }
                .disabled(selection == nil || selection == store.config.general.id)
                .help("Delete the selected app profile")
                Spacer()
            }
            .buttonStyle(.borderless)
            Picker("Button lights", selection: $store.config.ledMode) {
                Text("Off").tag(LEDMode.off)
                Text("While pressed").tag(LEDMode.pressed)
                Text("Always on").tag(LEDMode.always)
            }
            .font(.callout)
        }
        .padding([.horizontal, .bottom], 10)
    }

    private func profileBinding(_ id: UUID?) -> Binding<Profile>? {
        guard let id else { return nil }
        if id == store.config.general.id { return $store.config.general }
        guard store.config.apps.contains(where: { $0.id == id }) else { return nil }
        return Binding(
            get: { store.config.apps.first { $0.id == id } ?? store.config.general },
            set: { new in
                if let i = store.config.apps.firstIndex(where: { $0.id == id }) { store.config.apps[i] = new }
            })
    }

    private func runningApps() -> [NSRunningApplication] {
        NSWorkspace.shared.runningApplications
            .filter { app in
                guard app.activationPolicy == .regular, let b = app.bundleIdentifier else { return false }
                return b != Bundle.main.bundleIdentifier && !store.config.apps.contains { $0.bundleID == b }
            }
            .sorted { ($0.localizedName ?? "") < ($1.localizedName ?? "") }
    }

    private func add(bundleID: String, name: String) {
        if let existing = store.config.apps.first(where: { $0.bundleID == bundleID }) {
            selection = existing.id
            return
        }
        var p = Presets.preset(for: bundleID) ?? store.config.general
        p.id = UUID()
        p.bundleID = bundleID
        p.name = name
        p.enabled = true
        store.config.apps.append(p)
        selection = p.id
    }

    private func delete(_ id: UUID) {
        store.config.apps.removeAll { $0.id == id }
        if selection == id { selection = store.config.general.id }
    }

    private func chooseApp() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        guard panel.runModal() == .OK, let url = panel.url, let bundle = Bundle(url: url),
              let id = bundle.bundleIdentifier else { return }
        let name = FileManager.default.displayName(atPath: url.path).replacingOccurrences(of: ".app", with: "")
        add(bundleID: id, name: name)
    }
}

struct ProfileRow: View {
    let profile: Profile
    var body: some View {
        HStack {
            if let icon = appIcon(profile.bundleID) {
                Image(nsImage: icon).resizable().frame(width: 20, height: 20)
            } else {
                Image(systemName: profile.bundleID == nil ? "macwindow" : "app.dashed")
                    .frame(width: 20, height: 20)
            }
            Text(profile.name)
                .foregroundStyle(profile.enabled ? .primary : .secondary)
        }
    }
}

// MARK: - Profile editor

struct ProfileEditor: View {
    @Binding var profile: Profile
    @EnvironmentObject var driver: Driver

    var body: some View {
        Form {
            Section {
                HStack(spacing: 12) {
                    if let icon = appIcon(profile.bundleID) {
                        Image(nsImage: icon).resizable().frame(width: 40, height: 40)
                    } else {
                        Image(systemName: "macwindow").font(.system(size: 30)).frame(width: 40, height: 40)
                    }
                    VStack(alignment: .leading) {
                        Text(profile.name).font(.title2.bold())
                        Text(profile.bundleID == nil
                             ? "Used in every app that doesn't have its own profile."
                             : "Active whenever \(profile.name) is the frontmost app.")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if profile.bundleID != nil {
                        Toggle("Enabled", isOn: $profile.enabled).toggleStyle(.switch)
                    }
                }
                LiveDeviceView(live: driver.live, activeProfile: driver.profile.name)
            }

            Section("Buttons") {
                ForEach(0..<5, id: \.self) { i in
                    ActionRow(label: "Button \(i + 1)", lit: driver.live.buttons.contains(i + 1),
                              action: $profile.buttons[i])
                }
            }

            Section {
                Picker("Ring does", selection: $profile.ring.mode) {
                    Text("Actions").tag("actions")
                    Text("Scroll").tag("scroll")
                    Text("Nothing").tag("none")
                }
                if profile.ring.mode == "actions" {
                    ActionRow(label: "Slide clockwise ↻", action: $profile.ring.positive)
                    ActionRow(label: "Slide counter-clockwise ↺", action: $profile.ring.negative)
                    LabeledContent("Slide distance per step") {
                        Slider(value: doubleBinding($profile.ring.step), in: 30...600) {
                            EmptyView()
                        } minimumValueLabel: { Text("Short") } maximumValueLabel: { Text("Long") }
                    }
                } else if profile.ring.mode == "scroll" {
                    LabeledContent("Scroll speed") {
                        Slider(value: $profile.ring.scrollSpeed, in: 0.2...3)
                    }
                }
            } header: {
                SectionHeader(title: "Touch ring", lit: driver.live.ringTouched) {
                    (profile.ring.positive, profile.ring.negative) = (profile.ring.negative, profile.ring.positive)
                }
            }

            Section {
                ActionRow(label: "Twist clockwise ↻", action: $profile.twist.positive)
                ActionRow(label: "Twist counter-clockwise ↺", action: $profile.twist.negative)
                LabeledContent("Twist needed") {
                    Slider(value: doubleBinding($profile.twist.threshold), in: 30...450) {
                        EmptyView()
                    } minimumValueLabel: { Text("Light") } maximumValueLabel: { Text("Firm") }
                }
                LabeledContent("Repeat while held") {
                    Slider(value: doubleBinding($profile.twist.repeatMs), in: 80...1000) {
                        EmptyView()
                    } minimumValueLabel: { Text("Fast") } maximumValueLabel: { Text("Slow") }
                }
            } header: {
                SectionHeader(title: "Puck twist", lit: abs(driver.live.twist) > profile.twist.threshold) {
                    (profile.twist.positive, profile.twist.negative) = (profile.twist.negative, profile.twist.positive)
                }
            }

            Section {
                Picker("Pushing the puck", selection: $profile.puck.mode) {
                    Text("Scrolls").tag("scroll")
                    Text("Moves the pointer").tag("mouse")
                    Text("Does nothing").tag("none")
                }
                if profile.puck.mode != "none" {
                    LabeledContent("Speed") {
                        Slider(value: $profile.puck.speed, in: 0.2...4) {
                            EmptyView()
                        } minimumValueLabel: { Text("Slow") } maximumValueLabel: { Text("Fast") }
                    }
                    LabeledContent("Dead zone") {
                        Slider(value: doubleBinding($profile.puck.deadzone), in: 0...150) {
                            EmptyView()
                        } minimumValueLabel: { Text("Small") } maximumValueLabel: { Text("Large") }
                    }
                    Toggle("Reverse horizontal", isOn: $profile.puck.invertX)
                    Toggle("Reverse vertical", isOn: $profile.puck.invertY)
                }
            } header: {
                SectionHeader(title: "Puck push",
                              lit: abs(driver.live.x) > profile.puck.deadzone || abs(driver.live.y) > profile.puck.deadzone)
            }
        }
        .formStyle(.grouped)
        .navigationTitle(profile.name)
    }
}

struct SectionHeader: View {
    let title: String
    var lit = false
    var onSwap: (() -> Void)?

    var body: some View {
        HStack {
            Circle().fill(lit ? Color.accentColor : Color.secondary.opacity(0.25)).frame(width: 8, height: 8)
            Text(title)
            Spacer()
            if let onSwap {
                Button("Swap directions", systemImage: "arrow.left.arrow.right", action: onSwap)
                    .buttonStyle(.borderless)
                    .font(.callout)
            }
        }
    }
}

// MARK: - Action editing

struct ActionRow: View {
    let label: String
    var lit = false
    @Binding var action: String

    var body: some View {
        let spec = ActionSpec(action)
        LabeledContent {
            HStack {
                Picker("", selection: Binding(
                    get: { spec.kind },
                    set: { k in if k != spec.kind { action = ActionSpec(kind: k, value: k.defaultValue).string } }
                )) {
                    ForEach(ActionKind.allCases) { Text($0.label).tag($0) }
                }
                .labelsHidden()
                .frame(width: 170)
                editor(spec)
                    .frame(minWidth: 170, alignment: .leading)
            }
        } label: {
            HStack {
                Circle().fill(lit ? Color.accentColor : Color.secondary.opacity(0.25)).frame(width: 8, height: 8)
                Text(label)
            }
        }
    }

    private func set(_ spec: ActionSpec, _ value: String) {
        action = ActionSpec(kind: spec.kind, value: value).string
    }

    @ViewBuilder
    private func editor(_ spec: ActionSpec) -> some View {
        switch spec.kind {
        case .none:
            Color.clear.frame(height: 1)
        case .key:
            ShortcutRecorder(combo: Binding(get: { spec.value }, set: { set(spec, $0) }))
        case .media:
            Picker("", selection: Binding(get: { spec.value }, set: { set(spec, $0) })) {
                ForEach(mediaKeyNames, id: \.id) { Text($0.label).tag($0.id) }
            }
            .labelsHidden()
        case .click:
            Picker("", selection: Binding(get: { spec.value }, set: { set(spec, $0) })) {
                Text("Left click").tag("left")
                Text("Right click").tag("right")
                Text("Middle click").tag("middle")
            }
            .labelsHidden()
        case .open:
            HStack {
                Text(spec.value.isEmpty ? "Nothing chosen" : FileManager.default.displayName(atPath: spec.value))
                    .lineLimit(1).truncationMode(.middle)
                    .foregroundStyle(spec.value.isEmpty ? .secondary : .primary)
                Button("Choose…") {
                    let panel = NSOpenPanel()
                    panel.canChooseDirectories = true
                    panel.directoryURL = URL(fileURLWithPath: "/Applications")
                    if panel.runModal() == .OK, let url = panel.url { set(spec, url.path) }
                }
            }
        case .shell:
            TextField("", text: Binding(get: { spec.value }, set: { set(spec, $0) }),
                      prompt: Text("e.g. open -a Calculator"))
                .font(.system(.body, design: .monospaced))
        }
    }
}

struct ShortcutRecorder: View {
    @Binding var combo: String
    @State private var recording = false
    @State private var monitor: Any?

    var body: some View {
        Button {
            recording ? stop() : start()
        } label: {
            Text(recording ? "Press a shortcut…" : (combo.isEmpty ? "Click to record" : Shortcut.display(combo)))
                .font(recording || combo.isEmpty ? .body : .system(.body, design: .rounded).weight(.semibold))
                .frame(minWidth: 140)
        }
        .buttonStyle(.bordered)
        .tint(recording ? Color.accentColor : nil)
        .help("Click, then press the key combination. Click again to cancel.")
        .onDisappear { stop() }
    }

    private func start() {
        recording = true
        Driver.shared.suspended = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { e in
            combo = Shortcut.combo(from: e)
            stop()
            return nil
        }
    }

    private func stop() {
        if let m = monitor { NSEvent.removeMonitor(m) }
        monitor = nil
        recording = false
        Driver.shared.suspended = false
    }
}

// MARK: - Live device view

struct LiveDeviceView: View {
    let live: LiveState
    let activeProfile: String

    var body: some View {
        HStack(spacing: 28) {
            ZStack {
                Circle()
                    .stroke(live.ringTouched ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: 10)
                    .frame(width: 110, height: 110)
                if live.ringTouched, let a = live.ringAngle {
                    Circle().fill(Color.white).frame(width: 8, height: 8)
                        .offset(y: -55)
                        .rotationEffect(.degrees(-Double(a) / 4096 * 360))
                }
                ZStack {
                    Circle().fill(Color.secondary.opacity(0.35)).frame(width: 54, height: 54)
                    Capsule().fill(Color.primary.opacity(0.7)).frame(width: 3, height: 18).offset(y: -15)
                }
                .rotationEffect(.degrees(Double(live.twist) / 512 * 60))
                .offset(x: CGFloat(live.x) / 512 * 18, y: CGFloat(live.y) / 512 * 18)
            }
            .frame(width: 130, height: 130)
            .animation(.easeOut(duration: 0.08), value: live)

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    ForEach(1...5, id: \.self) { b in
                        let on = live.buttons.contains(b)
                        Text("\(b)")
                            .font(.callout.bold())
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(on ? Color.accentColor : Color.secondary.opacity(0.2)))
                            .foregroundStyle(on ? Color.white : Color.primary)
                    }
                }
                Label(live.connected ? "NuLOOQ connected" : "NuLOOQ not connected",
                      systemImage: live.connected ? "checkmark.circle.fill" : "xmark.circle")
                    .foregroundStyle(live.connected ? .green : .red)
                Text("Touch any control to see which setting it uses. Active profile: \(activeProfile)")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}
