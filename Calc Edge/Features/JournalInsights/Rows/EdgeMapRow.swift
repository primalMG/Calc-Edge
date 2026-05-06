import SwiftUI

struct EdgeMapRow: View {
    let segment: TradeInsights.SegmentPerformance

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(segment.label)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    Text("\(segment.category) • \(segment.trades) trades")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 12)

                VStack(alignment: .trailing, spacing: 2) {
                    Text(JournalInsightsFormatting.rMultiple(segment.expectancy))
                        .fontWeight(.semibold)
                        .foregroundStyle(accentColor)

                    Text(JournalInsightsFormatting.percent(segment.winRate))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.quaternary)

                    Capsule()
                        .fill(accentColor)
                        .frame(width: proxy.size.width * CGFloat(barScale))
                }
            }
            .frame(height: 6)
        }
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var barScale: Double {
        min(abs(segment.expectancy ?? 0) / 2, 1)
    }

    private var accentColor: Color {
        (segment.expectancy ?? 0) >= 0 ? .green : .red
    }
}
