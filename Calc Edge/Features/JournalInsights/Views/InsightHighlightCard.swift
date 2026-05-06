import SwiftUI

struct InsightHighlightCard: View {
    let highlight: TradeInsights.Highlight

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: iconName)
                    .foregroundStyle(accentColor)

                Text(highlight.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(highlight.value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(accentColor)
                .lineLimit(2)

            Text(highlight.detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var accentColor: Color {
        switch highlight.tone {
        case .positive:
            return .green
        case .caution:
            return .orange
        case .neutral:
            return .blue
        }
    }

    private var iconName: String {
        switch highlight.tone {
        case .positive:
            return "arrow.up.right.circle.fill"
        case .caution:
            return "exclamationmark.triangle.fill"
        case .neutral:
            return "chart.line.uptrend.xyaxis.circle.fill"
        }
    }
}
