import SwiftUI

struct MarketContextSection: View {
    @Bindable var trade: Trade

    var body: some View {
        JournalSectionContainer("Market Context") {
            if let context = trade.context {
                TradeContextEditor(context: context) {
                    trade.context = nil
                }
            } else {
                Button("Add Market Context") {
                    trade.context = TradeContext()
                }
            }
        }
    }
}

private struct TradeContextEditor: View {
    @Bindable var context: TradeContext
    let onRemove: () -> Void

    var body: some View {
        Form {
            Picker("Market Regime", selection: $context.marketRegime) {
                ForEach(MarketRegime.allCases, id: \.self) { regime in
                    Text(regime.rawValue.capitalized)
                            .tag(regime)
                }
            }

            LabeledContent("VIX") {
                TextField("", text: optionalDecimalBinding($context.vix))
            }

            LabeledContent("Index Trend") {
                SuggestingOptionalTextField(field: .marketIndexTrend, text: $context.indexTrend)
            }

            LabeledContent("Sector Strength") {
                SuggestingOptionalTextField(field: .marketSectorStrength, text: $context.sectorStrength)
            }

            LabeledContent("News During Trade") {
                SuggestingOptionalTextField(field: .marketNewsDuringTrade, text: $context.newsDuringTrade)
            }

            LabeledContent("Time Of Day") {
                SuggestingOptionalTextField(field: .marketTimeOfDayTag, text: $context.timeOfDayTag)
            }

            Button("Remove Context") {
                onRemove()
            }
            .tint(.red)
        }
    }
}
