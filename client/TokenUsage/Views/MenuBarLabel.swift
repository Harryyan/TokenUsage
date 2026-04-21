import SwiftUI
import AppKit

struct MenuBarLabel: View {
    @ObservedObject var viewModel: UsageViewModel

    var body: some View {
        HStack(spacing: 5) {
            Image(nsImage: makeIcon())
            Text(labelText)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
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

    private func makeIcon() -> NSImage {
        let size: CGFloat = 16
        let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            let inset: CGFloat = 1.5
            let diamond = NSBezierPath()
            diamond.move(to: NSPoint(x: rect.midX, y: rect.minY + inset))
            diamond.line(to: NSPoint(x: rect.maxX - inset, y: rect.midY))
            diamond.line(to: NSPoint(x: rect.midX, y: rect.maxY - inset))
            diamond.line(to: NSPoint(x: rect.minX + inset, y: rect.midY))
            diamond.close()

            let colors: [NSColor]
            switch self.viewModel.refreshState {
            case .failed:
                colors = [
                    NSColor(red: 0.95, green: 0.30, blue: 0.25, alpha: 1),
                    NSColor(red: 1.00, green: 0.55, blue: 0.20, alpha: 1)
                ]
            case .loading, .refreshing:
                colors = [
                    NSColor(red: 1.00, green: 0.70, blue: 0.15, alpha: 1),
                    NSColor(red: 1.00, green: 0.85, blue: 0.25, alpha: 1)
                ]
            default:
                colors = [
                    NSColor(red: 0.94, green: 0.75, blue: 0.25, alpha: 1),
                    NSColor(red: 1.00, green: 0.55, blue: 0.20, alpha: 1)
                ]
            }

            if let gradient = NSGradient(colors: colors) {
                gradient.draw(in: diamond, angle: -45)
            }
            return true
        }
        image.isTemplate = false
        return image
    }
}
