// Renders the Halo intro video as raw RGBA frames on stdout.
//   swiftc -O render.swift -o render && ./render <screenshots dir> [pace] | ffmpeg -f rawvideo -pix_fmt rgba -s 1920x1080 -r 30 -i - ...
import AppKit

let W = 1920.0, H = 1080.0, fps = 30.0, total = 43.0
let shots = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "docs/screenshots/profiles"
/// Pacing: 1 = original 43 s cut; 1.5 plays everything half again as slowly.
let pace = CommandLine.arguments.count > 2 ? Double(CommandLine.arguments[2])! : 1.0

// MARK: - Helpers

let accent = NSColor(calibratedRed: 0.29, green: 0.62, blue: 1.0, alpha: 1)
let ink = NSColor(calibratedWhite: 0.96, alpha: 1)
let muted = NSColor(calibratedWhite: 0.62, alpha: 1)

func clamp(_ x: Double) -> Double { min(max(x, 0), 1) }
func ease(_ x: Double) -> Double { let t = clamp(x); return t * t * (3 - 2 * t) }
/// Opacity for something visible from `a` to `b`, fading in/out over `f` seconds.
func vis(_ t: Double, _ a: Double, _ b: Double, _ f: Double = 0.6) -> Double {
    ease((t - a) / f) * (1 - ease((t - (b - f)) / f))
}

func loadImage(_ name: String) -> CGImage? {
    guard let img = NSImage(contentsOfFile: "\(shots)/\(name).png") else { return nil }
    return img.cgImage(forProposedRect: nil, context: nil, hints: nil)
}

func text(_ s: String, size: Double, weight: NSFont.Weight = .regular, color: NSColor = ink,
          alpha: Double, y: Double, x: Double = W / 2, align: NSTextAlignment = .center,
          kern: Double = 0, rise: Double = 0) {
    guard alpha > 0.001 else { return }
    let font = NSFont.systemFont(ofSize: size, weight: weight)
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font, .foregroundColor: color.withAlphaComponent(alpha), .kern: kern,
    ]
    let str = NSAttributedString(string: s, attributes: attrs)
    let sz = str.size()
    let ox: Double = switch align {
    case .center: x - sz.width / 2
    case .right: x - sz.width
    default: x
    }
    str.draw(at: NSPoint(x: ox, y: y - sz.height / 2 + (1 - alpha) * rise))
}

func drawImage(_ ctx: CGContext, _ img: CGImage, in r: CGRect, alpha: Double) {
    guard alpha > 0.001 else { return }
    ctx.saveGState()
    ctx.setAlpha(alpha)
    ctx.translateBy(x: r.minX, y: r.maxY)
    ctx.scaleBy(x: 1, y: -1)
    ctx.interpolationQuality = .high
    ctx.draw(img, in: CGRect(x: 0, y: 0, width: r.width, height: r.height))
    ctx.restoreGState()
}

/// The NuLOOQ: a touch ring around a puck. `glow` 0 = dead, 1 = alive.
func device(_ ctx: CGContext, cx: Double, cy: Double, r: Double, glow: Double, alpha: Double, spin: Double = 0) {
    guard alpha > 0.001 else { return }
    ctx.saveGState()
    ctx.setAlpha(alpha)
    let ringW = r * 0.22
    let dead = NSColor(calibratedWhite: 0.22, alpha: 1)
    let ringColor = dead.blended(withFraction: glow, of: accent)!
    if glow > 0.01 {   // halo glow
        ctx.setShadow(offset: .zero, blur: r * 0.6 * glow, color: accent.withAlphaComponent(0.85 * glow).cgColor)
    }
    ctx.setStrokeColor(ringColor.cgColor)
    ctx.setLineWidth(ringW)
    ctx.strokeEllipse(in: CGRect(x: cx - r, y: cy - r, width: 2 * r, height: 2 * r))
    ctx.setShadow(offset: .zero, blur: 0)
    // light travelling around the ring
    if glow > 0.01 {
        let a = spin * 2 * .pi - .pi / 2
        let p = CGPoint(x: cx + cos(a) * r, y: cy + sin(a) * r)
        ctx.setFillColor(NSColor.white.withAlphaComponent(0.9 * glow).cgColor)
        ctx.setShadow(offset: .zero, blur: ringW, color: NSColor.white.withAlphaComponent(glow).cgColor)
        ctx.fillEllipse(in: CGRect(x: p.x - ringW * 0.32, y: p.y - ringW * 0.32, width: ringW * 0.64, height: ringW * 0.64))
        ctx.setShadow(offset: .zero, blur: 0)
    }
    // puck
    let pr = r * 0.55
    let puck = CGRect(x: cx - pr, y: cy - pr, width: 2 * pr, height: 2 * pr)
    ctx.saveGState()
    ctx.addEllipse(in: puck); ctx.clip()
    let top = NSColor(calibratedWhite: 0.30 + 0.45 * glow, alpha: 1)
    let bottom = NSColor(calibratedWhite: 0.12 + 0.30 * glow, alpha: 1)
    let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [top.cgColor, bottom.cgColor] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(grad, start: CGPoint(x: cx, y: puck.minY), end: CGPoint(x: cx, y: puck.maxY), options: [])
    ctx.restoreGState()
    // puck notch
    ctx.setFillColor(NSColor(calibratedWhite: 0.05, alpha: 0.6).cgColor)
    let nw = pr * 0.09, nh = pr * 0.38
    ctx.fill(CGRect(x: cx - nw / 2, y: cy - pr * 0.82, width: nw, height: nh))
    ctx.restoreGState()
}

