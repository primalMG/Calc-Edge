import SwiftUI

struct MarketContextSection: View {
    @Bindable var trade: Trade

    var body: some View {
        marketContextSectionLayout {
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
    
    private func marketContextSectionLayout<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        #if os(macOS)
        JournalSectionContainer("Market Context") {
            content()
        }
        #else
        content()
        #endif
    }
}

private struct TradeContextEditor: View {
    @Bindable var context: TradeContext
    let onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                JournalField("Market Regime") {
                    JournalMenuPicker(context.marketRegime.rawValue.capitalized, selection: $context.marketRegime) {
                        ForEach(MarketRegime.allCases, id: \.self) { regime in
                            Text(regime.rawValue.capitalized)
                                .tag(regime)
                        }
                    }
                }

                JournalField("VIX") {
                    TextField("", text: optionalDecimalBinding($context.vix))
                    #if os(iOS)
                    .textFieldStyle(CustomTextFieldStyle())
                    #endif
                }
            }

            JournalField("Index Trend") {
                SuggestingOptionalTextField(field: .marketIndexTrend, text: $context.indexTrend)
                #if os(iOS)
                .textFieldStyle(CustomTextFieldStyle())
                #endif
            }

            JournalField("Sector Strength") {
                SuggestingOptionalTextField(field: .marketSectorStrength, text: $context.sectorStrength)
                #if os(iOS)
                .textFieldStyle(CustomTextFieldStyle())
                #endif
            }

            JournalField("News During Trade") {
                SuggestingOptionalTextField(field: .marketNewsDuringTrade, text: $context.newsDuringTrade)
                #if os(iOS)
                .textFieldStyle(CustomTextFieldStyle())
                #endif
            }

            JournalField("Time Of Day") {
                SuggestingOptionalTextField(field: .marketTimeOfDayTag, text: $context.timeOfDayTag)
                #if os(iOS)
                .textFieldStyle(CustomTextFieldStyle())
                #endif
            }

            Button("Remove Context") {
                onRemove()
            }
            .tint(.red)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

#if os(macOS)
    private let columns = [
        GridItem(.flexible(minimum: 160), spacing: 12),
        GridItem(.flexible(minimum: 160), spacing: 12)
    ]
#else
    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 10)
    ]
#endif
}
