import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let resourcesURL = root.appendingPathComponent("Resources", isDirectory: true)
let iconsetURL = resourcesURL.appendingPathComponent("AppIcon.iconset", isDirectory: true)
let iconURL = resourcesURL.appendingPathComponent("AppIcon.icns")

let fileManager = FileManager.default
try fileManager.createDirectory(at: resourcesURL, withIntermediateDirectories: true)
if fileManager.fileExists(atPath: iconsetURL.path) {
    try fileManager.removeItem(at: iconsetURL)
}
try fileManager.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

let iconSizes: [(name: String, pixels: Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512)
]

for iconSize in iconSizes {
    let image = drawIcon(size: iconSize.pixels)
    let data = try pngData(from: image, pixels: iconSize.pixels)
    try data.write(to: iconsetURL.appendingPathComponent(iconSize.name), options: [.atomic])
}

if fileManager.fileExists(atPath: iconURL.path) {
    try fileManager.removeItem(at: iconURL)
}

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconsetURL.path, "-o", iconURL.path]
try process.run()
process.waitUntilExit()

guard process.terminationStatus == 0 else {
    throw NSError(
        domain: "IconGeneration",
        code: Int(process.terminationStatus),
        userInfo: [NSLocalizedDescriptionKey: "iconutil failed"]
    )
}

print("Generated \(iconURL.path)")

private func drawIcon(size pixels: Int) -> NSImage {
    let size = CGFloat(pixels)
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    defer { image.unlockFocus() }

    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    NSColor.clear.setFill()
    rect.fill()

    let scale = size / 1024
    func s(_ value: CGFloat) -> CGFloat { value * scale }

    let iconRect = rect.insetBy(dx: s(54), dy: s(54))
    let iconPath = NSBezierPath(
        roundedRect: iconRect,
        xRadius: s(220),
        yRadius: s(220)
    )

    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.28)
    shadow.shadowBlurRadius = s(34)
    shadow.shadowOffset = NSSize(width: 0, height: -s(18))
    shadow.set()

    NSColor(calibratedWhite: 0.05, alpha: 0.22).setFill()
    iconPath.fill()
    NSShadow().set()

    NSGraphicsContext.saveGraphicsState()
    iconPath.addClip()

    let skyGradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.08, green: 0.45, blue: 0.50, alpha: 1),
        NSColor(calibratedRed: 0.38, green: 0.72, blue: 0.70, alpha: 1),
        NSColor(calibratedRed: 0.98, green: 0.62, blue: 0.24, alpha: 1)
    ])!
    skyGradient.draw(in: iconRect, angle: 90)

    drawSun(in: iconRect, scale: scale)
    drawMountains(in: iconRect, scale: scale)
    drawPhotoFrame(in: iconRect, scale: scale)
    drawSwitchMark(in: iconRect, scale: scale)

    NSGraphicsContext.restoreGraphicsState()

    let border = NSBezierPath(
        roundedRect: iconRect.insetBy(dx: s(2), dy: s(2)),
        xRadius: s(216),
        yRadius: s(216)
    )
    NSColor.white.withAlphaComponent(0.28).setStroke()
    border.lineWidth = s(3)
    border.stroke()

    return image
}

private func drawSun(in rect: NSRect, scale: CGFloat) {
    func s(_ value: CGFloat) -> CGFloat { value * scale }

    let sunRect = NSRect(
        x: rect.minX + s(610),
        y: rect.minY + s(574),
        width: s(214),
        height: s(214)
    )
    let glowRect = sunRect.insetBy(dx: -s(58), dy: -s(58))

    NSColor(calibratedRed: 1.0, green: 0.86, blue: 0.38, alpha: 0.20).setFill()
    NSBezierPath(ovalIn: glowRect).fill()

    NSColor(calibratedRed: 1.0, green: 0.82, blue: 0.26, alpha: 1).setFill()
    NSBezierPath(ovalIn: sunRect).fill()
}

private func drawMountains(in rect: NSRect, scale: CGFloat) {
    func p(_ x: CGFloat, _ y: CGFloat) -> NSPoint {
        NSPoint(x: rect.minX + x * scale, y: rect.minY + y * scale)
    }

    let back = NSBezierPath()
    back.move(to: p(0, 278))
    back.line(to: p(210, 454))
    back.line(to: p(365, 348))
    back.line(to: p(520, 540))
    back.line(to: p(760, 282))
    back.line(to: p(916, 394))
    back.line(to: p(916, 0))
    back.line(to: p(0, 0))
    back.close()
    NSColor(calibratedRed: 0.10, green: 0.34, blue: 0.36, alpha: 0.82).setFill()
    back.fill()

    let front = NSBezierPath()
    front.move(to: p(0, 190))
    front.line(to: p(156, 338))
    front.line(to: p(300, 256))
    front.line(to: p(470, 424))
    front.line(to: p(650, 248))
    front.line(to: p(816, 320))
    front.line(to: p(916, 214))
    front.line(to: p(916, 0))
    front.line(to: p(0, 0))
    front.close()
    NSColor(calibratedRed: 0.04, green: 0.24, blue: 0.22, alpha: 0.95).setFill()
    front.fill()
}

