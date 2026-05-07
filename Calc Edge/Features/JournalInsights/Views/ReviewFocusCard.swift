import SwiftUI

struct ReviewFocusCard: View {
    let focus: TradeInsightReviewFocus

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "scope")
                .font(.title3)
                .foregroundStyle(.red)

            VStack(alignment: .leading, spacing: 4) {
                Text(focus.title)
                    .font(.headline)

                Text(focus.detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