// MARK: - Assets

let general = loadImage("00-general")
let profiles: [(String, String)] = [
    ("01-safari", "Safari"), ("07-lightroom-classic", "Lightroom Classic"), ("11-spotify", "Spotify"),
    ("13-keynote", "Keynote"), ("16-xcode", "Xcode"), ("19-garageband", "GarageBand"), ("20-ghostty", "Ghostty"),
]
let profileImages: [CGImage] = profiles.compactMap { name, _ in
    guard let img = loadImage(name) else { return nil }
    // Keep the top of the window: header, live view, buttons and touch ring.
    return img.cropping(to: CGRect(x: 0, y: 0, width: img.width, height: Int(Double(img.height) * 0.60)))
}

// MARK: - Frame

let ctx = CGContext(data: nil, width: Int(W), height: Int(H), bitsPerComponent: 8, bytesPerRow: Int(W) * 4,
                    space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
ctx.translateBy(x: 0, y: H)
ctx.scaleBy(x: 1, y: -1)   // top-left origin
NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: true)

let bg = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                    colors: [NSColor(calibratedRed: 0.07, green: 0.08, blue: 0.10, alpha: 1).cgColor,
                             NSColor(calibratedRed: 0.02, green: 0.02, blue: 0.03, alpha: 1).cgColor] as CFArray,
                    locations: [0, 1])!

