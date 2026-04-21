#!/usr/bin/env swift

import AppKit
import CoreGraphics

func createIcon(size: Int) -> NSImage {
    let s = CGFloat(size)
    let image = NSImage(size: NSSize(width: s, height: s))
    image.lockFocus()

    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    // Background: rounded rect with gradient
    let cornerRadius = s * 0.22
    let bgRect = CGRect(x: 0, y: 0, width: s, height: s)
    let bgPath = CGPath(roundedRect: bgRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

    ctx.saveGState()
    ctx.addPath(bgPath)
    ctx.clip()

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let gradientColors = [
        CGColor(red: 0.15, green: 0.15, blue: 0.22, alpha: 1.0),
        CGColor(red: 0.08, green: 0.08, blue: 0.14, alpha: 1.0)
    ] as CFArray
    let gradient = CGGradient(colorsSpace: colorSpace, colors: gradientColors, locations: [0.0, 1.0])!
    ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: s), end: CGPoint(x: s, y: 0), options: [])
    ctx.restoreGState()

    // Diamond shape (◈) - outer
    let cx = s / 2
    let cy = s / 2
    let diamondSize = s * 0.32

    let diamondPath = CGMutablePath()
    diamondPath.move(to: CGPoint(x: cx, y: cy + diamondSize))      // top
    diamondPath.addLine(to: CGPoint(x: cx + diamondSize, y: cy))    // right
    diamondPath.addLine(to: CGPoint(x: cx, y: cy - diamondSize))    // bottom
    diamondPath.addLine(to: CGPoint(x: cx - diamondSize, y: cy))    // left
    diamondPath.closeSubpath()

    // Diamond glow
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: 0), blur: s * 0.08, color: CGColor(red: 0.45, green: 0.65, blue: 1.0, alpha: 0.6))
    ctx.setLineWidth(s * 0.02)
    ctx.setStrokeColor(CGColor(red: 0.5, green: 0.7, blue: 1.0, alpha: 0.8))
    ctx.addPath(diamondPath)
    ctx.strokePath()
    ctx.restoreGState()

    // Diamond fill with gradient
    ctx.saveGState()
    ctx.addPath(diamondPath)
    ctx.clip()

    let diamondGradientColors = [
        CGColor(red: 0.40, green: 0.60, blue: 1.0, alpha: 0.9),
        CGColor(red: 0.55, green: 0.75, blue: 1.0, alpha: 0.7),
        CGColor(red: 0.35, green: 0.50, blue: 0.95, alpha: 0.85)
    ] as CFArray
    let diamondGradient = CGGradient(colorsSpace: colorSpace, colors: diamondGradientColors, locations: [0.0, 0.5, 1.0])!
    ctx.drawLinearGradient(diamondGradient, start: CGPoint(x: cx - diamondSize, y: cy + diamondSize), end: CGPoint(x: cx + diamondSize, y: cy - diamondSize), options: [])
    ctx.restoreGState()

    // Diamond border
    ctx.setLineWidth(s * 0.015)
    ctx.setStrokeColor(CGColor(red: 0.6, green: 0.8, blue: 1.0, alpha: 0.9))
    ctx.addPath(diamondPath)
    ctx.strokePath()

    // Inner diamond (hollow center like ◈)
    let innerSize = diamondSize * 0.45
    let innerPath = CGMutablePath()
    innerPath.move(to: CGPoint(x: cx, y: cy + innerSize))
    innerPath.addLine(to: CGPoint(x: cx + innerSize, y: cy))
    innerPath.addLine(to: CGPoint(x: cx, y: cy - innerSize))
    innerPath.addLine(to: CGPoint(x: cx - innerSize, y: cy))
    innerPath.closeSubpath()

    ctx.setLineWidth(s * 0.012)
    ctx.setStrokeColor(CGColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 0.95))
    ctx.addPath(innerPath)
    ctx.strokePath()

    // Small bars below diamond (representing usage/data)
    let barY = cy - diamondSize - s * 0.1
    let barHeight = s * 0.025
    let barSpacing = s * 0.04
    let barWidths: [CGFloat] = [0.35, 0.25, 0.18]

    for (i, width) in barWidths.enumerated() {
        let barW = s * width
        let y = barY - CGFloat(i) * barSpacing
        let barRect = CGRect(x: cx - barW / 2, y: y, width: barW, height: barHeight)
        let barPath = CGPath(roundedRect: barRect, cornerWidth: barHeight / 2, cornerHeight: barHeight / 2, transform: nil)

        let alpha = 0.6 - Double(i) * 0.15
        ctx.setFillColor(CGColor(red: 0.5, green: 0.7, blue: 1.0, alpha: alpha))
        ctx.addPath(barPath)
        ctx.fillPath()
    }

    // "T" text at top (for Token)
    let fontSize = s * 0.11
    let font = CTFontCreateWithName("SF Pro Display Heavy" as CFString, fontSize, nil)
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor(red: 0.7, green: 0.85, blue: 1.0, alpha: 0.7)
    ]
    let text = NSAttributedString(string: "T", attributes: attributes)
    let textSize = text.size()
    let textX = cx - textSize.width / 2
    let textY = cy + diamondSize + s * 0.06
    text.draw(at: NSPoint(x: textX, y: textY))

    image.unlockFocus()
    return image
}

func createIconset() {
    let iconsetPath = "/Users/mega-hy/Desktop/Harry/Projects/TokenUsage/AppIcon.iconset"
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
    print("Run: iconutil -c icns AppIcon.iconset")
}

createIconset()
