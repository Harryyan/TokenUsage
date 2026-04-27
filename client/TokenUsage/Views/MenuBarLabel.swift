import SwiftUI
import AppKit

struct MenuBarLabel: View {
    @ObservedObject var viewModel: UsageViewModel

    var body: some View {
        HStack(spacing: 6) {
            Image(nsImage: MenuBarIcon.image(color: iconColor))
            Text(labelText)
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .monospacedDigit()
        }
    }

    private var labelText: String {
        let tokens = TokenFormatter.abbreviated(viewModel.snapshot.today.totalTokens)
        let cost = CostFormatter.abbreviated(viewModel.snapshot.today.totalCost)
        switch viewModel.menuBarDisplayMode {
        case .tokenOnly: return tokens
        case .costOnly: return cost
        case .tokenAndCost: return "\(tokens) · \(cost)"
        }
    }

    /// Diamond color: failure / loading states win; otherwise reflects current
    /// 5-hour usage with the same traffic-light bands as the popover bars.
    private var iconColor: NSColor {
        switch viewModel.refreshState {
        case .failed: return MenuBarColors.red
        case .loading, .refreshing: return MenuBarColors.amber
        default:
            return MenuBarColors.forUsage(viewModel.currentUsagePercent)
        }
    }
}

private enum MenuBarColors {
    static let mint = NSColor(red: 127/255, green: 224/255, blue: 168/255, alpha: 1)
    static let amber = NSColor(red: 212/255, green: 168/255, blue: 67/255, alpha: 1)
    static let red = NSColor(red: 215/255, green: 25/255, blue: 33/255, alpha: 1)

    static func forUsage(_ percent: Double?) -> NSColor {
        guard let p = percent else { return mint }
        if p >= 85 { return red }
        if p >= 60 { return amber }
        return mint
    }
}

enum MenuBarIcon {
    private static var cache: [UInt32: NSImage] = [:]
    private static let lock = NSLock()

    static func image(color: NSColor) -> NSImage {
        let key = color.rgbKey
        lock.lock()
        if let cached = cache[key] {
            lock.unlock()
            return cached
        }
        lock.unlock()

        let img = makeImage(color: color)
        lock.lock()
        cache[key] = img
        lock.unlock()
        return img
    }

    private static func makeImage(color: NSColor) -> NSImage {
        let size: CGFloat = 12
        let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            let inset: CGFloat = 1.5
            let diamond = NSBezierPath()
            diamond.move(to: NSPoint(x: rect.midX, y: rect.minY + inset))
            diamond.line(to: NSPoint(x: rect.maxX - inset, y: rect.midY))
            diamond.line(to: NSPoint(x: rect.midX, y: rect.maxY - inset))
            diamond.line(to: NSPoint(x: rect.minX + inset, y: rect.midY))
            diamond.close()
            color.setFill()
            diamond.fill()
            return true
        }
        image.isTemplate = false
        return image
    }
}

private extension NSColor {
    /// Pack 8-bit RGB into a single UInt32 for cache keying.
    var rgbKey: UInt32 {
        let resolved = self.usingColorSpace(.deviceRGB) ?? self
        let r = UInt32((resolved.redComponent * 255).rounded()) & 0xFF
        let g = UInt32((resolved.greenComponent * 255).rounded()) & 0xFF
        let b = UInt32((resolved.blueComponent * 255).rounded()) & 0xFF
        return (r << 16) | (g << 8) | b
    }
}