func render(_ t: Double) {
    ctx.drawRadialGradient(bg, startCenter: CGPoint(x: W / 2, y: H * 0.4), startRadius: 0,
                           endCenter: CGPoint(x: W / 2, y: H * 0.4), endRadius: W * 0.75, options: [.drawsAfterEndLocation])

    // 1. 2006
    let s1 = vis(t, 0.2, 5.0, 0.8)
    device(ctx, cx: W / 2, cy: 400, r: 150, glow: 0.12 * s1, alpha: s1)
    text("2006", size: 120, weight: .bold, alpha: vis(t, 0.8, 5.0, 0.7), y: 690, kern: 6, rise: 20)
    text("Logitech NuLOOQ Navigator", size: 40, weight: .light, color: muted, alpha: vis(t, 1.8, 5.0, 0.7), y: 800, kern: 2)

    // 2. The fall
    let lines = ["Discontinued in under a year.", "Then the Mac moved on.", "PowerPC. 32-bit. Gone."]
    for (i, l) in lines.enumerated() {
        let start = 5.4 + Double(i) * 1.5
        text(l, size: i == 2 ? 64 : 56, weight: i == 2 ? .semibold : .regular, color: i == 2 ? ink : muted,
             alpha: vis(t, start, 11.0, 0.6), y: 420 + Double(i) * 110, rise: 18)
    }

    // 3. Twenty years
    let s3 = vis(t, 11.2, 14.4, 0.8)
    device(ctx, cx: W / 2, cy: 430, r: 120, glow: 0, alpha: s3 * 0.55)
    text("Twenty years in a drawer.", size: 60, weight: .medium, alpha: vis(t, 11.6, 14.4, 0.8), y: 720)

    // 4. Until now → Halo
    text("Until now.", size: 84, weight: .semibold, alpha: vis(t, 14.6, 16.4, 0.5), y: H / 2, rise: 12)
    let s4 = vis(t, 16.2, 20.0, 0.5)
    let glow4 = ease((t - 16.3) / 1.4)
    device(ctx, cx: W / 2, cy: 400, r: 165, glow: glow4, alpha: s4, spin: (t - 16.3) * 0.35)
    text("Halo", size: 150, weight: .bold, alpha: vis(t, 17.3, 20.0, 0.7), y: 720, kern: 8, rise: 24)
    text("A modern macOS driver for the NuLOOQ Navigator", size: 36, weight: .light, color: muted,
         alpha: vis(t, 18.0, 20.0, 0.6), y: 830, kern: 1)

    // 5. The app
    let s5 = vis(t, 20.0, 26.2, 0.7)
    if let g = general, s5 > 0 {
        let h = 980.0 * (1 + 0.04 * clamp((t - 20) / 6))
        let w = h * Double(g.width) / Double(g.height)
        drawImage(ctx, g, in: CGRect(x: 1230 - w / 2, y: H / 2 - h / 2 + (1 - s5) * 30, width: w, height: h), alpha: s5)
    }
    text("Map every control.", size: 64, weight: .bold, alpha: vis(t, 20.4, 26.2, 0.6), y: 430, x: 140, align: .left, rise: 16)
    for (i, l) in ["Push the puck", "Twist the puck", "Slide around the ring", "Five buttons"].enumerated() {
        text(l, size: 38, weight: .regular, color: muted, alpha: vis(t, 21.2 + Double(i) * 0.45, 26.2, 0.5),
             y: 530 + Double(i) * 60, x: 140, align: .left, rise: 10)
    }

    // 6. Profiles
    let pStart = 26.2, per = 1.05
    let s6 = vis(t, pStart, 34.0, 0.6)
    text("Every app gets", size: 60, weight: .bold, alpha: s6, y: 440, x: 140, align: .left)
    text("its own profile.", size: 60, weight: .bold, color: accent, alpha: s6, y: 515, x: 140, align: .left)
    text("Halo switches the moment you do.", size: 34, weight: .regular, color: muted, alpha: vis(t, pStart + 0.6, 34.0, 0.6), y: 600, x: 140, align: .left)
    if s6 > 0 && !profileImages.isEmpty {
        let local = max(0, t - pStart - 0.3)
        let i = min(Int(local / per), profileImages.count - 1)
        let frac = local / per - Double(i)
        let cross = i < profileImages.count - 1 ? ease((frac - 0.78) / 0.22) : 0
        for (k, a) in [(i, 1 - cross), (min(i + 1, profileImages.count - 1), cross)] where a > 0.001 {
            let img = profileImages[k]
            let w = 1020.0, h = w * Double(img.height) / Double(img.width)
            drawImage(ctx, img, in: CGRect(x: 1290 - w / 2, y: H / 2 - h / 2 - 20, width: w, height: h), alpha: s6 * a)
            text(profiles[k].1, size: 30, weight: .semibold, color: accent, alpha: s6 * a, y: H / 2 + h / 2 + 10, x: 1290)
        }
    }

    // 7. Features
    let feats = ["Keyboard shortcuts & media keys", "Mouse clicks, apps & shell commands", "A live view of the device",
                 "Auto-recentring for tired springs", "Button lights that sleep with your Mac"]
    text("More than it ever did in 2006.", size: 58, weight: .bold, alpha: vis(t, 34.2, 39.2, 0.6), y: 300, rise: 14)
    for (i, f) in feats.enumerated() {
        let a = vis(t, 34.9 + Double(i) * 0.4, 39.2, 0.5)
        let y = 440 + Double(i) * 82
        if a > 0 {
            ctx.setFillColor(accent.withAlphaComponent(a).cgColor)
            ctx.fillEllipse(in: CGRect(x: 640, y: y - 9, width: 18, height: 18))
        }
        text(f, size: 42, color: ink, alpha: a, y: y, x: 685, align: .left, rise: 10)
    }

    // 8. Close
    let s8 = vis(t, 39.4, total, 0.8) * (1 - ease((t - 42.0) / 1.0))
    device(ctx, cx: W / 2, cy: 380, r: 140, glow: 1, alpha: s8, spin: (t - 39.4) * 0.35)
    text("Halo", size: 120, weight: .bold, alpha: s8, y: 660, kern: 6)
    text("A twenty-year-old friend, back to life.", size: 44, weight: .light, alpha: vis(t, 40.0, total, 0.7) * (1 - ease((t - 42.0) / 1.0)), y: 770)
}

let out = FileHandle.standardOutput
let frames = Int(total * pace * fps)
for f in 0..<frames {
    autoreleasepool {
        render(Double(f) / fps / pace)
        out.write(Data(bytes: ctx.data!, count: Int(W * H * 4)))
    }
}