private func drawPhotoFrame(in rect: NSRect, scale: CGFloat) {
    func s(_ value: CGFloat) -> CGFloat { value * scale }

    let frameRect = NSRect(
        x: rect.minX + s(174),
        y: rect.minY + s(172),
        width: s(676),
        height: s(482)
    )
    let framePath = NSBezierPath(
        roundedRect: frameRect,
        xRadius: s(58),
        yRadius: s(58)
    )

    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.24)
    shadow.shadowBlurRadius = s(26)
    shadow.shadowOffset = NSSize(width: 0, height: -s(12))
    shadow.set()

    NSColor.white.withAlphaComponent(0.94).setFill()
    framePath.fill()
    NSShadow().set()

    let innerRect = frameRect.insetBy(dx: s(34), dy: s(34))
    let innerPath = NSBezierPath(
        roundedRect: innerRect,
        xRadius: s(38),
        yRadius: s(38)
    )
    NSGraphicsContext.saveGraphicsState()
    innerPath.addClip()

    let innerGradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.10, green: 0.48, blue: 0.54, alpha: 1),
        NSColor(calibratedRed: 0.75, green: 0.86, blue: 0.73, alpha: 1)
    ])!
    innerGradient.draw(in: innerRect, angle: 80)

    drawTinyLandscape(in: innerRect)

    NSGraphicsContext.restoreGraphicsState()
}

private func drawTinyLandscape(in rect: NSRect) {
    func p(_ x: CGFloat, _ y: CGFloat) -> NSPoint {
        NSPoint(x: rect.minX + x * rect.width, y: rect.minY + y * rect.height)
    }

    NSColor(calibratedRed: 1.0, green: 0.76, blue: 0.25, alpha: 1).setFill()
    NSBezierPath(
        ovalIn: NSRect(
            x: rect.minX + rect.width * 0.64,
            y: rect.minY + rect.height * 0.58,
            width: rect.width * 0.16,
            height: rect.width * 0.16
        )
    ).fill()

    let ridge = NSBezierPath()
    ridge.move(to: p(0, 0.32))
    ridge.line(to: p(0.26, 0.58))
    ridge.line(to: p(0.42, 0.43))
    ridge.line(to: p(0.58, 0.62))
    ridge.line(to: p(0.84, 0.31))
    ridge.line(to: p(1, 0.42))
    ridge.line(to: p(1, 0))
    ridge.line(to: p(0, 0))
    ridge.close()
    NSColor(calibratedRed: 0.06, green: 0.30, blue: 0.28, alpha: 1).setFill()
    ridge.fill()

    let foreground = NSBezierPath()
    foreground.move(to: p(0, 0.18))
    foreground.curve(to: p(1, 0.18), controlPoint1: p(0.32, 0.03), controlPoint2: p(0.68, 0.32))
    foreground.line(to: p(1, 0))
    foreground.line(to: p(0, 0))
    foreground.close()
    NSColor(calibratedRed: 0.95, green: 0.51, blue: 0.20, alpha: 1).setFill()
    foreground.fill()
}

private func drawSwitchMark(in rect: NSRect, scale: CGFloat) {
    func s(_ value: CGFloat) -> CGFloat { value * scale }

    let badgeRect = NSRect(
        x: rect.minX + s(632),
        y: rect.minY + s(146),
        width: s(206),
        height: s(206)
    )
    let badge = NSBezierPath(
        roundedRect: badgeRect,
        xRadius: s(58),
        yRadius: s(58)
    )
    NSColor(calibratedRed: 0.98, green: 0.60, blue: 0.20, alpha: 1).setFill()
    badge.fill()

    NSColor.white.setStroke()
    let arrow = NSBezierPath()
    arrow.lineWidth = s(20)
    arrow.lineCapStyle = .round
    arrow.lineJoinStyle = .round
    arrow.move(to: NSPoint(x: badgeRect.minX + s(54), y: badgeRect.midY + s(26)))
    arrow.line(to: NSPoint(x: badgeRect.maxX - s(58), y: badgeRect.midY + s(26)))
    arrow.line(to: NSPoint(x: badgeRect.maxX - s(88), y: badgeRect.midY + s(56)))
    arrow.move(to: NSPoint(x: badgeRect.maxX - s(58), y: badgeRect.midY + s(26)))
    arrow.line(to: NSPoint(x: badgeRect.maxX - s(88), y: badgeRect.midY - s(4)))
    arrow.move(to: NSPoint(x: badgeRect.maxX - s(54), y: badgeRect.midY - s(38)))
    arrow.line(to: NSPoint(x: badgeRect.minX + s(58), y: badgeRect.midY - s(38)))
    arrow.line(to: NSPoint(x: badgeRect.minX + s(88), y: badgeRect.midY - s(68)))
    arrow.move(to: NSPoint(x: badgeRect.minX + s(58), y: badgeRect.midY - s(38)))
    arrow.line(to: NSPoint(x: badgeRect.minX + s(88), y: badgeRect.midY - s(8)))
    arrow.stroke()
}

private func pngData(from image: NSImage, pixels: Int) throws -> Data {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels,
        pixelsHigh: pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        throw NSError(
            domain: "IconGeneration",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Could not allocate bitmap"]
        )
    }

    bitmap.size = NSSize(width: pixels, height: pixels)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    image.draw(
        in: NSRect(x: 0, y: 0, width: pixels, height: pixels),
        from: .zero,
        operation: .copy,
        fraction: 1
    )
    NSGraphicsContext.restoreGraphicsState()

    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(
            domain: "IconGeneration",
            code: 2,
            userInfo: [NSLocalizedDescriptionKey: "Could not encode PNG"]
        )
    }

    return data
}
