import SwiftUI
import AppKit

struct MenuBarLabel: View {
    @ObservedObject var viewModel: UsageViewModel

    var body: some View {
        HStack(spacing: 6) {
            Image(nsImage: MenuBarIcon.image(for: iconState))
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

    private var iconState: MenuBarIcon.State {
        switch viewModel.refreshState {
        case .failed: return .failed
        case .loading, .refreshing: return .loading
        default: return .normal
        }
    }
}

enum MenuBarIcon {
    enum State { case normal, loading, failed }

    private static let cache: [State: NSImage] = [
        .normal: makeImage(color: NSColor(red: 127/255, green: 224/255, blue: 168/255, alpha: 1)),
        .loading: makeImage(color: NSColor(red: 212/255, green: 168/255, blue: 67/255, alpha: 1)),
        .failed: makeImage(color: NSColor(red: 215/255, green: 25/255, blue: 33/255, alpha: 1))
    ]

    static func image(for state: State) -> NSImage {
        cache[state] ?? cache[.normal]!
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
