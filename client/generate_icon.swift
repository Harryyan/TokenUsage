#!/usr/bin/env swift

import AppKit
import CoreGraphics

// Nothing-aesthetic app icon: warm dark squircle + mint twin-diamond mark.
// Generates AppIcon.iconset under the client directory, ready for `iconutil -c icns`.

func createIcon(size: Int) -> NSImage {
    let s = CGFloat(size)
    let image = NSImage(size: NSSize(width: s, height: s))
    image.lockFocus()
    defer { image.unlockFocus() }

    guard let ctx = NSGraphicsContext.current?.cgContext else { return image }

    // --- Background: warm dark squircle ---
    let cornerRadius = s * 0.22
    let bgRect = CGRect(x: 0, y: 0, width: s, height: s)
    let bgPath = CGPath(roundedRect: bgRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

    ctx.saveGState()
    ctx.addPath(bgPath)
    ctx.setFillColor(CGColor(red: 0x1A/255.0, green: 0x1A/255.0, blue: 0x18/255.0, alpha: 1.0))
    ctx.fillPath()
    ctx.restoreGState()

    // --- Twin diamond mark (mint), centered ---
    let cx = s / 2
    let cy = s / 2
    let outerR = s * 0.30
    let innerR = s * 0.13
    let strokeOuter = max(s * 0.028, 1)
    let strokeInner = max(s * 0.022, 1)
    let mint = CGColor(red: 0x7F/255.0, green: 0xE0/255.0, blue: 0xA8/255.0, alpha: 1.0)

    func diamond(at center: CGPoint, radius: CGFloat) -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: center.x, y: center.y + radius))
        path.addLine(to: CGPoint(x: center.x + radius, y: center.y))
        path.addLine(to: CGPoint(x: center.x, y: center.y - radius))
        path.addLine(to: CGPoint(x: center.x - radius, y: center.y))
        path.closeSubpath()
        return path
    }

    ctx.saveGState()
    ctx.setStrokeColor(mint)
    ctx.setLineJoin(.miter)
    ctx.setLineCap(.butt)

    // Outer diamond
    ctx.setLineWidth(strokeOuter)
    ctx.addPath(diamond(at: CGPoint(x: cx, y: cy), radius: outerR))
    ctx.strokePath()

    // Inner diamond
    ctx.setLineWidth(strokeInner)
    ctx.addPath(diamond(at: CGPoint(x: cx, y: cy), radius: innerR))
    ctx.strokePath()
    ctx.restoreGState()

    return image
}

func createIconset() {
    let scriptDir = (CommandLine.arguments[0] as NSString).deletingLastPathComponent
    let baseDir = scriptDir.isEmpty ? FileManager.default.currentDirectoryPath : scriptDir
    let iconsetPath = "\(baseDir)/AppIcon.iconset"

    let fm = FileManager.default
    try? fm.removeItem(atPath: iconsetPath)
    try! fm.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

    let sizes: [(String, Int)] = [
        ("icon_16x16", 16),
        ("icon_16x16@2x", 32),
        ("icon_32x32", 32),
        ("icon_32x32@2x", 64),
        ("icon_128x128", 128),
        ("icon_128x128@2x", 256),
        ("icon_256x256", 256),
        ("icon_256x256@2x", 512),
        ("icon_512x512", 512),
        ("icon_512x512@2x", 1024)
    ]

    for (name, size) in sizes {
        let image = createIcon(size: size)
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            print("Failed to create \(name)")
            continue
        }
        let filePath = "\(iconsetPath)/\(name).png"
        try! pngData.write(to: URL(fileURLWithPath: filePath))
        print("Created \(name).png (\(size)x\(size))")
    }

    print("\nIconset created at: \(iconsetPath)")
    print("Run: iconutil -c icns \(iconsetPath) -o \(baseDir)/AppIcon.icns")
}

createIconset()
