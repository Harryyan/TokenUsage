import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } icon: {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundStyle(color)
            }

            Text(value)
                .font(.system(.callout, design: .monospaced))
                .fontWeight(.medium)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            if let subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.quaternary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct TokenBreakdownRow: View {
    let label: String
    let tokens: Int
    let color: Color

    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.caption)
            Spacer()
            Text(TokenFormatter.abbreviated(tokens))
                .font(.caption)
                .monospacedDigit()
            Text("(\(TokenFormatter.precise(tokens)))")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }
}
