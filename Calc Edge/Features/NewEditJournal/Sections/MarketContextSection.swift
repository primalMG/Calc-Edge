import SwiftUI

struct MarketContextSection: View {
    @Bindable var trade: Trade

    var body: some View {
        Section("Market Context") {
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
        VStack(spacing: 12) {
            Picker("Market Regime", selection: $context.marketRegime) {
                ForEach(MarketRegime.allCases, id: \.self) { regime in
                    Text(regime.rawValue.capitalized)
                        .tag(regime)
                }
            }

            LabeledContent("VIX") {
                TextField("", text: optionalDecimalBinding($context.vix))
                    .textFieldStyle(CustomTextFieldStyle())
            }

            LabeledContent("Index Trend") {
                TextField("", text: optionalTextBinding($context.indexTrend))
            }

            LabeledContent("Sector Strength") {
                TextField("", text: optionalTextBinding($context.sectorStrength))
            }

            LabeledContent("News During Trade") {
                TextField("", text: optionalTextBinding($context.newsDuringTrade))
            }

            LabeledContent("Time Of Day") {
                TextField("", text: optionalTextBinding($context.timeOfDayTag))
            }

            Button("Remove Context") {
                onRemove()
            }
            .tint(.red)
        }
    }
}
