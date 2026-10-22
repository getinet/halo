// Renders the Halo app icon into an .iconset folder: swift makeicon.swift <out.iconset>
import AppKit

let out = CommandLine.arguments[1]
try? FileManager.default.createDirectory(atPath: out, withIntermediateDirectories: true)

func render(_ px: Int) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let s = CGFloat(px)
    let inset = s * 0.1
    let body = NSRect(x: inset, y: inset, width: s - 2 * inset, height: s - 2 * inset)
    NSGradient(starting: NSColor(calibratedWhite: 0.30, alpha: 1), ending: NSColor(calibratedWhite: 0.10, alpha: 1))!
        .draw(in: NSBezierPath(roundedRect: body, xRadius: body.width * 0.225, yRadius: body.width * 0.225), angle: -90)
    let c = NSPoint(x: s / 2, y: s / 2)
    // touch ring
    let ringR = s * 0.27
    let ring = NSBezierPath(ovalIn: NSRect(x: c.x - ringR, y: c.y - ringR, width: 2 * ringR, height: 2 * ringR))
    ring.lineWidth = s * 0.06
    NSColor(calibratedRed: 0.25, green: 0.6, blue: 1, alpha: 1).setStroke()
    ring.stroke()
    // puck
    let puckR = s * 0.15
    NSGradient(starting: NSColor(calibratedWhite: 0.85, alpha: 1), ending: NSColor(calibratedWhite: 0.55, alpha: 1))!
        .draw(in: NSBezierPath(ovalIn: NSRect(x: c.x - puckR, y: c.y - puckR, width: 2 * puckR, height: 2 * puckR)), angle: -90)
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

for base in [16, 32, 128, 256, 512] {
    try! render(base).write(to: URL(fileURLWithPath: "\(out)/icon_\(base)x\(base).png"))
    try! render(base * 2).write(to: URL(fileURLWithPath: "\(out)/icon_\(base)x\(base)@2x.png"))
}
